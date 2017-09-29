//
//  Logger.swift
//  filecrypt
//
//  Created by Koray Koska on 28.09.17.
//

import Foundation

class Logger {

    enum Level: Int {

        case debug = 0
        case info = 1
        case warn = 2
        case error = 3
        case fatal = 4

        func prefix(formatter: DateFormatter = DateFormatter.loggerDefault) -> String {
            let date = formatter.string(from: Date())
            let pre: String
            switch self {
            case .debug:
                pre = ANSIColor.blue + "[DEBUG] " + ANSIColor.reset
            case .info:
                pre = ANSIColor.white + "[INFO] " + ANSIColor.reset
            case .warn:
                pre = ANSIColor.yellow + "[WARN] " + ANSIColor.reset
            case .error:
                pre = ANSIColor.red + "[ERROR] " + ANSIColor.reset
            case .fatal:
                pre = ANSIColor.magenta + "[FATAL] " + ANSIColor.reset
            }

            return pre + date + ": "
        }
    }

    private let formatter: DateFormatter
    var level: Logger.Level

    init(level : Logger.Level) {
        self.level = level
        self.formatter = DateFormatter.loggerDefault
    }

    func log(level: Logger.Level, message: String) {
        if level >= self.level {
            print(level.prefix(formatter: formatter) + message)
        }
    }

    func debug(_ msg: String) {
        log(level: .debug, message: msg)
    }

    func info(_ msg: String) {
        log(level: .info, message: msg)
    }

    func warn(_ msg: String) {
        log(level: .warn, message: msg)
    }

    func error(_ msg: String) {
        log(level: .error, message: msg)
    }

    func fatal(_ msg: String) {
        log(level: .fatal, message: msg)
    }
}

extension DateFormatter {

    static var loggerDefault: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "[MM-dd|HH:mm:ss]"

        return formatter
    }
}

enum ANSIColor: String {

    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"

    case reset = "\u{001B}[0m"

    func queued(_ str: String) -> String {
        return "\(rawValue)\(str)"
    }

    func stacked(_ str: String) -> String {
        return "\(str)\(rawValue)"
    }
}

extension String {

    func color(_ clr: ANSIColor) -> String {
        return clr + self
    }
}
