//
//  FanControlProtocol.swift
//  SiliCool — shared by the app and the privileged helper
//
//  The entire privileged surface of this app. Reads need no privileges and stay
//  in the app; only these four calls cross into root.
//

import Foundation

/// Every reply carries an optional error string rather than throwing: XPC
/// replies cannot throw, and the app has nothing useful to do with a typed
/// error beyond showing it.
@objc public nonisolated protocol FanControlProtocol {
    func setTarget(rpm: Double, fanIndex: Int, withReply reply: @escaping (String?) -> Void)
    func setAutomatic(fanIndex: Int, withReply reply: @escaping (String?) -> Void)
    func restoreAll(withReply reply: @escaping (String?) -> Void)
    func version(withReply reply: @escaping (String) -> Void)
}

public nonisolated enum FanControlService {
    /// Must match the `Label` and the `MachServices` key in
    /// Helper/Nikunj.SiliCool.Helper.plist.
    public static let machServiceName = "Nikunj.SiliCool.Helper"

    /// Passed to `SMAppService.daemon(plistName:)`. The `.plist` extension is
    /// part of the name — omitting it is the classic "Error 108, unable to read
    /// plist" failure, because this is not the bare label SMJobBless took.
    public static let plistName = "Nikunj.SiliCool.Helper.plist"

    public static let helperVersion = "1"

    /// Each side requires this of the other before it will exchange a message.
    ///
    /// Pinned to the team, and to an Apple-issued leaf that is either a
    /// Developer ID Application or an Apple Development certificate. OIDs are
    /// from Apple's TN3127.
    ///
    /// Both leaf types are accepted because SiliCool currently ships signed
    /// with Apple Development — a Developer ID certificate needs the paid
    /// developer program. The team pin is what actually matters: only binaries
    /// signed by this team are accepted either way. Ad-hoc signing cannot work
    /// here at all, because an ad-hoc signature carries no team identifier for
    /// this requirement to match.
    ///
    /// TODO: once a Developer ID certificate exists, drop the
    /// `…6.1.12` (Apple Development) and `…6.2.1` (WWDR CA) alternatives so a
    /// shipped build will only ever talk to a Developer ID signed daemon.
    ///
    /// Must be passed to `setCodeSigningRequirement` exactly once, before
    /// `resume()`, and must be a literal: a malformed requirement is an
    /// unconditional fatal error in Swift, not a thrown error.
    public static let codeSigningRequirement = """
        anchor apple generic \
        and certificate leaf[subject.OU] = "72B76SWRDS" \
        and (certificate leaf[field.1.2.840.113635.100.6.1.13] \
        or certificate leaf[field.1.2.840.113635.100.6.1.12]) \
        and (certificate 1[field.1.2.840.113635.100.6.2.6] \
        or certificate 1[field.1.2.840.113635.100.6.2.1])
        """
}
