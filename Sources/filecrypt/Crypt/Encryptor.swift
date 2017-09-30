//
//  Encryptor.swift
//  filecrypt
//
//  Created by Koray Koska on 29.09.17.
//

import Foundation
import Cryptor

class Encryptor {

    let reader: BufferedReader
    let logger: Logger?

    init(filepath: String, logger: Logger? = nil) throws {
        self.reader = try BufferedReader(filepath: filepath)
        self.logger = logger
    }

    func crypt(withPassword password: String) throws {
        guard let pass = Digest(using: .sha256).update(string: password)?.final(), let iv = try? Random.generate(byteCount: 16) else {
            throw CryptException.Crypt.encryptionFailed(details: "SHA256 digest or random byte generation failed. Consider opening an issue on Github.")
        }
        var clearData: Data = Data()

        for d in reader {
            clearData.append(d)
        }

        var textToCipher = [UInt8](clearData)
        if textToCipher.count % Cryptor.Algorithm.aes256.blockSize != 0 {
            textToCipher = CryptoUtils.zeroPad(byteArray: textToCipher, blockSize: Cryptor.Algorithm.aes256.blockSize)
        }

        logger?.debug("Read data: \(String(data: clearData, encoding: .utf8) ?? "*No data available*")")

        guard let c = Cryptor(operation: .encrypt, algorithm: .aes256, options: .none, key: pass, iv: iv).update(byteArray: textToCipher) else {
            throw CryptException.Crypt.encryptionFailed(details: "Cryptor failed while injecting the clear data. Consider opening an issue on Github.")
        }
        guard let final = c.final() else {
            throw CryptException.Crypt.encryptionFailed(details: "Cryptor failed. Status: \(c.status.description)")
        }

        let str = final.string
        logger?.debug("IV: \(iv.string)")
        logger?.debug("Crypted data: \(str)")

        logger?.debug("Writing encrypted file...")

        let writer = try BufferedWriter(filepath: "\(reader.filepath).secured")
        // Write iv
        writer.write(data: CryptoUtils.data(from: iv))
        // Write encrypted data
        writer.write(data: CryptoUtils.data(from: final))

        // Example decrypting
        let c2 = Cryptor(operation: .decrypt, algorithm: .aes256, options: .none, key: pass, iv: iv).update(byteArray: final)?.final()
        logger?.debug("CLEAR: \(c2?.string ?? "*wut*")")
    }
}
