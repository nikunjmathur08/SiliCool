//
//  Theme.swift
//  SiliCool
//
//  One accent colour, derived from thermal load, over the system's own
//  materials. Everything else is `Color.primary` / `.secondary`, so the panel
//  follows the system appearance in both light and dark without a second
//  palette to maintain.
//

import SwiftUI

enum Heat {
    /// A four-stop ramp through Apple's system colours, with a separate set of
    /// values per appearance. The ramp deliberately passes through neutral grey
    /// rather than blending blue straight into orange — that midpoint is an
    /// olive mud — so a calm machine reads as colourless and colour only
    /// arrives when something is genuinely warm.
    ///
    /// The dark values are lifted well above the stock system colours: at
    /// small sizes, `systemBlue` on a dark panel is too dim to read.
    private typealias Stop = (stop: Double, r: Double, g: Double, b: Double)

    private static let lightRamp: [Stop] = [
        (0.00, 0.00, 0.48, 1.00),   // systemBlue
        (0.50, 0.56, 0.56, 0.58),   // systemGray
        (0.80, 1.00, 0.58, 0.00),   // systemOrange
        (1.00, 1.00, 0.23, 0.19)    // systemRed
    ]

    private static let darkRamp: [Stop] = [
        (0.00, 0.30, 0.64, 1.00),   // lifted blue
        (0.50, 0.63, 0.63, 0.65),   // lifted grey
        (0.80, 1.00, 0.70, 0.25),   // lifted orange
        (1.00, 1.00, 0.41, 0.38)    // lifted red
    ]

    static func colour(for load: Double, scheme: ColorScheme, opacity: Double = 1) -> Color {
        let ramp = scheme == .dark ? darkRamp : lightRamp
        let t = load.clamped(to: 0...1)

        var lower = ramp[0]
        var upper = ramp[ramp.count - 1]
        for index in 1..<ramp.count where ramp[index].stop >= t {
            lower = ramp[index - 1]
            upper = ramp[index]
            break
        }

        let span = upper.stop - lower.stop
        let local = span > 0 ? (t - lower.stop) / span : 0

        return Color(.sRGB,
                     red: lower.r + (upper.r - lower.r) * local,
                     green: lower.g + (upper.g - lower.g) * local,
                     blue: lower.b + (upper.b - lower.b) * local,
                     opacity: opacity)
    }
}

enum Theme {
    static func number(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func label(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Pill selector

/// The segmented pill used for both the fan mode and the presets: a soft
/// capsule track with the active segment lifted out of it.
struct PillSelector<Value: Hashable>: View {
    struct Item: Identifiable {
        let value: Value
        let title: String
        let symbol: String
        var id: Value { value }
    }

    var items: [Item]
    var selection: Value?
    var select: (Value) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 3) {
            ForEach(items) { item in
                let isSelected = item.value == selection

                Button {
                    select(item.value)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 10, weight: .semibold))
                        Text(item.title)
                            .font(Theme.label(11, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .brightness(isSelected && colorScheme == .dark ? 0.22 : 0)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(colorScheme == .dark
                                      ? Color.white.opacity(0.15)
                                      : Color.white)
                                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.12),
                                        radius: 2, y: 1)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.primary.opacity(0.07)))
        .animation(.snappy(duration: 0.22), value: selection)
    }
}
