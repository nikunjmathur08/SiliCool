//
//  SampleHistory.swift
//  SiliCool
//
//  Ten minutes of readings at 1 Hz, in a fixed ring buffer that is allocated
//  once and never grows: 600 slots of six Floats is about 14 KB, for the whole
//  window. Nothing is appended, copied or re-sorted per sample, and reading it
//  back for the chart allocates nothing at all.
//

import Foundation

nonisolated struct HistorySample: Sendable {
    var rpm: Float = 0
    var duty: Float = 0        // 0...1 of the fan's ceiling
    var hottest: Float = 0     // °C
    var cpu: Float = 0
    var gpu: Float = 0
    var watts: Float = 0
}

nonisolated struct SampleHistory: Sendable {
    /// 600 samples at one per second — ten minutes.
    static let capacity = 600

    private var storage: ContiguousArray<HistorySample> = []
    private var head = 0

    var count: Int { storage.count }
    var isEmpty: Bool { storage.isEmpty }

    init() {
        storage.reserveCapacity(Self.capacity)
    }

    mutating func append(_ sample: HistorySample) {
        if storage.count < Self.capacity {
            storage.append(sample)
        } else {
            storage[head] = sample
            head = (head + 1) % Self.capacity
        }
    }

    /// Oldest first, without materialising a second array.
    subscript(ordered index: Int) -> HistorySample {
        let full = storage.count == Self.capacity
        return storage[full ? (head + index) % Self.capacity : index]
    }

    /// Highest value of one field across the window, for scaling a chart.
    func peak(_ field: (HistorySample) -> Float) -> Float {
        var best: Float = 0
        for index in 0..<storage.count {
            best = max(best, field(storage[index]))
        }
        return best
    }
}
