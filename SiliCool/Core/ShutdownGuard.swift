//
//  ShutdownGuard.swift
//  SiliCool
//
//  A pinned fan stays pinned until something tells the SMC otherwise — the
//  setting outlives the process. So every way this app can exit has to hand
//  the fans back first.
//
//  Covered here:
//    · Quit / ⌘Q / logout        → applicationWillTerminate
//    · Ctrl-C in the terminal    → SIGINT
//    · `kill`, launchd shutdown  → SIGTERM, SIGHUP, SIGQUIT
//    · exit() from anywhere      → atexit hook
//
//  Not coverable: SIGKILL (`kill -9`, force quit) cannot be trapped by any
//  process. After one of those the fans stay where you left them until the SMC
//  resets on sleep, or you relaunch and press Release.
//

import Foundation

/// Set once at install time; the `atexit` hook has no context pointer to work
/// with, so the reference has to be reachable globally.
nonisolated(unsafe) private var guardedMonitor: HardwareMonitor?

@MainActor
enum ShutdownGuard {
    private static var sources: [DispatchSourceSignal] = []
    private static var installed = false

    static func install(monitor: HardwareMonitor) {
        guard !installed else { return }
        installed = true
        guardedMonitor = monitor

        for number in [SIGINT, SIGTERM, SIGHUP, SIGQUIT] {
            // The default disposition would kill us before the handler runs.
            signal(number, SIG_IGN)

            let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
            source.setEventHandler {
                monitor.stop()
                exit(0)
            }
            source.resume()
            sources.append(source)
        }

        atexit {
            guardedMonitor?.emergencyRestore()
        }
    }
}
