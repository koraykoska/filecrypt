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

        logger?.debug("Reading encrypted data...")

        for d in reader {
            encryptedData.append(d)
        }

        logger?.debug("Extracting iv...")

        var textToUnCipher = [UInt8](encryptedData)
        var iv = [UInt8]()
        // Remove first 16 bytes and save as iv
        for _ in 0..<16 {
            if textToUnCipher.count > 0 {
                iv.append(textToUnCipher[0])
                textToUnCipher.remove(at: 0)
            }
        }

        logger?.debug("Decrypting...")

        guard let c = Cryptor(operation: .decrypt, algorithm: .aes256, options: .none, key: pass, iv: iv).update(byteArray: textToUnCipher) else {
            throw CryptException.Crypt.decryptionFailed(details: "Cryptor failed while injecting the encrypted data. Consider opening an issue on Github.")
        }
        guard let final = c.final() else {
            throw CryptException.Crypt.decryptionFailed(details: "Cryptor failed. Status: \(c.status.description)")
        }

        var decryptedPath = "\(reader.filepath).cleartext"
        var decryptedPathComponents = reader.filepath.components(separatedBy: ".")
        if decryptedPathComponents.count > 1 && reader.filepath.hasSuffix(".secured") {
            decryptedPathComponents.removeLast()
            decryptedPath = decryptedPathComponents.joined(separator: ".")
        }
        logger?.debug("Writing decrypted data to \(decryptedPath)...")

        let writer = try BufferedWriter(filepath: decryptedPath)
        // Write decrypted data
        writer.write(data: CryptoUtils.data(from: final))
    }
}
