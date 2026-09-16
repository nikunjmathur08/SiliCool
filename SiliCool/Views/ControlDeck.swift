//
//  ControlDeck.swift
//  SiliCool
//
//  Pick a fan, hold it where you want it, or hand both back to the system.
//

import SwiftUI

struct ControlDeck: View {
    @Bindable var monitor: HardwareMonitor

    @State private var draftRPM: Double = 0
    @State private var isDragging = false

    private var fan: Fan? { monitor.selectedFan }

    private enum Mode: Hashable { case automatic, curve, manual }

    /// Dragging the slider *is* going manual, so the selector says so from the
    /// first pixel of the drag rather than after the write lands.
    private var activeMode: Mode {
        if isDragging { return .manual }
        if monitor.curveEnabled { return .curve }
        return (fan?.mode ?? .automatic) == .manual ? .manual : .automatic
    }

    var body: some View {
        VStack(spacing: 12) {
            fanPicker

            if let fan {
                modeSelector(for: fan)

                if activeMode == .curve {
                    curveControls
                } else {
                    speedSlider(for: fan)
                }

                presets
            }

            helperRow
            statusLine
        }
        .onAppear { draftRPM = fan?.target ?? 0 }
        .onChange(of: monitor.selectedFanID) { _, _ in draftRPM = fan?.target ?? 0 }
        .onChange(of: fan?.target ?? 0) { _, newValue in
            if !isDragging { draftRPM = newValue }
        }
    }

    // MARK: Fan picker

    private var fanPicker: some View {
        HStack(spacing: 10) {
            ForEach(monitor.fans) { fan in
                let isSelected = fan.id == monitor.selectedFanID

                Button {
                    monitor.selectedFanID = fan.id
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(fan.name)
                                .font(Theme.label(10, weight: .semibold))
                                .foregroundStyle(isSelected ? .primary : .secondary)

                            if fan.mode == .manual {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 7))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }

                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text(verbatim: "\(Int(fan.actual))")
                                .font(Theme.number(17, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(isSelected ? .primary : .secondary)
                            Text("rpm")
                                .font(Theme.label(8))
                                .foregroundStyle(.secondary)
                        }

                        DutyBar(value: fan.duty, isActive: isSelected)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.primary.opacity(0.07))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.snappy(duration: 0.3), value: monitor.selectedFanID)
    }

    // MARK: Mode

    private func modeSelector(for fan: Fan) -> some View {
        PillSelector(items: [
            .init(value: Mode.automatic, title: "Auto", symbol: "gearshape.fill"),
            .init(value: Mode.curve, title: "Curve", symbol: "point.topleft.down.curvedto.point.bottomright.up"),
            .init(value: Mode.manual, title: "Manual", symbol: "slider.horizontal.3")
        ], selection: activeMode) { mode in
            switch mode {
            case .automatic:
                monitor.curveEnabled = false
                monitor.setAutomatic(for: fan.id)
            case .curve:
                monitor.curveEnabled = true
            case .manual:
                monitor.curveEnabled = false
                monitor.setTarget(rpm: draftRPM, for: fan.id)
            }
        }
    }

    // MARK: Curve

