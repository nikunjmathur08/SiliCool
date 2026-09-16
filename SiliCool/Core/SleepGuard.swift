//
//  SleepGuard.swift
//  SiliCool
//
//  Hands the fans back before the Mac sleeps, and picks them up again on wake.
//
//  A pinned fan keeps spinning through sleep: the SMC holds the last target it
//  was given, and SiliCool isn't running to change its mind. The machine is
//  doing no work, so the fan is running for nothing — noise, battery, and wear
//  on a bearing, for hours.
//
//  `willSleepNotification` is delivered before the system sleeps and the system
//  waits for observers to return, so the restore here is deliberately
//  synchronous. An async XPC round trip would very likely not complete.
//

import AppKit

@MainActor
enum SleepGuard {
    private static var observers: [NSObjectProtocol] = []

    static func install(monitor: HardwareMonitor) {
        guard observers.isEmpty else { return }
        let center = NSWorkspace.shared.notificationCenter

        observers.append(center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { monitor.suspendForSleep() }
            })

        observers.append(center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { monitor.resumeAfterWake() }
            })

        // Logging out or restarting goes through here before the app is asked
        // to terminate, and sometimes instead of it.
        observers.append(center.addObserver(
            forName: NSWorkspace.willPowerOffNotification,
            object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { monitor.suspendForSleep() }
            })
    }
}
