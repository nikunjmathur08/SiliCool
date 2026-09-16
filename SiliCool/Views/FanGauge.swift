//
//  FanGauge.swift
//  SiliCool
//
//  A ring of identical bars around a soft heat glow, with the fan's rpm in the
//  middle. Two things track fan speed, and nothing else does: how far the bars
//  reach inward, and how bright they are.
//
//  One TimelineView drives one Canvas which draws both the bars and the heat
//  streaks. The streaks are a pure function of time and index, so the whole
//  animation keeps no state beyond a single rotation accumulator.
//

import SwiftUI

// MARK: - Spin integrator

/// Carries the ring's continuous state between frames: its angle, and eased
/// versions of the two values that would otherwise step once a second when a
/// new SMC reading lands.
final class RingClock {
    private var lastTimestamp: Double?
    private(set) var phase: Double = 0
    private var rate: Double = 0
    private var level: Double?

    struct Frame {
        var phase: Double
        /// Fan speed 0...1, eased — bar length and brightness both follow this.
        var level: Double
    }

    func advance(to date: Date, targetRate: Double, targetLevel: Double) -> Frame {
        let now = date.timeIntervalSinceReferenceDate
        defer { lastTimestamp = now }

        guard let last = lastTimestamp, let current = level else {
            rate = targetRate
            level = targetLevel
            return Frame(phase: phase, level: targetLevel)
        }

        let dt = min(max(now - last, 0), 1.0 / 15.0)
        rate += (targetRate - rate) * min(1, dt * 2.2)
        let eased = current + (targetLevel - current) * min(1, dt * 2.5)
        level = eased

        phase = (phase + rate * dt * 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
        return Frame(phase: phase, level: eased)
    }
}

// MARK: - Gauge

struct FanGauge: View {
    var rpm: Double
    var minimumRPM: Double
    var maximumRPM: Double
    /// 0...1, the fan's speed as a fraction of its ceiling. Drives bar length
    /// and bar brightness alike.
    var duty: Double
    var thermalLoad: Double
    var isPinnedToMaximum: Bool
    var diameter: CGFloat = 200
    /// False when the panel is closed. A canvas redrawing at 120 Hz behind a
    /// shut popover costs CPU, GPU and the surfaces backing both.
    var isAnimating: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    /// Real fans spin far too fast to render literally. The ceiling here is
    /// set by the bars themselves: 120 of them sit 3° apart, so anything past
    /// ~0.2 rev/s advances more than half a bar per frame at 60 Hz and the ring
    /// starts to strobe backwards like a wagon wheel. Speed is carried by bar
    /// length, brightness and the motion smear instead.
    private var revolutionsPerSecond: Double {
        let normalised = ((rpm - minimumRPM) / max(maximumRPM - minimumRPM, 1)).clamped(to: 0...1)
        return 0.03 + pow(normalised, 0.85) * 0.17
    }

    var body: some View {
        ZStack {
            glow
            BladeRing(revolutionsPerSecond: revolutionsPerSecond,
                      duty: duty,
                      accent: Heat.colour(for: thermalLoad, scheme: colorScheme),
                      isAnimating: isAnimating)
            readout
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeInOut(duration: 0.9), value: thermalLoad)
    }

    /// A soft, edgeless bloom. No fill, no border — it fades to nothing well
    /// before the bounds, so the gauge sits on the panel rather than in a box.
    private var glow: some View {
        Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Heat.colour(for: thermalLoad, scheme: colorScheme, opacity: 0.34), location: 0.0),
                    .init(color: Heat.colour(for: thermalLoad, scheme: colorScheme, opacity: 0.16), location: 0.42),
                    .init(color: .clear, location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: diameter * 0.46))
            .blur(radius: 18)
            .allowsHitTesting(false)
    }

    private var readout: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(rpm, format: .number.precision(.fractionLength(0)).grouping(.never))
                    .font(Theme.number(diameter * 0.15, weight: .semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: rpm))

                Text("rpm")
                    .font(Theme.label(diameter * 0.045, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            // Bars reach at most 21% of the radius inward; this keeps the
            // readout inside the remaining circle at any speed.
            .frame(maxWidth: diameter * 0.62)

            if isPinnedToMaximum {
                Text("MAX")
                    .font(Theme.label(diameter * 0.042, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Heat.colour(for: thermalLoad, scheme: colorScheme))
            }
        }
        .animation(.snappy(duration: 0.45), value: rpm)
    }
}

// MARK: - Blade ring

