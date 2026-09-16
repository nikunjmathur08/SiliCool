//
//  SMCKeyCatalog.swift
//  SiliCool
//
//  Sensor naming.
//
//  Apple has never published any of this. Every Apple silicon mapping below is
//  reverse-engineered, and comes from the two projects that maintain real
//  per-generation tables:
//
//    · dkorunic/iSMC — src/temp.txt, derived from hardware dumps per chip
//      (report-m1-max … report-m5-max) plus a stress-and-correlate `guess` pass
//    · exelban/stats — Modules/Sensors/values.swift, community-curated
//
//  The two disagree in places (all of M3's `Tf*`, M2 efficiency cores, M4 cores
//  past the fourth). They agree exactly on M5, and that agreement checks out
//  against this machine: all six `Tp00…Tp0K` super cores, all twelve
//  `Tp0O…Tp0y` performance cores, and a `Tg08…Tg43` GPU family of exactly 42.
//  Where they conflict, or where a key is a placeholder like "Sensor Group 1",
//  the raw key is shown instead of a guess.
//
//  Two further traps the sources warn about, both handled here:
//    · The same key means different things on Intel and Apple silicon — `Ts*`
//      is palm-rest skin on Intel but SSD dies on Apple silicon, `Tm*` is
//      mainboard on Intel but memory on Apple silicon.
//    · Some keys are not sensors. On M5 `Ta00…Ta0R` are aliases of a single
//      thermal-headroom register, and `TR0Z` is a fixed ~51.85 °C reference.
//      Both are filtered out rather than shown as temperatures.
//

import Foundation

