//
//  SiliCoolApp.swift
//  SiliCool
//
//  Created by Nikunj Mathur on 06/09/26.
//

import SwiftUI
import AppKit

@main
struct SiliCoolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            ControlPanel(monitor: delegate.monitor)
        } label: {
            MenuBarLabel(monitor: delegate.monitor)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Owns the monitor for the whole process lifetime — the menu bar readout has
/// to stay live whether or not the panel is open — and makes sure the fans are
/// handed back on the way out.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let monitor = HardwareMonitor()

    private var occlusionObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor.start()
        ShutdownGuard.install(monitor: monitor)
        SleepGuard.install(monitor: monitor)
        watchPanelVisibility()
    }

    /// Whether the panel is actually on screen, asked of the window server
    /// rather than inferred from `onAppear`.
    ///
    /// SwiftUI sometimes builds a MenuBarExtra's content without showing it —
    /// about one launch in three here — and an `onAppear` signal believes it,
    /// leaving the gauge animating behind a closed panel at ~105 MB. Occlusion
    /// state is the window server's own answer and does not have that problem.
    private func watchPanelVisibility() {
        let update = { [monitor] in
            monitor.isPanelVisible = NSApp.occlusionState.contains(.visible)
        }
        update()
        occlusionObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeOcclusionStateNotification,
            object: NSApp, queue: .main) { _ in
                MainActor.assumeIsolated { update() }
            }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}

/// What sits in the menu bar: whichever reading you picked, and a filled icon
/// while SiliCool is the one holding the fans.
struct MenuBarLabel: View {
    var monitor: HardwareMonitor

    private var text: String? {
        switch monitor.menuBarMetric {
        case .iconOnly:
            return nil
        case .fanSpeed:
            return monitor.fans.map(\.actual).max().map { "\(Int($0))" }
        case .cpuTemperature:
            return monitor.cpuTemperature.map { "\(Int($0))°" }
        case .hottest:
            return monitor.hottestSensor.map { "\(Int($0.celsius))°" }
        case .power:
            return monitor.totalPower.map { String(format: "%.0fW", $0) }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: monitor.hasManualFan ? "fan.fill" : "fan")
            if let text {
                Text(verbatim: text)
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
            }
        }
    }
}