    private var curveControls: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Fan speed by temperature")
                    .font(Theme.label(10))
                    .foregroundStyle(.secondary)
                Spacer()
                if let point = monitor.curveOperatingPoint, let rpm = monitor.curveTargetRPM {
                    Text(verbatim: "\(Int(point.celsius))° → \(rpm) rpm")
                        .font(Theme.label(10, weight: .semibold))
                        .monospacedDigit()
                }
            }

            CurveEditor(curve: $monitor.curve, operatingPoint: monitor.curveOperatingPoint)

            HStack(spacing: 6) {
                ForEach(FanCurve.presets, id: \.name) { preset in
                    Button(preset.name) { monitor.curve = preset.curve }
                        .font(Theme.label(10, weight: .semibold))
                        .buttonStyle(.plain)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(Capsule().fill(monitor.curve == preset.curve
                                                   ? Color.accentColor.opacity(0.18)
                                                   : Color.primary.opacity(0.06)))
                        .foregroundStyle(monitor.curve == preset.curve ? Color.accentColor : Color.secondary)
                }
            }
        }
    }

    // MARK: Slider

    private func speedSlider(for fan: Fan) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("Target")
                    .font(Theme.label(10))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: "\(Int(draftRPM)) rpm · \(Int(fraction(of: draftRPM, in: fan) * 100))%")
                    .font(Theme.label(10, weight: .semibold))
                    .monospacedDigit()
            }

            PowerSlider(value: $draftRPM,
                        range: fan.minimum...max(fan.maximum, fan.minimum + 1),
                        onEditingChanged: { editing in
                            isDragging = editing
                            // Committing on release keeps this to one SMC write
                            // per adjustment instead of one per frame.
                            if !editing { monitor.setTarget(rpm: draftRPM, for: fan.id) }
                        })

            HStack {
                Text(verbatim: "\(Int(fan.minimum)) min")
                Spacer()
                Text(verbatim: "\(Int(fan.maximum)) max")
            }
            .font(Theme.label(9))
            .foregroundStyle(.tertiary)
            .monospacedDigit()
        }
    }

    // MARK: Presets

    private var presets: some View {
        VStack(spacing: 5) {
            HStack {
                Text("Both fans")
                    .font(Theme.label(10))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            PillSelector(items: [
                .init(value: Preset.maximum, title: "Max Out", symbol: "bolt.fill"),
                .init(value: Preset.automatic, title: "Automatic", symbol: "wand.and.stars")
            ], selection: activePreset) { preset in
                switch preset {
                case .maximum:
                    monitor.setAll(to: 1.0)
                    draftRPM = fan?.maximum ?? draftRPM
                case .automatic:
                    monitor.restoreAutomaticControl()
                }
            }
        }
    }

    private enum Preset: Hashable { case maximum, automatic }

    private var activePreset: Preset? {
        guard !monitor.fans.isEmpty else { return nil }
        if monitor.fans.allSatisfy(\.isAtCeiling) { return .maximum }
        if monitor.fans.allSatisfy({ $0.mode == .automatic }) { return .automatic }
        return nil
    }

    // MARK: Helper

    /// Fan control needs root. Rather than asking the user to relaunch under
    /// sudo, SiliCool installs a small daemon that owns the SMC writes; this is
    /// the one-time install and approval affordance.
    @ViewBuilder
    private var helperRow: some View {
        if !monitor.control.canControl {
            if monitor.installLocation.advice != nil {
                // Nothing to press until the app is where it needs to be.
                EmptyView()
            } else {
                switch monitor.helperStatus {
                case .notInstalled, .failed:
                    helperButton("Enable Fan Control", symbol: "lock.open.fill") {
                        monitor.installHelper()
                    }
                case .requiresApproval:
                    helperButton("Approve in System Settings", symbol: "arrow.up.forward.app.fill") {
                        monitor.openHelperApproval()
                    }
                case .ready:
                    EmptyView()
                }
            }
        }
    }

    private func helperButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(Theme.label(11, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: Status

    @ViewBuilder
    private var statusLine: some View {
        if let message = monitor.lastMessage ?? monitor.control.reason {
            HStack(spacing: 6) {

                Text(message)
                    .font(Theme.label(10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
    }

    private func fraction(of rpm: Double, in fan: Fan) -> Double {
        guard fan.maximum > 0 else { return 0 }
        return (rpm / fan.maximum).clamped(to: 0...1)
    }
}

// MARK: - Custom slider

struct PowerSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onEditingChanged: (Bool) -> Void

    private var fraction: Double {
        ((value - range.lowerBound) / (range.upperBound - range.lowerBound)).clamped(to: 0...1)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let knobX = width * fraction

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.09))
                    .frame(height: 6)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(6, knobX), height: 6)

                Circle()
                    .fill(.background)
                    .frame(width: 15, height: 15)
                    .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
                    .offset(x: knobX - 7.5)
            }
            .frame(height: 16)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        onEditingChanged(true)
                        let ratio = (drag.location.x / width).clamped(to: 0...1)
                        value = range.lowerBound + ratio * (range.upperBound - range.lowerBound)
                    }
                    .onEnded { _ in onEditingChanged(false) }
            )
        }
        .frame(height: 16)
    }
}

// MARK: - Small parts

struct DutyBar: View {
    var value: Double
    var isActive: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.1))
                Capsule()
                    .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.55))
                    .frame(width: max(3, geometry.size.width * value.clamped(to: 0...1)))
            }
        }
        .frame(height: 3)
        .animation(.easeOut(duration: 0.6), value: value)
    }
}
