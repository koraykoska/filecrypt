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
        case decryptionFailed(details: String)
    }
}

class CryptExceptionHandler {

    static func handleIn(_ inError: CryptException.In, logger: Logger) {
        let msg: String
        switch inError {
        case .fileDoesNotExist(let path):
            msg = "The file \(path) does not exist."
        case .cannotReadFile(let path):
            msg = "Cannot read the file \(path)."
        }

        logger.error(msg)
    }

    static func handleOut(_ out: CryptException.Out, logger: Logger) {
        let msg: String
        switch out {
        case .fileAlreadyExists(let path):
            msg = "The file \(path) already exists."
        case .cannotWriteFile(let path):
            msg = "Cannot write the file \(path)."
        }

        logger.error(msg)
    }

    static func handleCrypt(_ crypt: CryptException.Crypt, logger: Logger) {
        let msg: String
        switch crypt {
        case .encryptionFailed(let details):
            msg = "Encryption failed. Details: \(details)"
        case .decryptionFailed(let details):
            msg = "Decryption failed. Details: \(details)"
        }

        logger.error(msg)
    }
}
