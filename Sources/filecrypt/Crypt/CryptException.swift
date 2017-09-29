//
//  CryptException.swift
//  filecrypt
//
//  Created by Koray Koska on 29.09.17.
//

import Foundation

struct CryptException {

    enum In: Error {

        case fileDoesNotExist(path: String)
        case cannotReadFile(path: String)
    }

    enum Out: Error {

        case fileAlreadyExists(path: String)
        case cannotWriteFile(path: String)
    }

    enum Crypt: Error {

        case encryptionFailed(details: String)
    }
}
