//
//  SettingsPanel.swift
//  SiliCool
//

import SwiftUI

struct SettingsPanel: View {
    @Bindable var monitor: HardwareMonitor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                setting("Menu bar shows") {
                    Picker("", selection: $monitor.menuBarMetric) {
                        ForEach(MenuBarMetric.allCases, id: \.self) { metric in
                            Text(metric.title).tag(metric)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                }

                setting("Open at login") {
                    Toggle("", isOn: Binding(
                        get: { monitor.launchAtLogin },
                        set: { monitor.launchAtLogin = $0 }))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }

                setting("Animate the gauge") {
                    Toggle("", isOn: $monitor.animateGauge)
                        .labelsHidden().toggleStyle(.switch).controlSize(.mini)
                }

                Text("The live gauge is drawn on the GPU. Animating costs about 100 MB of memory while the panel is open, against roughly 30 MB when still — it is reclaimed either way once the panel closes.")
                    .font(Theme.label(10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().opacity(0.5)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Fan control helper")
                        .font(Theme.label(11, weight: .semibold))

                    Text(helperDescription)
                        .font(Theme.label(10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        if monitor.helperStatus != .ready {
                            Button("Install") { monitor.installHelper() }
                        }
                        if monitor.helperStatus != .notInstalled {
                            Button("Remove") { monitor.removeHelper() }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider().opacity(0.5)

                VStack(alignment: .leading, spacing: 4) {
                    detail("Machine", monitor.inventory.model)
                    detail("CPU", monitor.inventory.cpuSummary)
                    detail("GPU", monitor.inventory.gpuSummary ?? "—")
                    detail("Memory", monitor.inventory.memorySummary ?? "—")
                    detail("Sensors polled", "\(monitor.temperatures.count)")
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.never)
    }

    private var helperDescription: String {
        switch monitor.helperStatus {
        case .ready: return "Installed and approved. Fan writes go through the root daemon."
        case .requiresApproval: return "Registered — switch SiliCool on under Login Items & Extensions."
        case .notInstalled: return "Not installed. Fan control needs it, unless you run SiliCool as root."
        case .failed(let reason): return reason
        }
    }

    private func setting<Control: View>(_ title: String,
                                        @ViewBuilder control: () -> Control) -> some View {
        HStack {
            Text(title).font(Theme.label(11))
            Spacer()
            control()
        }
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.label(10))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(Theme.label(10, weight: .medium))
                .monospacedDigit()
        }
    }
}
