//
//  main.swift
//  SiliCoolHelper
//
//  A launchd daemon that does exactly one thing: write fan keys to the SMC on
//  behalf of SiliCool, which cannot because it is not root.
//
//  It is deliberately tiny. It links Foundation and IOKit and nothing else — no
//  AppKit, no SwiftUI — because everything here runs as root, and the smaller
//  the surface the better. It launches on demand, and exits as soon as the last
//  client disconnects, so there is no idle root process sitting around.
//

import Foundation

// MARK: - The privileged work

final class FanController: NSObject, FanControlProtocol {
    private let smc = SMC()

    /// Apple silicon uses a lowercase `F0md`; Intel machines use `F0Md`.
    private func modeKey(for index: Int) -> String? {
        ["F\(index)md", "F\(index)Md"].first { (try? smc.keyInfo(for: $0)) != nil }
    }

    private func fanCount() -> Int {
        Int(smc.readNumber(key: "FNum") ?? 0)
    }

    func setTarget(rpm: Double, fanIndex: Int, withReply reply: @escaping (String?) -> Void) {
        guard fanIndex >= 0, fanIndex < fanCount() else {
            return reply("No fan at index \(fanIndex)")
        }
        // Clamp to the fan's own declared range: the app should never be able to
        // ask this daemon for a speed the hardware did not advertise.
        let minimum = smc.readNumber(key: "F\(fanIndex)Mn") ?? 0
        let maximum = smc.readNumber(key: "F\(fanIndex)Mx") ?? 0
        guard maximum > minimum else { return reply("Fan \(fanIndex) reports no usable range") }
        let target = min(max(rpm, minimum), maximum)

        do {
            if let key = modeKey(for: fanIndex) {
                try smc.write(key: key, value: 1)
            }
            try smc.write(key: "F\(fanIndex)Tg", value: target)
            reply(nil)
        } catch {
            reply(error.localizedDescription)
        }
    }

    func setAutomatic(fanIndex: Int, withReply reply: @escaping (String?) -> Void) {
        guard fanIndex >= 0, fanIndex < fanCount() else {
            return reply("No fan at index \(fanIndex)")
        }
        do {
            if let key = modeKey(for: fanIndex) {
                try smc.write(key: key, value: 0)
            }
            reply(nil)
        } catch {
            reply(error.localizedDescription)
        }
    }

    func restoreAll(withReply reply: @escaping (String?) -> Void) {
        var failure: String?
        for index in 0..<fanCount() {
            if let key = modeKey(for: index) {
                do { try smc.write(key: key, value: 0) }
                catch { failure = error.localizedDescription }
            }
        }
        reply(failure)
    }

    func version(withReply reply: @escaping (String) -> Void) {
        reply(FanControlService.helperVersion)
    }
}

// MARK: - Listener

final class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    private let controller = FanController()
    private var liveConnections = 0

    func listener(_ listener: NSXPCListener,
                  shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: FanControlProtocol.self)
        connection.exportedObject = controller

        // Only SiliCool, signed by this team, gets to drive the fans. This is a
        // static check of the peer's signature and replaces the older
        // audit-token dance.
        connection.setCodeSigningRequirement(FanControlService.codeSigningRequirement)

        liveConnections += 1
        connection.invalidationHandler = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.liveConnections -= 1
                // Nothing left to serve: stop being a root process.
                if self.liveConnections <= 0 { exit(EXIT_SUCCESS) }
            }
        }

        connection.resume()
        return true
    }
}

// MARK: - Entry point

// launchd starts this as root from /Library/LaunchDaemons. Anything else is a
// mistake or an attack; either way it should not run.
guard getuid() == 0 else {
    FileHandle.standardError.write(Data("SiliCoolHelper must be launched by launchd as root.\n".utf8))
    exit(EXIT_FAILURE)
}

let delegate = ListenerDelegate()
let listener = NSXPCListener(machServiceName: FanControlService.machServiceName)
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
