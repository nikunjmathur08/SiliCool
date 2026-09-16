//
//  HardwareMonitor.swift
//  SiliCool
//
//  Main-actor state for the UI. Owns the polling task, the derived thermal
//  numbers, and the fan-control API the controls bind to.
//
//  Everything here is read from the machine. There is no simulation and no
//  placeholder data: if the SMC cannot be reached, the panel says so and shows
//  nothing rather than showing something plausible.
//

import Foundation
import Observation
import os

@Observable
final class HardwareMonitor {

    // MARK: Published state

    private(set) var fans: [Fan] = []
    private(set) var temperatures: [TemperatureSensor] = []
    private(set) var power: [PowerReading] = []
    private(set) var inventory = HardwareInventory()
    private(set) var status: MonitorStatus = .connecting
    private(set) var control: ControlAuthority = .denied("Checking privileges…")
    private(set) var helperStatus: PrivilegedFanControl.Status = .notInstalled
    let installLocation = InstallLocation.current()
    private(set) var lastMessage: String?

    var selectedFanID: Int = 0

    /// Ten minutes of readings, in a fixed ring buffer.
    private(set) var history = SampleHistory()

    /// Whether the menu bar panel is on screen. Drives both the poll cadence
    /// and whether the gauge animates at all — a canvas redrawing at 120 Hz
    /// behind a closed panel is pure waste.
    var isPanelVisible = false {
        didSet { if isPanelVisible { refreshControlAuthority() } }
    }

    // MARK: Settings

    var menuBarMetric: MenuBarMetric = Preferences.menuBarMetric {
        didSet { Preferences.menuBarMetric = menuBarMetric }
    }

    var curve: FanCurve = Preferences.curve {
        didSet { Preferences.curve = curve }
    }

    var animateGauge: Bool = Preferences.animateGauge {
        didSet { Preferences.animateGauge = animateGauge }
    }

    var curveEnabled: Bool = Preferences.curveEnabled {
        didSet {
            Preferences.curveEnabled = curveEnabled
            if !curveEnabled { lastCurveTarget.removeAll() }
        }
    }

    var launchAtLogin: Bool {
        get { Preferences.launchAtLogin }
        set { Preferences.launchAtLogin = newValue }
    }

    // MARK: Derived state

    var selectedFan: Fan? {
        fans.first { $0.id == selectedFanID } ?? fans.first
    }

    var hottestSensor: TemperatureSensor? {
        temperatures.filter { $0.group.isCompute }.max { $0.celsius < $1.celsius }
            ?? temperatures.max { $0.celsius < $1.celsius }
    }

    var cpuTemperature: Double? {
        temperatures.filter { $0.group == .cpuCores || $0.group == .socPackage }.map(\.celsius).max()
    }

    var gpuTemperature: Double? {
        temperatures.filter { $0.group == .gpu }.map(\.celsius).max()
    }

    var totalPower: Double? {
        power.first { $0.id == "PSTR" }?.watts ?? power.first?.watts
    }

    /// Sensors folded into their fixed groups, in a stable order that never
    /// depends on the current temperatures. Group details come from the
    /// hardware inventory, not from the sensor count.
    var sensorGroups: [SensorGroup] {
        SensorGroupKind.allCases.compactMap { kind in
            let members = temperatures.filter { $0.group == kind }
            guard !members.isEmpty else { return nil }
            return SensorGroup(kind: kind, sensors: members, detail: detail(for: kind))
        }
    }

    private func detail(for kind: SensorGroupKind) -> String? {
        switch kind {
        case .cpuCores: return inventory.cpuTiers.isEmpty ? nil : inventory.cpuSummary
        case .gpu: return inventory.gpuSummary
        case .memory: return inventory.memorySummary
        default: return nil
        }
    }

    /// True while any fan is being held by us rather than the system.
    var hasManualFan: Bool {
        fans.contains { $0.mode == .manual }
    }

