//
//  InstallLocation.swift
//  SiliCool
//
//  Where the app is running from, which decides whether fan control can work
//  at all.
//
//  SMAppService binds a daemon registration to the app's location, and
//  Gatekeeper randomises the path of an app launched in place from a download
//  or a mounted disk image. Registering from either looks like it succeeds and
//  then never works — so the app checks first and says so, rather than offering
//  a button that cannot do anything.
//

import Foundation

nonisolated enum InstallLocation: Equatable, Sendable {
    case installed
    case diskImage
    case translocated
    case elsewhere

    static func current() -> InstallLocation {
        let path = Bundle.main.bundlePath

        // Gatekeeper's randomised read-only mount for apps opened in place.
        if path.contains("/AppTranslocation/") { return .translocated }
        if path.hasPrefix("/Volumes/") { return .diskImage }
        if path.hasPrefix("/Applications/") { return .installed }
        if path.range(of: "^/Users/[^/]+/Applications/", options: .regularExpression) != nil {
            return .installed
        }
        return .elsewhere
    }

    var allowsFanControl: Bool { self == .installed }

    /// What to tell someone who just downloaded it and pressed the button.
    var advice: String? {
        switch self {
        case .installed:
            return nil
        case .diskImage:
            return "Drag SiliCool into your Applications folder first. Fan control can't be approved while it runs from the disk image."
        case .translocated:
            return "Move SiliCool into Applications and open it from there. macOS is running this copy from a temporary location, which fan control can't be approved for."
        case .elsewhere:
            return "Move SiliCool into your Applications folder. macOS ties the fan-control approval to where the app lives."
        }
    }
}
