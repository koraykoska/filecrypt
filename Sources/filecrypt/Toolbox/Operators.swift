//
//  Operators.swift
//  filecrypt
//
//  Created by Koray Koska on 28.09.17.
//

import Foundation

// MARK: - Logical XOR

precedencegroup BooleanPrecedence { associativity: left }
infix operator ^^: BooleanPrecedence

/**
 Swift Logical XOR operator
 ```
 true  ^^ true   // false
 true  ^^ false  // true
 false ^^ true   // true
 false ^^ false  // false
 ```
 - parameter lhs: First value.
 - parameter rhs: Second value.
 */
func ^^(lhs: Bool, rhs: Bool) -> Bool {
    return lhs != rhs
}

// MARK: - Color specific

func +(lhs: ANSIColor, rhs: String) -> String {
    return "\(lhs.rawValue)\(rhs)"
}

func +(lhs: String, rhs: ANSIColor) -> String {
    return "\(lhs)\(rhs.rawValue)"
}

// MARK: - Logger.Level operators

extension Logger.Level: Comparable {}

func <(lhs: Logger.Level, rhs: Logger.Level) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func ==(lhs: Logger.Level, rhs: Logger.Level) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
