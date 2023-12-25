//
//  Encryptor.swift
//  filecrypt
//
//  Created by Koray Koska on 29.09.17.
//

import Foundation
import CryptoSwift

class Encryptor {

    let reader: BufferedReader
    let logger: Logger?

    init(filepath: String, logger: Logger? = nil) throws {
        self.reader = try BufferedReader(filepath: filepath)
        self.logger = logger
    }

    func crypt(withPassword password: String) throws {
        logger?.debug("Generating password hash and secure random iv...")
        
        var saltPointer = Data(count: 16)
        let saltGenerationResult = try? saltPointer.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> OSStatus in
            guard let base = pointer.baseAddress else {
                throw CryptException.Crypt.encryptionFailed(details: "")
            }
            return SecRandomCopyBytes(kSecRandomDefault, 16, base)
        }
        guard let saltGenerationResult, saltGenerationResult == errSecSuccess else {
            throw CryptException.Crypt.encryptionFailed(details: "Random salt generation failed. Consider trying again or opening an issue on Github.")
        }

        let scryptDklen = 32
        let scryptN: Int = Int(pow(Float(2), Float(20)))
        let scryptR = 8
        let scryptP = 1
        let pass: [UInt8]
        do {
            pass = try Scrypt(password: password.bytes, salt: saltPointer.bytes, dkLen: scryptDklen, N: scryptN, r: scryptR, p: scryptP).calculate()
        } catch {
            throw CryptException.Crypt.encryptionFailed(details: "Scrypt digest failed. Consider trying again or opening an issue on Github. Error: \(error)")
        }

        var ivPointer = Data(count: AES.blockSize)
        let ivGenerationResult = try? ivPointer.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> OSStatus in
            guard let base = pointer.baseAddress else {
                throw CryptException.Crypt.encryptionFailed(details: "")
            }
            return SecRandomCopyBytes(kSecRandomDefault, AES.blockSize, base)
        }
        if ivGenerationResult != errSecSuccess {
            throw CryptException.Crypt.encryptionFailed(details: "Random iv generation failed. Consider trying again or opening an issue on Github.")
        }

        var clearData: Data = Data()

        logger?.debug("Reading cleartext data...")

        for d in reader {
            clearData.append(d)
        }

        logger?.debug("Encrypting...")

        let aes = try AES(key: pass, blockMode: CBC(iv: ivPointer.bytes), padding: .pkcs7)

        let encryptedBytes = try aes.encrypt(clearData.bytes)

        logger?.debug("Generating HMAC signature...")

        let hmac = try CryptoSwift.HMAC(key: pass, variant: .sha3(.keccak256)).authenticate(clearData.bytes)

        let encryptedPath = "\(reader.filepath).secured"

        logger?.debug("Writing encrypted data to \(encryptedPath)...")

        let keyfile = Keyfile(
            kdfType: .scrypt,
            scryptParams: .init(
                salt: "0x\(saltPointer.toHexString())",
                dkLen: scryptDklen,
                N: scryptN,
                r: scryptR,
                p: scryptP
            ),
            hmac: "0x\(hmac.toHexString())",
            hmacVariant: .sha3_keccak256,
            encryptionType: .aes_256,
            aesParams: .init(iv: "0x\(ivPointer.toHexString())", paddingType: .pkcs7),
            encryptedMessage: "0x\(encryptedBytes.toHexString())"
        )

        let writer = try BufferedWriter(filepath: encryptedPath)
        // Write keyfile
        try writer.write(data: JSONEncoder().encode(keyfile))
    }
}