    /// 0 = cool and quiet, 1 = thermally pinned. Every colour derives from this.
    var thermalLoad: Double {
        let heat = hottestSensor?.thermalLoad ?? 0
        let air = selectedFan?.duty ?? 0
        return (heat * 0.68 + air * 0.32).clamped(to: 0...1)
    }

    // MARK: Private

    private let probe = SensorProbe()
    private let helper = PrivilegedFanControl()
    private var pollTask: Task<Void, Never>?
    private var lastCurveTarget: [Int: Double] = [:]

    /// Set while the machine is asleep. The curve must not keep writing during
    /// that window, but the user's preference must not be altered either — so
    /// this is a separate flag rather than flipping `curveEnabled`, which would
    /// persist "curve off" to their settings.
    private var sleepSuspended = false

    /// What to put back on wake: the fans that were being held, and whether a
    /// curve was driving them.
    private var heldBeforeSleep: (curve: Bool, targets: [Int: Double])?

    /// Fans this process has written a target to. Kept separately from
    /// `Fan.mode`, which is read back from the SMC and is only as fresh as the
    /// last poll — a fan held a moment ago may still read as automatic.
    private var heldFanIDs: Set<Int> = []

    /// True when this process is root itself (launched with sudo) and can write
    /// to the SMC without going through the daemon.
    private var isRoot: Bool { geteuid() == 0 }

    // MARK: Lifecycle

