//
//  Preferences.swift
//  SiliCool
//
//  The handful of settings worth keeping between launches, in UserDefaults.
//

import Foundation
import ServiceManagement

nonisolated enum MenuBarMetric: String, CaseIterable, Codable, Sendable {
    case fanSpeed
    case cpuTemperature
    case hottest
    case power
    case iconOnly

    var title: String {
        switch self {
        case .fanSpeed: return "Fan rpm"
        case .cpuTemperature: return "CPU °C"
        case .hottest: return "Hottest °C"
        case .power: return "Watts"
        case .iconOnly: return "Icon only"
        }
    }
}

nonisolated enum Preferences {
    private static let defaults = UserDefaults.standard

    enum Key {
        static let menuBarMetric = "menuBarMetric"
        static let curve = "fanCurve"
        static let curveEnabled = "fanCurveEnabled"
        static let animateGauge = "animateGauge"
    }

    /// The live gauge is Metal-backed: while it animates the app's footprint
    /// sits around 100 MB, against ~30 MB when it is still. Bounded, but worth
    /// being able to switch off.
    static var animateGauge: Bool {
        get { defaults.object(forKey: Key.animateGauge) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.animateGauge) }
    }

    static var menuBarMetric: MenuBarMetric {
        get { MenuBarMetric(rawValue: defaults.string(forKey: Key.menuBarMetric) ?? "") ?? .fanSpeed }
        set { defaults.set(newValue.rawValue, forKey: Key.menuBarMetric) }
    }

    static var curve: FanCurve {
        get {
            guard let data = defaults.data(forKey: Key.curve),
                  let curve = try? JSONDecoder().decode(FanCurve.self, from: data) else {
                return .balanced
            }
            return curve
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Key.curve)
            }
        }
    }

    static var curveEnabled: Bool {
        get { defaults.bool(forKey: Key.curveEnabled) }
        set { defaults.set(newValue, forKey: Key.curveEnabled) }
    }

    // MARK: Launch at login

    /// Unlike the fan helper, this needs no approval — it is an ordinary login
    /// item registered for the app itself.
    static var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("SiliCool: launch at login failed — %@", error.localizedDescription)
            }
        }
    }
}
