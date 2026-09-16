//
//  SMC.swift
//  SiliCool
//
//  Minimal AppleSMC user-client bridge: key enumeration, typed reads and
//  privileged writes. Everything here talks to the same IOKit user client
//  that `powermetrics` and the fan-control utilities use.
//

import Foundation
import IOKit

// MARK: - Four character codes

nonisolated extension UInt32 {
    init(smcKey: String) {
        var value: UInt32 = 0
        for byte in smcKey.utf8.prefix(4) {
            value = (value << 8) | UInt32(byte)
        }
        self = value
    }

    var smcKeyString: String {
        let bytes = [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? ""
    }
}

// MARK: - Raw driver structure
//
// The driver expects an exactly 80-byte parameter block. Nested Swift structs
// get their tail padding packed away (which silently produced a 76-byte block
// and a kIOReturnBadArgument from the driver), so every field — padding
// included — is spelled out flat here.

/// 32 raw payload bytes. Modelled as a tuple so the struct keeps C layout.
typealias SMCRawBytes = (
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
    UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
)

nonisolated let smcZeroBytes: SMCRawBytes = (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
)

nonisolated struct SMCParamStruct {
    // SMCKeyData_t.key
    var key: UInt32 = 0

    // SMCKeyData_vers_t (offset 4, 6 bytes + 2 padding)
    var versionMajor: UInt8 = 0
    var versionMinor: UInt8 = 0
    var versionBuild: UInt8 = 0
    var versionReserved: UInt8 = 0
    var versionRelease: UInt16 = 0
    private var versionPadding: UInt16 = 0

    // SMCKeyData_pLimitData_t (offset 12, 16 bytes)
    var pLimitVersion: UInt16 = 0
    var pLimitLength: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0

    // SMCKeyData_keyInfo_t (offset 28, 9 bytes + 3 padding)
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
    private var keyInfoPadding0: UInt8 = 0
    private var keyInfoPadding1: UInt8 = 0
    private var keyInfoPadding2: UInt8 = 0

    // offset 40
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    private var padding: UInt8 = 0
    var data32: UInt32 = 0

    // offset 48, 32 bytes -> 80 total
    var bytes: SMCRawBytes = smcZeroBytes
}

/// What `keyInfo(for:)` hands back — size and four-char type of a key.
nonisolated struct SMCKeyInfo {
    var dataSize: UInt32
    var dataType: UInt32
}

// MARK: - Selectors

private nonisolated enum SMCSelector {
    static let handleYPCEvent: UInt32 = 2
    static let readKey: UInt8 = 5
    static let writeKey: UInt8 = 6
    static let keyFromIndex: UInt8 = 8
    static let keyInfo: UInt8 = 9
}

private nonisolated enum SMCResult {
    static let ok: UInt8 = 0
    static let keyNotFound: UInt8 = 132
}

// MARK: - Errors

nonisolated enum SMCError: LocalizedError {
    case driverUnavailable
    case keyNotFound(String)
    case notPermitted
    case ioKit(kern_return_t)
    case unsupportedType(String)

    var errorDescription: String? {
        switch self {
        case .driverUnavailable:
            return "AppleSMC is unreachable. The app cannot run inside the App Sandbox."
        case .keyNotFound(let key):
            return "This Mac does not expose the SMC key \(key)."
        case .notPermitted:
            return "Writing to the SMC requires root privileges."
        case .ioKit(let code):
            return "IOKit call failed (0x\(String(code, radix: 16)))."
        case .unsupportedType(let type):
            return "Unsupported SMC data type '\(type)'."
        }
    }
}

// MARK: - Typed value

nonisolated struct SMCValue {
    let key: String
    let type: String
    let bytes: [UInt8]

    /// Decodes the common SMC encodings into a plain Double.
    var number: Double? {
        switch type {
        case "flt ":
            guard bytes.count >= 4 else { return nil }
            let raw = UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
            return Double(Float(bitPattern: raw))
        case "ui8 ", "ui16", "ui32", "ui64":
            return bytes.reduce(0) { $0 * 256 + Double($1) }
        case "si8 ":
            guard let first = bytes.first else { return nil }
            return Double(Int8(bitPattern: first))
        case "si16":
            guard bytes.count >= 2 else { return nil }
            return Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1])))
        case "fpe2":
            guard bytes.count >= 2 else { return nil }
            return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 4.0
        case "fp88":
            guard bytes.count >= 2 else { return nil }
            return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 256.0
        case "fp1f":
            guard bytes.count >= 2 else { return nil }
            return Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 32768.0
        case "sp78":
            guard bytes.count >= 2 else { return nil }
            return Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 256.0
        case "sp96":
            guard bytes.count >= 2 else { return nil }
            return Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 64.0
        case "flag":
            return bytes.first.map { Double($0) }
        default:
            return nil
        }
    }
}

// MARK: - Service

