//
//  SensorModels.swift
//  SiliCool
//
//  Value types shared between the background probe and the UI, so they are
//  deliberately outside the app's default main-actor isolation.
//

import Foundation

// MARK: - Fans

nonisolated enum FanMode: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case manual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: return "Auto"
        case .manual: return "Manual"
        }
    }
}

nonisolated struct Fan: Identifiable, Equatable, Sendable {
    let id: Int
    var name: String
    var actual: Double
    var minimum: Double
    var maximum: Double
    var target: Double
    var mode: FanMode

    /// Fraction of the fan's ceiling it is currently turning at. Fans idle at
    /// their floor rather than at zero, so measuring against the ceiling is
    /// what actually reads as "how hard is it working".
    var duty: Double {
        guard maximum > 0 else { return 0 }
        return (actual / maximum).clamped(to: 0...1)
    }

    var targetDuty: Double {
        guard maximum > 0 else { return 0 }
        return (target / maximum).clamped(to: 0...1)
    }

    /// Where the fan sits inside its own usable range, floor to ceiling.
    var headroomUsed: Double {
        guard maximum > minimum else { return 0 }
        return ((actual - minimum) / (maximum - minimum)).clamped(to: 0...1)
    }

    var isAtCeiling: Bool { maximum > 0 && actual >= maximum * 0.95 }
}

// MARK: - Temperatures

nonisolated struct TemperatureSensor: Identifiable, Equatable, Sendable {
    let id: String          // SMC key
    var name: String
    var group: SensorGroupKind
    var celsius: Double

    /// 0 at 55 °C, 1 at 105 °C. Apple silicon idles warm and cruises in the
    /// seventies, so the scale starts high enough that a working machine still
    /// reads as calm rather than alarming.
    var thermalLoad: Double {
        ((celsius - 55) / 50).clamped(to: 0...1)
    }
}

// MARK: - Sensor groups

/// The fixed running order of the sensor list. Grouping is what makes the
/// readings legible: this Mac exposes 23 CPU-core probes, 42 GPU probes and 40
/// memory probes, and no one outside Apple can say which physical core `Tp0C`
/// sits on — but "CPU Cores, 23 probes, peak 89 °C" is a fact worth showing.
nonisolated enum SensorGroupKind: String, CaseIterable, Identifiable, Sendable {
    case cpuCores
    case gpu
    case memory
    case socPackage
    case storage
    case battery
    case enclosure
    case powerDelivery
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cpuCores: return "CPU Cores"
        case .gpu: return "GPU"
        case .memory: return "Memory"
        case .socPackage: return "SoC & Package"
        case .storage: return "Storage"
        case .battery: return "Battery"
        case .enclosure: return "Enclosure & Airflow"
        case .powerDelivery: return "Power Delivery"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .cpuCores: return "cpu"
        case .gpu: return "cube.transparent"
        case .memory: return "memorychip"
        case .socPackage: return "square.stack.3d.up"
        case .storage: return "internaldrive"
        case .battery: return "battery.100"
        case .enclosure: return "macbook"
        case .powerDelivery: return "bolt"
        case .other: return "sensor"
        }
    }

    /// Groups that actually track compute heat, and so drive the gauge.
    var isCompute: Bool {
        switch self {
        case .cpuCores, .gpu, .memory, .socPackage: return true
        default: return false
        }
    }
}

nonisolated struct SensorGroup: Identifiable, Equatable, Sendable {
    var kind: SensorGroupKind
    /// Always ordered by key, never by temperature — the list must not reshuffle
    /// itself while you are reading it.
    var sensors: [TemperatureSensor]
    /// Ground truth about the part, where the OS can tell us — for the CPU that
    /// is the real core topology, which the probe count does not match.
    var detail: String?

    var id: String { kind.rawValue }
    var peak: Double { sensors.map(\.celsius).max() ?? 0 }
    var average: Double {
        guard !sensors.isEmpty else { return 0 }
        return sensors.map(\.celsius).reduce(0, +) / Double(sensors.count)
    }
    var thermalLoad: Double { ((peak - 55) / 50).clamped(to: 0...1) }
}

nonisolated struct PowerReading: Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var watts: Double
}

// MARK: - Snapshot

nonisolated struct HardwareSnapshot: Sendable {
    var fans: [Fan] = []
    var temperatures: [TemperatureSensor] = []
    var power: [PowerReading] = []
}

// MARK: - Status

nonisolated enum MonitorStatus: Equatable, Sendable {
    case connecting
    case live
    /// Nothing is invented to fill the gap — the panel says why instead.
    case unavailable(reason: String)

    var isLive: Bool { self == .live }

    var label: String {
        switch self {
        case .connecting: return "Reading sensors…"
        case .live: return "Live"
        case .unavailable: return "No SMC access"
        }
    }

    var detail: String {
        switch self {
        case .connecting: return "Enumerating SMC keys"
        case .live: return "reading hardware sensors"
        case .unavailable(let reason): return reason
        }
    }
}

nonisolated enum ControlAuthority: Equatable, Sendable {
    case available
    case denied(String)

    var canControl: Bool { self == .available }

    var reason: String? {
        if case .denied(let reason) = self { return reason }
        return nil
    }
}

// MARK: - Helpers

nonisolated extension Comparable {
    /// Used from the background probe as well as the views, so it lives in the
    /// core layer and must not inherit the app's main-actor default isolation.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
