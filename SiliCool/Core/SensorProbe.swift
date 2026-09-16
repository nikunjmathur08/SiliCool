//
//  SensorProbe.swift
//  SiliCool
//
//  All the blocking IOKit work lives here, off the main actor: one slow
//  discovery pass at launch, then cheap sampling of a curated key set.
//

import Foundation
import os

nonisolated final class SensorProbe: @unchecked Sendable {

    struct Discovery: Sendable {
        var inventory = HardwareInventory()
        var isLive: Bool
        var note: String?
        var fanCount: Int
        var sensorCount: Int
        var canWrite: Bool
        var writeNote: String?
    }

    private let smc = SMC()
    private let lock = NSLock()

    private var temperatureKeys: [String] = []
    private var displayNames: [String: String] = [:]
    private var powerKeys: [(key: String, name: String)] = []
    private var fanCount = 0
    private var fanModeKeys: [Int: String] = [:]

    // MARK: Discovery

    /// Enumerates the SMC once and picks the keys worth polling. ~600 ms.
    func discover() -> Discovery {
        guard smc.open() else {
            return Discovery(isLive: false,
                             note: "AppleSMC is unreachable — the app must run outside the App Sandbox",
                             fanCount: 0, sensorCount: 0,
                             canWrite: false, writeNote: "No SMC connection")
        }

        let keys = smc.allKeys()
        guard !keys.isEmpty else {
            return Discovery(isLive: false,
                             note: "SMC opened but advertised no keys",
                             fanCount: 0, sensorCount: 0,
                             canWrite: false, writeNote: "No SMC keys")
        }

        let liveTemperatures = keys.filter { $0.hasPrefix("T") }.compactMap { key -> (String, SensorGroupKind)? in
            guard let info = try? smc.keyInfo(for: key) else { return nil }
            let type = info.dataType.smcKeyString
            guard type == "flt " || type == "sp78" || type == "sp96" || type == "fp88" else { return nil }
            guard let value = smc.readNumber(key: key),
                  SMCKeyCatalog.isPlausibleTemperature(value) else { return nil }
            return (key, SMCKeyCatalog.group(for: key))
        }

        // Some keys are several views of one register — on this Mac
        // `Ta00 Ta04 Ta08 Ta0K Ta0O Ta0R` are bit-identical to each other
        // sample after sample. Rather than trusting a published list of which
        // keys those are, measure it: sweep everything three times a second
        // apart and fold away same-family keys that never differ.
        let duplicates = measureDuplicates(among: liveTemperatures.map(\.0))
        let deduplicated = liveTemperatures.filter { duplicates.hidden.contains($0.0) == false }
        let selected = trimToBudget(deduplicated)
        let availablePower = SMCKeyCatalog.powerKeys.filter { keys.contains($0.key) }
        let fans = Int(smc.readNumber(key: SMCKeyCatalog.fanCount) ?? 0)

        var modeKeys: [Int: String] = [:]
        for index in 0..<max(fans, 0) {
            modeKeys[index] = SMCKeyCatalog.fanModeCandidates(index).first {
                (try? smc.keyInfo(for: $0)) != nil
            }
        }

        // Named against the whole live set, so "GPU 42" means the 42nd of 42
        // even when only a dozen of them are polled.
        let inventory = HardwareInventory.current()
        var names = SMCKeyCatalog.displayNames(for: deduplicated.map(\.0), inventory: inventory)

        // Say so where several keys were folded into one, so the reading is not
        // silently standing in for others.
        for (key, count) in duplicates.counts where count > 1 {
            names[key] = "\((names[key] ?? key)) ×\(count)"
        }

        lock.withLock {
            displayNames = names
            temperatureKeys = selected
            powerKeys = availablePower
            fanCount = fans
            fanModeKeys = modeKeys
        }

        let writable = geteuid() == 0
        return Discovery(inventory: inventory,
                         isLive: fans > 0,
                         note: fans > 0 ? nil : "This Mac reports no controllable fans",
                         fanCount: fans,
                         sensorCount: selected.count,
                         canWrite: writable,
                         writeNote: writable ? nil : "Fan writes need root — relaunch with elevated privileges")
    }

    /// Sweeps every candidate key three times, a second apart, and folds away
    /// keys that are bit-identical to another key of the same family in every
    /// sweep. Only groups of three or more are folded: two same-family probes
    /// can legitimately agree for a while — this Mac's `TB0T` and `TB2T`
    /// battery thermistors do — and losing a real sensor is worse than showing
    /// a redundant one.
    private func measureDuplicates(among keys: [String]) -> (hidden: Set<String>, counts: [String: Int]) {
        var sweeps: [[String: Double]] = []
        for sweep in 0..<3 {
            var readings: [String: Double] = [:]
            for key in keys {
                if let value = smc.readNumber(key: key) { readings[key] = value }
            }
            sweeps.append(readings)
            if sweep < 2 { Thread.sleep(forTimeInterval: 1.0) }
        }

        var byFingerprint: [String: [String]] = [:]
        for key in keys {
            let values = sweeps.compactMap { $0[key] }
            guard values.count == sweeps.count else { continue }
            // Family prefix is part of the fingerprint: two unrelated sensors
            // reading the same number is a coincidence, not an alias.
            let fingerprint = key.prefix(2) + "|" + values.map { String(format: "%.6f", $0) }.joined(separator: "|")
            byFingerprint[String(fingerprint), default: []].append(key)
        }

        var hidden: Set<String> = []
        var counts: [String: Int] = [:]
        for group in byFingerprint.values where group.count >= 3 {
            let members = group.sorted()
            counts[members[0]] = members.count
            hidden.formUnion(members.dropFirst())
        }
        return (hidden, counts)
    }

    /// Keeps a representative slice of each group so a poll stays a few
    /// milliseconds instead of thirty-five. Keys stay in sorted order, and the
    /// selection is made once at launch, so the list never reshuffles.
    private func trimToBudget(_ candidates: [(String, SensorGroupKind)]) -> [String] {
        var perGroup: [SensorGroupKind: [String]] = [:]
        for (key, group) in candidates {
            perGroup[group, default: []].append(key)
        }

        var selected: [String] = []
        for group in SensorGroupKind.allCases {
            let budget = SMCKeyCatalog.pollBudget[group] ?? 4
            let keys = (perGroup[group] ?? []).sorted()
            // Spread the picks across the family rather than taking the first N,
            // which would be all of one cluster.
            let stride = max(1, keys.count / max(budget, 1))
            var picked: [String] = []
            var index = 0
            while index < keys.count && picked.count < budget {
                picked.append(keys[index])
                index += stride
            }
            selected.append(contentsOf: picked.sorted())
        }
        return selected
    }

    // MARK: Sampling

    func sample() -> HardwareSnapshot {
        let (temperatureKeys, powerKeys, fanCount, modeKeys, names) = lock.withLock {
            (self.temperatureKeys, self.powerKeys, self.fanCount, self.fanModeKeys, self.displayNames)
        }

        var snapshot = HardwareSnapshot()

        snapshot.fans = (0..<fanCount).compactMap { index in
            guard let actual = smc.readNumber(key: SMCKeyCatalog.fanActual(index)) else { return nil }
            let minimum = smc.readNumber(key: SMCKeyCatalog.fanMinimum(index)) ?? 0
            let maximum = smc.readNumber(key: SMCKeyCatalog.fanMaximum(index)) ?? max(actual, 6_000)
            let target = smc.readNumber(key: SMCKeyCatalog.fanTarget(index)) ?? actual
            let manual = modeKeys[index].flatMap { smc.readNumber(key: $0) } ?? 0

            return Fan(id: index,
                       name: Self.fanName(index: index, of: fanCount),
                       actual: actual,
                       minimum: minimum,
                       maximum: maximum,
                       target: target,
                       mode: manual > 0 ? .manual : .automatic)
        }

        // Deliberately not sorted by temperature: the discovery order is fixed
        // (group order, then key), so rows never swap places under the cursor.
        snapshot.temperatures = temperatureKeys.compactMap { key in
            guard let value = smc.readNumber(key: key),
                  SMCKeyCatalog.isPlausibleTemperature(value) else { return nil }
            return TemperatureSensor(id: key,
                                     name: SMCKeyCatalog.name(for: key, in: names),
                                     group: SMCKeyCatalog.group(for: key),
                                     celsius: value)
        }

        snapshot.power = powerKeys.compactMap { entry in
            guard let watts = smc.readNumber(key: entry.key), watts > 0.05, watts < 400 else { return nil }
            return PowerReading(id: entry.key, name: entry.name, watts: watts)
        }

        return snapshot
    }

    static func fanName(index: Int, of count: Int) -> String {
        guard count > 1 else { return "System Fan" }
        switch index {
        case 0: return "Left Fan"
        case 1: return "Right Fan"
        default: return "Fan \(index + 1)"
        }
    }

    // MARK: Control

    /// Pins a fan: force manual mode, then write the target rpm.
    func setTarget(rpm: Double, fanIndex: Int) throws {
        try enableManualMode(fanIndex: fanIndex)
        try smc.write(key: SMCKeyCatalog.fanTarget(fanIndex), value: rpm)
    }

    func setAutomatic(fanIndex: Int) throws {
        try disableManualMode(fanIndex: fanIndex)
    }

    private func enableManualMode(fanIndex: Int) throws {
        if let modeKey = lock.withLock({ fanModeKeys[fanIndex] }) {
            try smc.write(key: modeKey, value: 1)
            return
        }
        let current = smc.readNumber(key: SMCKeyCatalog.fanForceBitmask) ?? 0
        let updated = UInt16(current.clamped(to: 0...65535)) | (1 << UInt16(fanIndex))
        try smc.write(key: SMCKeyCatalog.fanForceBitmask, value: Double(updated))
    }

    private func disableManualMode(fanIndex: Int) throws {
        if let modeKey = lock.withLock({ fanModeKeys[fanIndex] }) {
            try smc.write(key: modeKey, value: 0)
            return
        }
        let current = smc.readNumber(key: SMCKeyCatalog.fanForceBitmask) ?? 0
        let updated = UInt16(current.clamped(to: 0...65535)) & ~(1 << UInt16(fanIndex))
        try smc.write(key: SMCKeyCatalog.fanForceBitmask, value: Double(updated))
    }

    /// Best-effort revert of every fan this process may have pinned. Safe to
    /// call from a signal handler's queue or an `atexit` hook: it takes no
    /// locks it does not already own and swallows every error.
    @discardableResult
    func restoreAllAutomatic() -> Bool {
        let modeKeys = lock.withLock { fanModeKeys }
        var allReleased = true

        for (index, key) in modeKeys {
            do {
                try smc.write(key: key, value: 0)
            } catch {
                Diagnostics.fans.error("fan \(index, privacy: .public): could not write \(key, privacy: .public) — \(error.localizedDescription, privacy: .public)")
                allReleased = false
                continue
            }
            // Read it straight back: if the fan is still in manual mode the
            // write did not take, and that is worth knowing at the time rather
            // than from a user report weeks later.
            let readback = smc.readNumber(key: key) ?? -1
            if readback != 0 {
                Diagnostics.fans.error("fan \(index, privacy: .public): \(key, privacy: .public) still reads \(readback, privacy: .public) after release")
                allReleased = false
            }
        }

        if modeKeys.isEmpty {
            _ = try? smc.write(key: SMCKeyCatalog.fanForceBitmask, value: 0)
        }
        return allReleased
    }

    func shutdown() {
        smc.close()
    }
}