/// Thin wrapper around the AppleSMC user client.
///
/// Enumerating the key space costs ~500 ms and a full sensor sweep ~35 ms, so
/// this never runs on the main actor — `SensorProbe` drives it from a
/// background task and hands finished snapshots back.
nonisolated final class SMC: @unchecked Sendable {
    private let lock = NSLock()
    private var connection: io_connect_t = 0
    private var keyInfoCache: [String: SMCKeyInfo] = [:]
    private var opened = false

    var isOpen: Bool { lock.withLock { opened } }

    init() {}

    deinit {
        if opened { IOServiceClose(connection) }
    }

    @discardableResult
    func open() -> Bool {
        lock.withLock {
            if opened { return true }
            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
            guard service != IO_OBJECT_NULL else { return false }
            defer { IOObjectRelease(service) }

            let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
            opened = (result == kIOReturnSuccess)
            return opened
        }
    }

    func close() {
        lock.withLock {
            guard opened else { return }
            IOServiceClose(connection)
            connection = 0
            opened = false
        }
    }

    // MARK: Core call

    private func call(_ input: inout SMCParamStruct) throws -> SMCParamStruct {
        guard isOpen || open() else { throw SMCError.driverUnavailable }
        lock.lock()
        defer { lock.unlock() }

        var output = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.stride

        let result = IOConnectCallStructMethod(
            connection,
            SMCSelector.handleYPCEvent,
            &input,
            MemoryLayout<SMCParamStruct>.stride,
            &output,
            &outputSize
        )

        switch result {
        case kIOReturnSuccess:
            break
        case kIOReturnNotPrivileged, kIOReturnNotPermitted:
            throw SMCError.notPermitted
        default:
            throw SMCError.ioKit(result)
        }

        switch output.result {
        case SMCResult.ok:
            return output
        case SMCResult.keyNotFound:
            throw SMCError.keyNotFound(input.key.smcKeyString)
        default:
            throw SMCError.ioKit(kern_return_t(output.result))
        }
    }

    // MARK: Key metadata

    func keyInfo(for key: String) throws -> SMCKeyInfo {
        if let cached = lock.withLock({ keyInfoCache[key] }) { return cached }

        var input = SMCParamStruct()
        input.key = UInt32(smcKey: key)
        input.data8 = SMCSelector.keyInfo

        let output = try call(&input)
        let info = SMCKeyInfo(dataSize: output.dataSize, dataType: output.dataType)
        lock.withLock { keyInfoCache[key] = info }
        return info
    }

    /// Every key the SMC advertises, in driver order. ~3,500 keys on Apple
    /// silicon, so this is a once-per-launch call.
    func allKeys() -> [String] {
        guard let count = (try? read(key: "#KEY"))?.number.map({ Int($0) }), count > 0 else { return [] }

        var keys: [String] = []
        keys.reserveCapacity(count)

        for index in 0..<count {
            var input = SMCParamStruct()
            input.data8 = SMCSelector.keyFromIndex
            input.data32 = UInt32(index)
            guard let output = try? call(&input) else { continue }
            keys.append(output.key.smcKeyString)
        }
        return keys
    }

    // MARK: Read / write

    func read(key: String) throws -> SMCValue {
        let info = try keyInfo(for: key)

        var input = SMCParamStruct()
        input.key = UInt32(smcKey: key)
        input.dataSize = info.dataSize
        input.data8 = SMCSelector.readKey

        let output = try call(&input)
        let size = Int(info.dataSize)

        var payload = output.bytes
        let bytes: [UInt8] = withUnsafeBytes(of: &payload) { raw in
            Array(raw.prefix(min(size, 32)))
        }

        return SMCValue(key: key, type: info.dataType.smcKeyString, bytes: bytes)
    }

    func readNumber(key: String) -> Double? {
        (try? read(key: key))?.number
    }

    func write(key: String, bytes payload: [UInt8]) throws {
        let info = try keyInfo(for: key)

        var input = SMCParamStruct()
        input.key = UInt32(smcKey: key)
        input.dataSize = info.dataSize
        input.data8 = SMCSelector.writeKey

        withUnsafeMutableBytes(of: &input.bytes) { raw in
            for (offset, byte) in payload.prefix(min(Int(info.dataSize), 32)).enumerated() {
                raw[offset] = byte
            }
        }

        _ = try call(&input)
    }

    /// Encodes `value` using the key's declared type, then writes it.
    func write(key: String, value: Double) throws {
        let info = try keyInfo(for: key)
        let type = info.dataType.smcKeyString

        switch type {
        case "flt ":
            let raw = Float(value).bitPattern
            try write(key: key, bytes: [
                UInt8(raw & 0xFF),
                UInt8((raw >> 8) & 0xFF),
                UInt8((raw >> 16) & 0xFF),
                UInt8((raw >> 24) & 0xFF)
            ])
        case "fpe2":
            let raw = UInt16(max(0, min(65535, value * 4)))
            try write(key: key, bytes: [UInt8(raw >> 8), UInt8(raw & 0xFF)])
        case "ui8 ", "flag":
            try write(key: key, bytes: [UInt8(max(0, min(255, value)))])
        case "ui16":
            let raw = UInt16(max(0, min(65535, value)))
            try write(key: key, bytes: [UInt8(raw >> 8), UInt8(raw & 0xFF)])
        case "ui32":
            let raw = UInt32(max(0, min(4294967295, value)))
            try write(key: key, bytes: [
                UInt8((raw >> 24) & 0xFF),
                UInt8((raw >> 16) & 0xFF),
                UInt8((raw >> 8) & 0xFF),
                UInt8(raw & 0xFF)
            ])
        default:
            throw SMCError.unsupportedType(type)
        }
    }
}