    func start() {
        guard pollTask == nil else { return }

        pollTask = Task { [probe] in
            // Enumerating ~3,500 SMC keys and measuring which of them are
            // duplicates takes a few seconds, so it happens off the main actor
            // before the first sample lands.
            let discovery = await Task.detached(priority: .userInitiated) { probe.discover() }.value
            guard !Task.isCancelled else { return }
            apply(discovery)

            while !Task.isCancelled {
                guard status.isLive else { return }
                let snapshot = await Task.detached(priority: .utility) { probe.sample() }.value
                guard !Task.isCancelled else { return }
                apply(snapshot)
                record()
                applyCurve()

                // The menu bar readout does not need a fresh number every
                // second while the panel is shut.
                try? await Task.sleep(for: .seconds(isPanelVisible ? 1 : 2))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        restoreAutomaticControl()
        probe.shutdown()
    }

    /// Feeds one real probe result in without starting the polling task — used
    /// by previews and design snapshots, which therefore show this machine's
    /// actual sensors rather than invented ones.
    func applyOneShot(discovery: SensorProbe.Discovery, snapshot: HardwareSnapshot) {
        apply(discovery)
        apply(snapshot)
        record()
    }

    private func apply(_ discovery: SensorProbe.Discovery) {
        inventory = discovery.inventory

        if discovery.isLive {
            status = .live
            refreshControlAuthority()
        } else {
            status = .unavailable(reason: discovery.note ?? "Sensors unavailable")
            control = .denied(discovery.writeNote ?? discovery.note ?? "No SMC connection")
        }
    }

    /// Writes are possible either because we are root, or because the daemon is
    /// installed and approved.
    func refreshControlAuthority() {
        helperStatus = helper.status

        guard status.isLive else { return }
        if isRoot {
            control = .available
            return
        }

        // No point offering to install the helper from a location the approval
        // cannot survive.
        if let advice = installLocation.advice {
            control = .denied(advice)
            return
        }

        switch helperStatus {
        case .ready:
            control = .available
        case .requiresApproval:
            control = .denied("Approve SiliCool's helper in System Settings to control the fans")
        case .notInstalled:
            control = .denied("Fan control needs a small helper installed once")
        case .failed(let reason):
            control = .denied(reason)
        }
    }

    /// Installs the root daemon. The user approves it once, in System Settings.
    func installHelper() {
        guard installLocation.allowsFanControl else {
            lastMessage = installLocation.advice
            return
        }
        helperStatus = helper.install()
        switch helperStatus {
        case .ready:
            lastMessage = "Fan control enabled."
        case .requiresApproval:
            lastMessage = "Switch SiliCool on under Login Items & Extensions, then come back."
        case .failed(let reason):
            lastMessage = reason
        case .notInstalled:
            lastMessage = "The helper could not be registered."
        }
        refreshControlAuthority()
    }

    func openHelperApproval() {
        helper.openApprovalSettings()
    }

    /// Returns the fans to automatic and removes the daemon entirely.
    func removeHelper() {
        restoreAutomaticControl()
        helper.remove()
        helperStatus = helper.status
        lastMessage = "Fan control helper removed."
        refreshControlAuthority()
    }

    private func apply(_ snapshot: HardwareSnapshot) {
        fans = snapshot.fans
        temperatures = snapshot.temperatures
        power = snapshot.power

        if fans.isEmpty && temperatures.isEmpty {
            status = .unavailable(reason: "The SMC stopped reporting")
        }
    }

    // MARK: - History

    private func record() {
        let fan = selectedFan
        history.append(HistorySample(
            rpm: Float(fan?.actual ?? 0),
            duty: Float(fan?.duty ?? 0),
            hottest: Float(hottestSensor?.celsius ?? 0),
            cpu: Float(cpuTemperature ?? 0),
            gpu: Float(gpuTemperature ?? 0),
            watts: Float(totalPower ?? 0)))
    }

    // MARK: - Curve

    /// Holds each fan at the speed the curve asks for at the current
    /// temperature. Only writes when the answer has actually moved, so a stable
    /// machine produces no SMC traffic at all.
    private func applyCurve() {
        guard !sleepSuspended, curveEnabled, control.canControl, !fans.isEmpty,
              let hottest = hottestSensor?.celsius else { return }

        let fraction = curve.fraction(at: hottest)
        for fan in fans {
            // Across the fan's usable range, not its ceiling: this Mac idles at
            // 2317 of 7826, so a curve measured against the ceiling would spend
            // its whole lower half clamped to the floor and do nothing.
            let target = fan.minimum + (fan.maximum - fan.minimum) * fraction
            if let previous = lastCurveTarget[fan.id], abs(previous - target) < 120 { continue }
            lastCurveTarget[fan.id] = target
            setTarget(rpm: target, for: fan.id)
        }
    }

    /// What the curve is asking for right now, for the editor's live marker.
    var curveOperatingPoint: (celsius: Double, fraction: Double)? {
        guard let hottest = hottestSensor?.celsius else { return nil }
        return (hottest, curve.fraction(at: hottest))
    }

    /// The curve's current answer in rpm, which is the number that actually
    /// means something to someone reading it.
    var curveTargetRPM: Int? {
        guard let point = curveOperatingPoint, let fan = selectedFan else { return nil }
        return Int(fan.minimum + (fan.maximum - fan.minimum) * point.fraction)
    }

    // MARK: - Sleep

    /// Returns the fans to the system before the Mac sleeps, remembering what
    /// to restore. Synchronous: the system is waiting on this notification.
    func suspendForSleep() {
        guard !sleepSuspended else { return }
        sleepSuspended = true

        // Our own record of what we hold, not the hardware's mode bit: a fan
        // written to a second ago may not have been polled back yet.
        let heldIDs = heldFanIDs.union(fans.filter { $0.mode == .manual }.map(\.id))
        let targets = Dictionary(uniqueKeysWithValues:
            fans.filter { heldIDs.contains($0.id) }.map { ($0.id, $0.target) })
        heldBeforeSleep = (curveEnabled, targets)
        lastCurveTarget.removeAll()

        // Unconditional. Two SMC writes cost nothing, and doing it even when we
        // believe nothing is held also clears a hold left behind by an earlier
        // run that was killed before it could tidy up.
        emergencyRestore()
        for index in fans.indices { fans[index].mode = .automatic }
        heldFanIDs.removeAll()

        Diagnostics.fans.info("sleep: released \(targets.count, privacy: .public) held fan(s), curve=\(self.curveEnabled, privacy: .public)")
        lastMessage = "Fans returned to automatic for sleep."
    }

    /// Picks the fans back up once the machine is awake again.
    func resumeAfterWake() {
        guard sleepSuspended else { return }

        Task { [weak self] in
            // The SMC is not reliably writable the instant the system wakes.
            try? await Task.sleep(for: .seconds(2))
            guard let self else { return }

            self.sleepSuspended = false
            Diagnostics.fans.info("wake: resuming")
            guard let held = self.heldBeforeSleep else { return }
            self.heldBeforeSleep = nil

            guard self.control.canControl else {
                self.lastMessage = "Fans left on automatic after waking."
                return
            }

            if held.curve {
                // The curve re-applies itself on the next poll now that the
                // suspension is lifted.
                self.lastMessage = "Curve resumed after waking."
            } else {
                for (fanID, rpm) in held.targets {
                    self.setTarget(rpm: rpm, for: fanID)
                }
            }
        }
    }

    // MARK: - Fan control

    /// Puts a fan under manual control and pins it to `rpm`.
    func setTarget(rpm: Double, for fanID: Int) {
        guard let index = fans.firstIndex(where: { $0.id == fanID }) else { return }
        let fan = fans[index]
        let clamped = rpm.clamped(to: fan.minimum...fan.maximum)

        guard control.canControl else {
            lastMessage = control.reason ?? "Fan control unavailable"
            return
        }

        // The next poll reports what the SMC actually did; this is only so the
        // control does not visibly lag the drag that caused it.
        fans[index].target = clamped
        fans[index].mode = .manual

        if isRoot {
            do {
                try probe.setTarget(rpm: clamped, fanIndex: fanID)
                heldFanIDs.insert(fanID)
                lastMessage = "\(fan.name) held at \(Int(clamped)) rpm"
            } catch {
                lastMessage = error.localizedDescription
                control = .denied(error.localizedDescription)
            }
        } else {
            heldFanIDs.insert(fanID)
            helper.setTarget(rpm: clamped, fanIndex: fanID) { [weak self] failure in
                Task { @MainActor in
                    self?.lastMessage = failure ?? "\(fan.name) held at \(Int(clamped)) rpm"
                }
            }
        }
    }

    /// Slams a fan to its SMC-declared ceiling.
    func setMaximum(for fanID: Int) {
        guard let fan = fans.first(where: { $0.id == fanID }) else { return }
        setTarget(rpm: fan.maximum, for: fanID)
    }

    /// Hands the fan back to the system's own thermal governor.
    func setAutomatic(for fanID: Int) {
        guard let index = fans.firstIndex(where: { $0.id == fanID }) else { return }
        let fan = fans[index]
        lastCurveTarget[fanID] = nil

        guard control.canControl else {
            lastMessage = control.reason ?? "Fan control unavailable"
            return
        }

        fans[index].mode = .automatic
        heldFanIDs.remove(fanID)

        if isRoot {
            do {
                try probe.setAutomatic(fanIndex: fanID)
                lastMessage = "\(fan.name) returned to automatic"
            } catch {
                lastMessage = error.localizedDescription
            }
        } else {
            helper.setAutomatic(fanIndex: fanID) { [weak self] failure in
                Task { @MainActor in
                    self?.lastMessage = failure ?? "\(fan.name) returned to automatic"
                }
            }
        }
    }

    func setAll(to fraction: Double) {
        for fan in fans {
            let rpm = fan.minimum + (fan.maximum - fan.minimum) * fraction.clamped(to: 0...1)
            setTarget(rpm: rpm, for: fan.id)
        }
    }

    func restoreAutomaticControl() {
        for fan in fans where fan.mode == .manual {
            setAutomatic(for: fan.id)
        }
    }

    /// Hands every fan back to the SMC without touching published state.
    /// This is the path used when the process is going away — a signal, an
    /// `atexit` hook, `applicationWillTerminate` — so it must not care about
    /// what the UI currently believes.
    nonisolated func emergencyRestore() {
        Diagnostics.fans.info("restoring every fan to automatic")
        // Whichever path can actually write: as root, straight to the SMC;
        // otherwise a blocking round trip to the daemon.
        if geteuid() == 0 {
            probe.restoreAllAutomatic()
        } else {
            helper.restoreAllSynchronously()
        }
    }
}
