//
//  Decryptor.swift
//  filecrypt
//
//  Created by Koray Koska on 29.09.17.
//

import Foundation
import Cryptor

class Decryptor {

    let reader: BufferedReader
    let logger: Logger?

    init(filepath: String, logger: Logger? = nil) throws {
        self.reader = try BufferedReader(filepath: filepath)
        self.logger = logger
    }

    func crypt(withPassword password: String) throws {
        guard let pass = Digest(using: .sha256).update(string: password)?.final() else {
            throw CryptException.Crypt.decryptionFailed(details: "SHA256 digest failed. Consider opening an issue on Github.")
        }
        var encryptedData: Data = Data()

        for d in reader {
            encryptedData.append(d)
        }

        var textToUnCipher = [UInt8](encryptedData)
        var iv = [UInt8]()
        // Remove first 16 bytes and save as iv
        for _ in 0..<16 {
            if textToUnCipher.count > 0 {
                iv.append(textToUnCipher[0])
                textToUnCipher.remove(at: 0)
            }
        }

        logger?.debug("Read iv: \(iv.string)")
        logger?.debug("Read data: \(textToUnCipher.string)")

        guard let c = Cryptor(operation: .decrypt, algorithm: .aes256, options: .none, key: pass, iv: iv).update(byteArray: textToUnCipher) else {
            throw CryptException.Crypt.decryptionFailed(details: "Cryptor failed while injecting the encrypted data. Consider opening an issue on Github.")
        }
        guard let final = c.final() else {
            throw CryptException.Crypt.decryptionFailed(details: "Cryptor failed. Status: \(c.status.description)")
        }

        let str = final.string
        logger?.debug("Clear data: \(str)")
    }
}
