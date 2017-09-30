//
//  ArrayExtensions.swift
//  filecrypt
//
//  Created by Koray Koska on 30.09.17.
//

import Foundation

extension Array where Element == UInt8 {

    var string: String {
        return map { String(format: "%c", $0) }.joined()
    }
}
