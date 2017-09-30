//
//  CLI.swift
//  filecrypt
//
//  Created by Koray Koska on 30.09.17.
//

import Foundation

class CLI {

    static func getPasswordWithValidation() -> (password: String, validation: String) {
        let pass = String(cString: getpass("Password: "))
        let validatedPass = String(cString: getpass("Validate Password: "))
        return (password: pass, validation: validatedPass)
    }

    static func getPassword() -> String {
        return String(cString: getpass("Password: "))
    }
}
