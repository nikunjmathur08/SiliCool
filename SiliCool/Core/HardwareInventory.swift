//
//  HardwareInventory.swift
//  SiliCool
//
//  What this machine actually is, asked of the machine itself — never of a
//  lookup table. Core counts and tier names come from sysctl, the GPU core
//  count from the IORegistry. Everything the UI claims about parts is checked
//  against these numbers before it is displayed.
//

import Foundation
import IOKit

nonisolated struct HardwareInventory: Sendable {
    struct Tier: Sendable {
        var name: String        // "Super", "Performance", "Efficiency"…
        var coreCount: Int
    }

    var model: String = ""
    var cpuTiers: [Tier] = []
    var gpuCoreCount: Int?
    var memoryBytes: UInt64 = 0

    var totalCores: Int { cpuTiers.reduce(0) { $0 + $1.coreCount } }

    /// "5 Super · 10 Performance"
    var cpuSummary: String {
        cpuTiers.map { "\($0.coreCount) \($0.name)" }.joined(separator: " · ")
    }

    var gpuSummary: String? {
        gpuCoreCount.map { "\($0) cores" }
    }

    var memorySummary: String? {
        guard memoryBytes > 0 else { return nil }
        return "\(memoryBytes / 1_073_741_824) GB"
    }

    static func current() -> HardwareInventory {
        var inventory = HardwareInventory()
        inventory.model = sysctlString("hw.model") ?? ""
        inventory.memoryBytes = UInt64(sysctlInt64("hw.memsize") ?? 0)

        for level in 0..<4 {
            guard let count = sysctlInt("hw.perflevel\(level).physicalcpu"), count > 0 else { break }
            let name = sysctlString("hw.perflevel\(level).name") ?? "Core"
            inventory.cpuTiers.append(Tier(name: name, coreCount: count))
        }
        // Pre-perflevel machines report a single flat count.
        if inventory.cpuTiers.isEmpty, let count = sysctlInt("hw.physicalcpu"), count > 0 {
            inventory.cpuTiers = [Tier(name: "CPU", coreCount: count)]
        }

        inventory.gpuCoreCount = gpuCoreCountFromIORegistry()
        return inventory
    }

    // MARK: IOKit

    private static func gpuCoreCountFromIORegistry() -> Int? {
        let matching = IOServiceMatching("AGXAccelerator")
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            let property = IORegistryEntryCreateCFProperty(service,
                                                           "gpu-core-count" as CFString,
                                                           kCFAllocatorDefault,
                                                           0)
            if let number = property?.takeRetainedValue() as? NSNumber {
                return number.intValue
            }
        }
        return nil
    }

    // MARK: sysctl

    private static func sysctlInt(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return Int(value)
    }

    private static func sysctlInt64(_ name: String) -> Int64? {
        var value: Int64 = 0
        var size = MemoryLayout<Int64>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
        return value
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }
}
