//
//  Diagnostics.swift
//  SiliCool
//
//  A small amount of logging on the paths that hand fan control back, so a
//  report of "it didn't let go" can be answered with evidence instead of a
//  guess:
//
//      log stream --predicate 'subsystem == "Nikunj.SiliCool"' --info
//
//  Nothing here records anything about the machine beyond fan state.
//

import os

nonisolated enum Diagnostics {
    static let fans = Logger(subsystem: "Nikunj.SiliCool", category: "fans")
}
