import Foundation

/// All byte values are required to be hex encoded. Even if they are string representible.
struct Keyfile: Codable {
    enum KDFType: String, Codable {
        case scrypt
    }

    struct ScryptParams: Codable {
        let salt: String
        let dkLen: Int
        let N: Int
        let r: Int
        let p: Int
    }

    enum HMACVariant: String, Codable {
        case sha3_keccak256
    }

    enum EncryptionType: String, Codable {
        case aes_256
    }

    struct AESParams: Codable {
        enum PaddingType: String, Codable {
            case pkcs7
        }

        let iv: String
        let paddingType: PaddingType
    }

    let kdfType: KDFType
    let scryptParams: ScryptParams

    let hmac: String
    let hmacVariant: HMACVariant

    let encryptionType: EncryptionType
    let aesParams: AESParams
    let encryptedMessage: String
}
