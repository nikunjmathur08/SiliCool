//
//  PrivilegedFanControl.swift
//  SiliCool
//
//  Talks to the root daemon so the app itself never needs to be root.
//
//  Reading sensors needs no privileges and is done directly by the app; only
//  fan writes come through here. The daemon is registered with SMAppService,
//  which asks the user to approve it once in System Settings — after that a
//  normal double-click of SiliCool can drive the fans.
//

import Foundation
import ServiceManagement

nonisolated final class PrivilegedFanControl: @unchecked Sendable {

    enum Status: Equatable {
        case notInstalled
        /// Registered, but waiting for the user to switch it on in
        /// System Settings › General › Login Items & Extensions. A normal
        /// resting state, not an error.
        case requiresApproval
        case ready
        case failed(String)

        var isReady: Bool { self == .ready }
    }

    private let lock = NSLock()
    private var connection: NSXPCConnection?

    private var service: SMAppService {
        SMAppService.daemon(plistName: FanControlService.plistName)
    }

    // MARK: Status

    var status: Status {
        switch service.status {
        case .enabled: return .ready
        case .requiresApproval: return .requiresApproval
        case .notRegistered, .notFound: return .notInstalled
        @unknown default: return .notInstalled
        }
    }

    // MARK: Install / remove

    /// Registers the daemon. The first time, this needs the user to approve it
    /// in System Settings, so this opens that pane for them.
    @discardableResult
    func install() -> Status {
        if status == .ready { return .ready }

        do {
            try service.register()
        } catch {
            // A stale Background Task Management record is the common cause;
            // unregistering and retrying once clears it.
            try? service.unregister()
            do {
                try service.register()
            } catch {
                if service.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                    return .requiresApproval
                }
                return .failed(error.localizedDescription)
            }
        }

        let result = status
        if result == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        return result
    }

    func openApprovalSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    /// Hands the fans back before tearing the daemon down — a pinned fan stays
    /// pinned once nothing is left to un-pin it.
    func remove() {
        restoreAllSynchronously()
        invalidate()
        try? service.unregister()
    }

    // MARK: Connection

    private func proxy(onFailure: @escaping (String) -> Void) -> FanControlProtocol? {
        lock.lock()
        defer { lock.unlock() }

        if connection == nil {
            let new = NSXPCConnection(machServiceName: FanControlService.machServiceName,
                                      options: .privileged)
            new.remoteObjectInterface = NSXPCInterface(with: FanControlProtocol.self)
            // Refuse to talk to anything that is not our own signed daemon.
            // Must be set exactly once, before resume().
            new.setCodeSigningRequirement(FanControlService.codeSigningRequirement)
            new.invalidationHandler = { [weak self] in self?.clearConnection() }
            new.interruptionHandler = { [weak self] in self?.clearConnection() }
            new.resume()
            connection = new
        }

        return connection?.remoteObjectProxyWithErrorHandler { error in
            onFailure(error.localizedDescription)
        } as? FanControlProtocol
    }

    private func clearConnection() {
        lock.lock()
        connection = nil
        lock.unlock()
    }

    private func invalidate() {
        lock.lock()
        connection?.invalidate()
        connection = nil
        lock.unlock()
    }

    // MARK: Calls

    func setTarget(rpm: Double, fanIndex: Int, completion: @escaping (String?) -> Void) {
        guard let proxy = proxy(onFailure: { completion($0) }) else {
            return completion("Fan control helper is not reachable")
        }
        proxy.setTarget(rpm: rpm, fanIndex: fanIndex, withReply: completion)
    }

    func setAutomatic(fanIndex: Int, completion: @escaping (String?) -> Void) {
        guard let proxy = proxy(onFailure: { completion($0) }) else {
            return completion("Fan control helper is not reachable")
        }
        proxy.setAutomatic(fanIndex: fanIndex, withReply: completion)
    }

    /// Blocking, on purpose: this runs on the way out — from a signal handler
    /// or `atexit` — where there is no later turn of the run loop in which an
    /// async reply could arrive.
    func restoreAllSynchronously() {
        guard status.isReady else { return }

        lock.lock()
        let existing = connection
        lock.unlock()

        let target: NSXPCConnection
        if let existing {
            target = existing
        } else {
            let new = NSXPCConnection(machServiceName: FanControlService.machServiceName,
                                      options: .privileged)
            new.remoteObjectInterface = NSXPCInterface(with: FanControlProtocol.self)
            new.setCodeSigningRequirement(FanControlService.codeSigningRequirement)
            new.resume()
            lock.lock()
            connection = new
            lock.unlock()
            target = new
        }

        let proxy = target.synchronousRemoteObjectProxyWithErrorHandler { _ in }
        (proxy as? FanControlProtocol)?.restoreAll { _ in }
    }
}
