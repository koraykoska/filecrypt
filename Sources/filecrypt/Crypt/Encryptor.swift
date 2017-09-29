//
//  Encryptor.swift
//  filecrypt
//
//  Created by Koray Koska on 29.09.17.
//

import Foundation
import Cryptor

class Encryptor {

    let filepath: String
    // let file: FILE

    init(filepath: String) throws {
        self.filepath = filepath
        var isDirectory: ObjCBool = true
        guard FileManager.default.fileExists(atPath: filepath, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw CryptException.In.fileDoesNotExist(path: filepath)
        }
        // Does not guarantee that our file is readable because of possible file system race conditions.
        // But it helps terminating gracefully before trying to read the file if it is indeed not readable.
        // Better for debugging...
        guard FileManager.default.isReadableFile(atPath: filepath) else {
            throw CryptException.In.cannotReadFile(path: filepath)
        }
    }

    func crypt() {
    }
}