/// Every bar is identical: same length, same width, same colour. Speed changes
/// how far they all reach in, and how brightly they all read.
private struct BladeRing: View {
    var revolutionsPerSecond: Double
    var duty: Double
    var accent: Color
    var isAnimating: Bool

    private let tickCount = 120

    @State private var clock = RingClock()

    var body: some View {
        // 30 fps, not the display's 120. The ring turns at 0.2 rev/s, so a
        // third of the frames look identical — and each frame the canvas draws
        // costs backing-store memory that is slow to be reclaimed.
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isAnimating)) { context in
            Canvas { ctx, size in
                let frame = clock.advance(to: context.date,
                                          targetRate: revolutionsPerSecond,
                                          targetLevel: duty.clamped(to: 0...1))
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let outerRadius = min(size.width, size.height) / 2 - 4
                let speed = frame.level

                // Length and brightness both track fan speed. Brightness has a
                // floor so a fan at its idle 30% is still legible.
                let length = outerRadius * (0.05 + 0.16 * speed)
                let brightness = max(0.22, speed)

                // A three-pass smear at speed: the same ring drawn a fraction of
                // a degree either side, which reads as motion blur and hides the
                // hard edge each bar would otherwise have.
                let smear = 0.010 * speed
                let passes: [(offset: Double, weight: Double)] = speed > 0.35
                    ? [(-smear, 0.28), (0, 0.55), (smear, 0.28)]
                    : [(0, 1.0)]

                for pass in passes {
                    ctx.stroke(ringPath(center: center,
                                        innerRadius: outerRadius - length,
                                        outerRadius: outerRadius,
                                        phase: frame.phase + pass.offset),
                               with: .color(.primary.opacity(brightness * pass.weight)),
                               style: StrokeStyle(lineWidth: 2.1, lineCap: .round))
                }

                drawHeatStreaks(into: &ctx,
                                center: center,
                                ringRadius: outerRadius,
                                time: context.date.timeIntervalSinceReferenceDate,
                                intensity: speed)
            }
        }
    }

    private func ringPath(center: CGPoint, innerRadius: Double, outerRadius: Double, phase: Double) -> Path {
        var path = Path()
        for index in 0..<tickCount {
            let angle = Double(index) / Double(tickCount) * 2 * .pi - .pi / 2 + phase
            let cosine = cos(angle), sine = sin(angle)
            path.move(to: CGPoint(x: center.x + cosine * innerRadius,
                                  y: center.y + sine * innerRadius))
            path.addLine(to: CGPoint(x: center.x + cosine * outerRadius,
                                     y: center.y + sine * outerRadius))
        }
        return path
    }

    /// Exhaust leaving the ring. Each streak picks a fresh angle every time it
    /// recycles — reusing the same 60 angles forever is what made the old
    /// version read as a loop — and fades in and out along its travel.
    /// Positions are still a pure function of time and index, so there is
    /// nothing to allocate or keep between frames.
    private func drawHeatStreaks(into ctx: inout GraphicsContext,
                                 center: CGPoint,
                                 ringRadius: Double,
                                 time: Double,
                                 intensity: Double) {
        let count = Int(16 + intensity * 40)

        for index in 0..<count {
            let seed = Double(index) * 0.6180339887498949
            let jitter = (seed * 12.9898).truncatingRemainder(dividingBy: 1)
            let pace = 0.16 + intensity * 0.30 + jitter * 0.14

            let progress = time * pace + jitter * 4.13
            let life = progress - progress.rounded(.down)
            let cycle = progress.rounded(.down)

            let eased = 1 - pow(1 - life, 2.1)
            let radius = ringRadius * (1.02 + 0.26 * eased)
            let angle = hash(Double(index) + cycle * 31.7) * 2 * .pi + eased * 0.22
            let length = 3 + 6 * eased
            let alpha = sin(.pi * life) * (0.10 + intensity * 0.26)

            let cosine = cos(angle), sine = sin(angle)
            var streak = Path()
            streak.move(to: CGPoint(x: center.x + cosine * radius,
                                    y: center.y + sine * radius))
            streak.addLine(to: CGPoint(x: center.x + cosine * (radius + length),
                                       y: center.y + sine * (radius + length)))

            ctx.stroke(streak,
                       with: .color(accent.opacity(alpha)),
                       style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
    }

    /// Cheap deterministic scatter in 0..<1.
    private func hash(_ value: Double) -> Double {
        let x = sin(value * 12.9898) * 43758.5453
        return x - x.rounded(.down)
    }
}
