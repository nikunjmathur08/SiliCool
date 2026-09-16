//
//  HistoryChart.swift
//  SiliCool
//
//  The last ten minutes: the hottest compute sensor as a line, fan duty as the
//  fill beneath it. Drawn straight from the ring buffer — no intermediate array
//  is built, and the chart only redraws when a sample lands.
//

import SwiftUI

struct HistoryChart: View {
    var history: SampleHistory
    var thermalLoad: Double

    @Environment(\.colorScheme) private var colorScheme

    /// A fixed 40–100 °C window, so the trace does not silently rescale itself
    /// and make a calm stretch look like a spike.
    private let floorC: Float = 40
    private let ceilingC: Float = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Last 10 minutes")
                    .font(Theme.label(10))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: "\(Int(floorC))–\(Int(ceilingC))°")
                    .font(Theme.label(9))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            Canvas { ctx, size in
                let count = history.count
                guard count > 1 else { return }

                let step = size.width / CGFloat(SampleHistory.capacity - 1)
                // A partial window draws against the right edge, so the newest
                // sample is always under the same pixel.
                let offset = size.width - CGFloat(count - 1) * step

                func y(_ celsius: Float) -> CGFloat {
                    let t = (celsius - floorC) / (ceilingC - floorC)
                    return size.height * (1 - CGFloat(max(0, min(1, t))))
                }

                var duty = Path()
                duty.move(to: CGPoint(x: offset, y: size.height))
                var line = Path()

                for index in 0..<count {
                    let sample = history[ordered: index]
                    let x = offset + CGFloat(index) * step
                    duty.addLine(to: CGPoint(x: x, y: size.height * (1 - CGFloat(sample.duty))))
                    let point = CGPoint(x: x, y: y(sample.hottest))
                    index == 0 ? line.move(to: point) : line.addLine(to: point)
                }
                duty.addLine(to: CGPoint(x: offset + CGFloat(count - 1) * step, y: size.height))
                duty.closeSubpath()

                ctx.fill(duty, with: .color(.secondary.opacity(0.16)))
                ctx.stroke(line,
                           with: .color(Heat.colour(for: thermalLoad, scheme: colorScheme)),
                           style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))

                // Emphasise where the trace ends — that is "now".
                let last = history[ordered: count - 1]
                let end = CGPoint(x: offset + CGFloat(count - 1) * step, y: y(last.hottest))
                ctx.fill(Path(ellipseIn: CGRect(x: end.x - 2.5, y: end.y - 2.5, width: 5, height: 5)),
                         with: .color(Heat.colour(for: thermalLoad, scheme: colorScheme)))
            }
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.035))
            }
        }
    }
}
