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
        let pass = CryptoUtils.byteArray(from: password)
        let iv = CryptoUtils.byteArray(fromHex: "00000000000000000000000000000000")
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

        let str = final.map { String(format: "%c", $0) }.joined()
        logger?.debug("Crypted data: \(str)")
    }
}
