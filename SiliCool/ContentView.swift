//
//  ContentView.swift
//  SiliCool
//
//  Created by Nikunj Mathur on 06/09/26.
//
//  The menu bar panel: name and Quit at the top, the gauge, the controls, and
//  the sensor list taking whatever height is left.
//

import SwiftUI

struct ControlPanel: View {
    @State private var monitor: HardwareMonitor

    init(monitor: HardwareMonitor = HardwareMonitor()) {
        _monitor = State(initialValue: monitor)
    }

    @Environment(\.colorScheme) private var colorScheme
    @State private var showsSettings = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: Color {
        Heat.colour(for: monitor.thermalLoad, scheme: colorScheme)
    }

    /// The badge only earns its place when the whole machine is at the stop.
    private var allFansMaxed: Bool {
        !monitor.fans.isEmpty && monitor.fans.allSatisfy(\.isAtCeiling)
    }

    private var statusColour: Color {
        switch monitor.status {
        case .live: return accent
        case .connecting: return .secondary
        case .unavailable: return .orange
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            header

            if monitor.status.isLive, let fan = monitor.selectedFan {
                FanGauge(rpm: fan.actual,
                         minimumRPM: fan.minimum,
                         maximumRPM: fan.maximum,
                         duty: fan.duty,
                         thermalLoad: monitor.thermalLoad,
                         isPinnedToMaximum: allFansMaxed,
                         diameter: 190,
                         isAnimating: monitor.isPanelVisible && monitor.animateGauge && !reduceMotion)

                ControlDeck(monitor: monitor)

                Divider().opacity(0.5)

                if showsSettings {
                    SettingsPanel(monitor: monitor)
                } else {
                    HistoryChart(history: monitor.history, thermalLoad: monitor.thermalLoad)
                    SensorPanel(monitor: monitor)
                }
            } else {
                unavailable
            }
        }
        .padding(16)
        // Visibility itself comes from the window server (see AppDelegate);
        // this only refreshes state the user may have changed in System
        // Settings while the panel was shut.
        .onAppear { monitor.refreshControlAuthority() }
        // The heat glow washes across the panel and fades out — no panel fills,
        // no borders, nothing with a visible edge.
        .background {
            RadialGradient(colors: [accent.opacity(0.10), .clear],
                           center: .init(x: 0.5, y: 0.30),
                           startRadius: 0,
                           endRadius: 300)
            .animation(.easeInOut(duration: 1.2), value: monitor.thermalLoad)
        }
        .background(.regularMaterial)
        .frame(width: 400, height: 760)
    }

    /// Shown instead of the gauge when there is nothing real to show.
    private var unavailable: some View {
        VStack(spacing: 10) {
            Spacer()

            Image(systemName: monitor.status.isLive ? "fan" : "exclamationmark.triangle")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.tertiary)

            Text(monitor.status.label)
                .font(Theme.label(13, weight: .semibold))

            Text(monitor.status.detail)
                .font(Theme.label(11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("SiliCool")
                .font(Theme.label(15, weight: .semibold))

            Circle()
                .fill(statusColour)
                .frame(width: 5, height: 5)
                .help(monitor.status.detail)

            Spacer()

            Button {
                showsSettings.toggle()
            } label: {
                Image(systemName: showsSettings ? "chart.bar.fill" : "gearshape.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(showsSettings ? Color.accentColor : Color.secondary)
                    .frame(width: 26, height: 22)
                    .background(Capsule().fill(Color.primary.opacity(0.07)))
            }
            .buttonStyle(.plain)
            .help(showsSettings ? "Back to sensors" : "Settings")


            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
                    .font(Theme.label(11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.primary.opacity(0.07)))
            }
            .buttonStyle(.plain)
            .help("Quitting returns every fan to automatic control")
        }
    }
}

#Preview {
    // Real hardware, read once — there is no sample data to fall back on.
    let monitor = HardwareMonitor()
    let probe = SensorProbe()
    monitor.applyOneShot(discovery: probe.discover(), snapshot: probe.sample())
    return ControlPanel(monitor: monitor)
}
