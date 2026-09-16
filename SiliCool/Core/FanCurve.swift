//
//  FanCurve.swift
//  SiliCool
//
//  A temperature-to-speed curve. Four fixed temperature anchors with a
//  draggable percentage at each: enough to shape the response usefully, few
//  enough to edit with a finger in a 370pt panel.
//

import Foundation

nonisolated struct FanCurve: Codable, Equatable, Sendable {
    /// The temperatures the percentages are pinned to.
    static let anchors: [Double] = [50, 65, 80, 95]

    /// Fraction of each fan's ceiling, one per anchor.
    var percentages: [Double]

    init(_ percentages: [Double]) {
        self.percentages = percentages
    }

    /// Piecewise linear between anchors, flat outside them.
    func fraction(at celsius: Double) -> Double {
        let anchors = Self.anchors
        guard percentages.count == anchors.count else { return 0 }
        if celsius <= anchors[0] { return percentages[0] }
        if celsius >= anchors[anchors.count - 1] { return percentages[anchors.count - 1] }

        for index in 1..<anchors.count where celsius <= anchors[index] {
            let span = anchors[index] - anchors[index - 1]
            let local = span > 0 ? (celsius - anchors[index - 1]) / span : 0
            return percentages[index - 1] + (percentages[index] - percentages[index - 1]) * local
        }
        return percentages[percentages.count - 1]
    }

    static let quiet = FanCurve([0.00, 0.15, 0.45, 0.85])
    static let balanced = FanCurve([0.10, 0.30, 0.65, 1.00])
    static let aggressive = FanCurve([0.25, 0.55, 0.90, 1.00])

    static let presets: [(name: String, curve: FanCurve)] = [
        ("Quiet", .quiet), ("Balanced", .balanced), ("Aggressive", .aggressive)
    ]
}