nonisolated enum SMCKeyCatalog {

    // MARK: Fans

    static let fanCount = "FNum"

    static func fanActual(_ index: Int) -> String { "F\(index)Ac" }
    static func fanMinimum(_ index: Int) -> String { "F\(index)Mn" }
    static func fanMaximum(_ index: Int) -> String { "F\(index)Mx" }
    static func fanTarget(_ index: Int) -> String { "F\(index)Tg" }

    /// Apple silicon uses a lowercase `F0md`; Intel machines use `F0Md`.
    static func fanModeCandidates(_ index: Int) -> [String] { ["F\(index)md", "F\(index)Md"] }

    /// Intel-era bitmask that forces individual fans into manual mode.
    static let fanForceBitmask = "FS! "

    // MARK: Power

    static let powerKeys: [(key: String, name: String)] = [
        ("PSTR", "System Total"),
        ("PDTR", "Adapter In"),
        ("PPBR", "Battery"),
        ("PMTR", "Package"),
        ("PC0C", "CPU Core"),
        ("PG0R", "GPU Rail")
    ]

    static func isPlausibleTemperature(_ celsius: Double) -> Bool {
        celsius > 5 && celsius < 125
    }

    // MARK: - Individually named keys

    private static let exactNames: [String: String] = [
        // SoC
        "TCMb": "CPU Die Average",
        "TCMz": "CPU Die Max",
        "TCDX": "CPU Die Aggregate",
        "TF2S": "Fabric Sensor 2",
        "TSG1": "Sensor Group 1",
        "TSG2": "Sensor Group 2",
        "TUDX": "Uncore Die Max",

        // Storage — `Ts*` is SSD on Apple silicon, not skin
        "Ts0P": "SSD Controller 1",
        "Ts1P": "SSD Controller 2",
        "TS0P": "SSD Proximity",
        "TH0a": "SSD Drive A",
        "TH0b": "SSD Drive B",
        "TH0x": "NAND Max",

        // Battery
        "TB0T": "Battery",
        "TB1T": "Battery Thermistor 1",
        "TB2T": "Battery Thermistor 2",

        // Enclosure and airflow
        "TAOL": "Ambient Outside Lid",
        "TaLP": "Airflow Left",
        "TaRF": "Airflow Right",
        "TaLT": "Thunderbolt Left",
        "TaRT": "Thunderbolt Right",
        "TaTP": "Ambient Top",
        "TW0P": "Wi-Fi",
        // Apple's own firmware string says charger proximity, not CPU heatpipe
        // as one community table has it — and this Mac reads it ~40 °C below
        // the CPU die, which fits the charger.
        "TCHP": "Charger Proximity",

        // Power
        "TMVR": "Memory Voltage Regulator",
        "TPMP": "Power Management Proximity",
        "TPSP": "Power Supply Proximity",
        "TPH3": "Power Heatsink 3",
        "TPDX": "Power Delivery Max",
        "TRDX": "RF Delivery Max",
        "TUVR": "Uncore Voltage Regulator"
    ]

    // MARK: - CPU core slots
    //
    // The published M5 list has six first-tier and twelve second-tier keys —
    // but that came from an M5 Max dump, and an M5 Pro has five and ten. The
    // SMC still exposes the full slot range either way, so these are treated as
    // an *ordering*, truncated to the core count the OS actually reports. Any
    // slot past that count is a cluster probe, not a core, and is labelled as
    // one rather than being counted as a core that does not exist.

    private static let firstTierSlots = ["Tp00", "Tp04", "Tp08", "Tp0C", "Tp0G", "Tp0K"]
    private static let secondTierSlots = ["Tp0O", "Tp0R", "Tp0U", "Tp0X", "Tp0a", "Tp0d",
                                          "Tp0g", "Tp0j", "Tp0m", "Tp0p", "Tp0u", "Tp0y"]

    // MARK: - Ordinal families
    //
    // The grid families are numbered by sorted key order, which is exactly how
    // both sources number them (`Tg08` = GPU 1 through `Tg43` = GPU 42).

    private struct Family {
        let label: String
        let matches: (String) -> Bool
    }

    // Note the wording: these are die probes, not parts, unless the count is
    // checked against the hardware first. This Mac has 16 GPU cores but 42 `Tg`
    // keys, so numbering them "GPU 1…42" would imply cores that do not exist —
    // the same mistake as the CPU tiers above.
    private static let ordinalFamilies: [Family] = [
        Family(label: "GPU Probe") { $0.hasPrefix("Tg") },
        Family(label: "GPU Fabric") { $0.hasPrefix("TfC") },
        Family(label: "Memory Probe") { $0.hasPrefix("Tm") },
        Family(label: "SSD Die") { $0.hasPrefix("Ts") },
        Family(label: "Uncore Die") { $0.hasPrefix("TUD") },
        Family(label: "Power Delivery") { $0.hasPrefix("TPD") },
        Family(label: "RF Delivery") { $0.hasPrefix("TRD") },
        Family(label: "SoC Diode") { $0.hasPrefix("TD0") || $0.hasPrefix("TD1") || $0.hasPrefix("TD2") },
        Family(label: "Package") { $0.hasPrefix("TN0") },
        Family(label: "Virtual Die") { $0.hasPrefix("TVD") },
        Family(label: "Voltage Probe") { $0.hasPrefix("TV0") || $0.hasPrefix("TV1") }
    ]

    /// Builds the display names for a machine's whole live key set at once, so
    /// the ordinals are numbered against every probe the family has — not just
    /// the subset that ends up being polled.
    static func displayNames(for keys: [String], inventory: HardwareInventory) -> [String: String] {
        var names: [String: String] = [:]
        let sorted = keys.sorted()
        let cpuKeys = sorted.filter { $0.hasPrefix("Tp") }

        // One label per core the OS reports, no more. Tier names come from
        // sysctl too ("Super", "Performance", "Efficiency"), so this stays
        // correct across chip generations without a vocabulary table.
        var namedCores: Set<String> = []
        for (tierIndex, slots) in [firstTierSlots, secondTierSlots].enumerated() {
            guard tierIndex < inventory.cpuTiers.count else { break }
            let tier = inventory.cpuTiers[tierIndex]
            let present = slots.filter(cpuKeys.contains)
            for (index, key) in present.prefix(tier.coreCount).enumerated() {
                names[key] = "\(tier.name) Core \(index + 1)"
                namedCores.insert(key)
            }
        }

        // Whatever is left in the family is a cluster-level probe.
        let clusterProbes = cpuKeys.filter { !namedCores.contains($0) }
        for (index, key) in clusterProbes.enumerated() {
            names[key] = "CPU Cluster Probe \(index + 1)"
        }

        for family in ordinalFamilies {
            let members = sorted.filter { family.matches($0) && names[$0] == nil && exactNames[$0] == nil }

            // A family is only described as cores when there is exactly one
            // probe per core the hardware reports. Otherwise it stays "Probe".
            var label = family.label
            if family.label == "GPU Probe", let cores = inventory.gpuCoreCount, cores == members.count {
                label = "GPU Core"
            }

            for (index, key) in members.enumerated() {
                names[key] = "\(label) \(index + 1)"
            }
        }

        // Named keys win over any family ordinal.
        for (key, name) in exactNames where keys.contains(key) {
            names[key] = name
        }

        return names
    }

    /// The raw key is the honest label when nothing better is known.
    static func name(for key: String, in names: [String: String]) -> String {
        names[key] ?? key
    }

    // MARK: - Grouping

    private static let exactGroups: [String: SensorGroupKind] = [
        "TCMb": .socPackage, "TCMz": .socPackage, "TCDX": .socPackage,
        "TF2S": .socPackage, "TSG1": .socPackage, "TSG2": .socPackage,
        "TS0P": .storage,
        "TCHP": .enclosure, "TW0P": .enclosure, "TAOL": .enclosure,
        "TMVR": .powerDelivery, "TUVR": .powerDelivery
    ]

    private static let familyGroups: [(prefix: String, group: SensorGroupKind)] = [
        ("Tp", .cpuCores),
        ("Te", .cpuCores),
        ("Tg", .gpu),
        ("TG", .gpu),
        ("Tf", .gpu),
        ("Tm", .memory),
        ("TM", .memory),
        ("Ts", .storage),
        ("TH", .storage),
        ("TB", .battery),
        ("Ta", .enclosure),
        ("TA", .enclosure),
        ("TS", .enclosure),
        ("TC", .socPackage),
        ("TD", .socPackage),
        ("TN", .socPackage),
        ("TU", .socPackage),
        ("TP", .powerDelivery),
        ("TR", .powerDelivery),
        ("TV", .powerDelivery)
    ]

    static func group(for key: String) -> SensorGroupKind {
        if let exact = exactGroups[key] { return exact }
        for family in familyGroups where key.hasPrefix(family.prefix) { return family.group }
        return .other
    }

    /// How many probes of each group are worth polling every second. Sampling
    /// every one of the 250-odd live keys costs ~35 ms; this keeps it near 10.
    static let pollBudget: [SensorGroupKind: Int] = [
        .cpuCores: 20,
        .gpu: 10,
        .memory: 10,
        .socPackage: 10,
        .storage: 8,
        .battery: 3,
        .enclosure: 8,
        .powerDelivery: 8,
        .other: 4
    ]
}
