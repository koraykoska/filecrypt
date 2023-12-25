//
//  Decryptor.swift
//  filecrypt
//
//  Created by Koray Koska on 29.09.17.
//

import Foundation
import Cryptor
import CryptoSwift

class Decryptor {

    let reader: BufferedReader
    let logger: Logger?

    init(filepath: String, logger: Logger? = nil) throws {
        self.reader = try BufferedReader(filepath: filepath)
        self.logger = logger
    }

    func crypt(withPassword password: String, dry: Bool = false) throws {
        logger?.debug("Reading encrypted data...")

        var encryptedData: Data = Data()
        for d in reader {
            encryptedData.append(d)
        }
        let textToUnCipher = [UInt8](encryptedData)

        let finalData: [UInt8]
        if let jsonKeyfile = try? JSONDecoder().decode(Keyfile.self, from: Data(textToUnCipher)) {
            finalData = try newCrypt(withPassword: password, jsonKeyfile: jsonKeyfile)
        } else {
            finalData = try backwardsCrypt(withPassword: password, encryptedData: textToUnCipher)
        }

        if !dry {
            var decryptedPath = "\(reader.filepath).cleartext"
            var decryptedPathComponents = reader.filepath.components(separatedBy: ".")
            if decryptedPathComponents.count > 1 && reader.filepath.hasSuffix(".secured") {
                decryptedPathComponents.removeLast()
                decryptedPath = decryptedPathComponents.joined(separator: ".")
            }
            logger?.debug("Writing decrypted data to \(decryptedPath)...")

            let writer = try BufferedWriter(filepath: decryptedPath)
            // Write decrypted data
            writer.write(data: CryptoUtils.data(from: finalData))
        } else {
            // TODO: Print should be done in main.swift.
            let data = String(data: CryptoUtils.data(from: finalData), encoding: .utf8)
            print()
            print("-------- Decrypted Data --------")
            print(data ?? "*No data*")
        }
    }

    private func newCrypt(withPassword password: String, jsonKeyfile keyfile: Keyfile) throws -> [UInt8] {
        logger?.debug("Hashing password...")

        guard keyfile.kdfType == .scrypt else {
            throw CryptException.Crypt.decryptionFailed(details: "Given KDF not supported.")
        }

        let salt = [UInt8](hex: keyfile.scryptParams.salt)
        let dkLen = keyfile.scryptParams.dkLen
        let scryptN = keyfile.scryptParams.N
        let scryptR = keyfile.scryptParams.r
        let scryptP = keyfile.scryptParams.p
        let pass: [UInt8]
        do {
            pass = try Scrypt(password: password.bytes, salt: salt, dkLen: dkLen, N: scryptN, r: scryptR, p: scryptP).calculate()
        } catch {
            throw CryptException.Crypt.encryptionFailed(details: "Scrypt digest failed. Consider trying again or opening an issue on Github. Error: \(error)")
        }

        logger?.debug("Decrypting...")

        guard keyfile.encryptionType == .aes_256 else {
            throw CryptException.Crypt.decryptionFailed(details: "Given encryption type not supported.")
        }
        guard keyfile.aesParams.paddingType == .pkcs7 else {
            throw CryptException.Crypt.decryptionFailed(details: "Given AES padding type not supported.")
        }
        let iv = [UInt8](hex: keyfile.aesParams.iv)
        let aes = try AES(key: pass, blockMode: CBC(iv: iv), padding: .pkcs7)

        let encryptedBytes = [UInt8](hex: keyfile.encryptedMessage)
        let decryptedBytes = try aes.decrypt(encryptedBytes)

        logger?.debug("Generating HMAC signature...")

        guard keyfile.hmacVariant == .sha3_keccak256 else {
            throw CryptException.Crypt.decryptionFailed(details: "Given hmac variant not supported.")
        }
        guard let hmacClear = try? CryptoSwift.HMAC(key: pass, variant: .sha3(.keccak256)).authenticate(decryptedBytes) else {
            throw CryptException.Crypt.decryptionFailed(details: "HMAC signature generation failed...")
        }

        logger?.debug("Checking HMAC signature...")

        let hmac = [UInt8](hex: keyfile.hmac)
        guard hmac.elementsEqual(hmacClear) else {
            throw CryptException.Crypt.decryptionFailed(details: "Signature verification failed. It looks like your password is incorrect. Please re-check it.")
        }

        return decryptedBytes
    }

    private func backwardsCrypt(withPassword password: String, encryptedData: [UInt8]) throws -> [UInt8] {
        var textToUnCipher = encryptedData

        logger?.debug("Hashing password...")

        guard let pass = Digest(using: .sha256).update(string: password)?.final() else {
            throw CryptException.Crypt.decryptionFailed(details: "SHA256 digest failed. Consider opening an issue on Github.")
        }

        logger?.debug("Extracting iv...")

        var iv = [UInt8]()
        // Remove first 16 bytes and save as iv
        for _ in 0..<16 {
            if textToUnCipher.count > 0 {
                iv.append(textToUnCipher[0])
                textToUnCipher.remove(at: 0)
            }
        }

        logger?.debug("Extracting hmac signature...")

        var hmac = [UInt8]()
        // Remove first 32 bytes and save as hmac
        for _ in 0..<32 {
            if textToUnCipher.count > 0 {
                hmac.append(textToUnCipher[0])
                textToUnCipher.remove(at: 0)
            }
        }

        logger?.debug("Decrypting...")

        guard let c = try Cryptor(operation: .decrypt, algorithm: .aes256, options: .none, key: pass, iv: iv).update(byteArray: textToUnCipher) else {
            throw CryptException.Crypt.decryptionFailed(details: "Cryptor failed while injecting the encrypted data. Consider opening an issue on Github.")
        }
        guard let finalData = c.final() else {
            throw CryptException.Crypt.decryptionFailed(details: "Cryptor failed. Status: \(c.status.description)")
        }

        logger?.debug("Generating HMAC signature...")

        guard let hmacClear = HMAC(using: .sha256, key: pass).update(byteArray: finalData)?.final() else {
            throw CryptException.Crypt.decryptionFailed(details: "HMAC signature generation failed...")
        }

        logger?.debug("Checking HMAC signature...")

        guard hmac.elementsEqual(hmacClear) else {
            throw CryptException.Crypt.decryptionFailed(details: "Signature verification failed. It looks like your password is incorrect. Please re-check it.")
        }

        return finalData
    }
}
