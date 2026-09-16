//
//  CurveEditor.swift
//  SiliCool
//
//  Drag a point to change how hard the fans work at that temperature. The
//  anchors are fixed at 50/65/80/95 °C so there is nothing to add, delete or
//  mis-order — only the four heights are yours.
//

import SwiftUI

struct CurveEditor: View {
    @Binding var curve: FanCurve
    /// Where the machine actually is right now, drawn on the same axes.
    var operatingPoint: (celsius: Double, fraction: Double)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var dragging: Int?

    private let minC = 40.0
    private let maxC = 100.0

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                let size = geometry.size

                ZStack {
                    Canvas { ctx, size in
                        drawGrid(&ctx, size: size)
                        drawCurve(&ctx, size: size)
                        drawOperatingPoint(&ctx, size: size)
                    }

                    // Handles are real views so they take focus and hit-testing
                    // properly, rather than being painted into the canvas.
                    ForEach(Array(FanCurve.anchors.enumerated()), id: \.offset) { index, celsius in
                        Circle()
                            .fill(.background)
                            .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: 2))
                            .frame(width: dragging == index ? 15 : 12,
                                   height: dragging == index ? 15 : 12)
                            .position(x: x(for: celsius, in: size),
                                      y: y(for: curve.percentages[index], in: size))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let index = dragging ?? nearestAnchor(to: value.location.x, in: size)
                            dragging = index
                            let fraction = 1 - (value.location.y / size.height)
                            curve.percentages[index] = min(1, max(0, fraction))
                        }
                        .onEnded { _ in dragging = nil }
                )
            }
            .frame(height: 92)

            HStack {
                ForEach(FanCurve.anchors, id: \.self) { celsius in
                    Text(verbatim: "\(Int(celsius))°")
                        .font(Theme.label(9))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: Geometry

    private func x(for celsius: Double, in size: CGSize) -> CGFloat {
        let t = (celsius - minC) / (maxC - minC)
        return size.width * CGFloat(min(1, max(0, t)))
    }

    private func y(for fraction: Double, in size: CGSize) -> CGFloat {
        size.height * CGFloat(1 - min(1, max(0, fraction)))
    }

    private func nearestAnchor(to pointX: CGFloat, in size: CGSize) -> Int {
        var best = 0
        var distance = CGFloat.greatestFiniteMagnitude
        for (index, celsius) in FanCurve.anchors.enumerated() {
            let candidate = abs(x(for: celsius, in: size) - pointX)
            if candidate < distance { distance = candidate; best = index }
        }
        return best
    }

    // MARK: Drawing

    private func drawGrid(_ ctx: inout GraphicsContext, size: CGSize) {
        var grid = Path()
        for fraction in [0.0, 0.5, 1.0] {
            let lineY = size.height * (1 - fraction)
            grid.move(to: CGPoint(x: 0, y: lineY))
            grid.addLine(to: CGPoint(x: size.width, y: lineY))
        }
        ctx.stroke(grid, with: .color(.primary.opacity(0.08)), lineWidth: 1)
    }

    private func drawCurve(_ ctx: inout GraphicsContext, size: CGSize) {
        var line = Path()
        var fill = Path()
        fill.move(to: CGPoint(x: 0, y: size.height))

        // Flat before the first anchor and after the last, matching how the
        // curve is actually evaluated.
        let points = FanCurve.anchors.enumerated().map { index, celsius in
            CGPoint(x: x(for: celsius, in: size), y: y(for: curve.percentages[index], in: size))
        }
        let full = [CGPoint(x: 0, y: points[0].y)] + points + [CGPoint(x: size.width, y: points[points.count - 1].y)]

        for (index, point) in full.enumerated() {
            index == 0 ? line.move(to: point) : line.addLine(to: point)
            fill.addLine(to: point)
        }
        fill.addLine(to: CGPoint(x: size.width, y: size.height))
        fill.closeSubpath()

        ctx.fill(fill, with: .color(Color.accentColor.opacity(0.12)))
        ctx.stroke(line, with: .color(Color.accentColor),
                   style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }

    private func drawOperatingPoint(_ ctx: inout GraphicsContext, size: CGSize) {
        guard let point = operatingPoint else { return }
        let px = x(for: point.celsius, in: size)

        var marker = Path()
        marker.move(to: CGPoint(x: px, y: 0))
        marker.addLine(to: CGPoint(x: px, y: size.height))
        ctx.stroke(marker, with: .color(.primary.opacity(0.25)),
                   style: StrokeStyle(lineWidth: 1, dash: [2, 3]))

        let py = y(for: point.fraction, in: size)
        let dot = CGRect(x: px - 3.5, y: py - 3.5, width: 7, height: 7)
        ctx.fill(Path(ellipseIn: dot),
                 with: .color(Heat.colour(for: (point.celsius - 55) / 50, scheme: colorScheme)))
    }
}
