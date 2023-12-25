import Foundation
import ArgumentParser

@main
struct Filecrypt: ParsableCommand, Decodable {
    enum FilecryptCommand: String, Codable, ExpressibleByArgument {
        case encrypt
        case decrypt
        case cat
    }

    @Flag(help: "Turn on debug logging.")
    var verbose: Bool = false

    @Argument(help: "encrypt or decrypt to encrypt or decrypt a file. cat to decrypt and print.")
    var command: FilecryptCommand
    
    @Argument(help: "The file to encrypt/decrypt.")
    var filepath: String

    mutating func run() throws {
        print(command)
        print(filepath)
        
        let logger = Logger(level: verbose ? .debug : .warn)

        do {
            switch command {
            case .encrypt:
                var pass: String
                var validation: String
        
                (pass, validation) = CLI.getPasswordWithValidation()
                while pass != validation {
                    logger.warn("Your passwords didn't match. Please try again.")
                    (pass, validation) = CLI.getPasswordWithValidation()
                }
        
                let c = try Encryptor(filepath: filepath, logger: logger)
                try c.crypt(withPassword: pass)
            case .decrypt:
                let pass = CLI.getPassword()
        
                let c = try Decryptor(filepath: filepath, logger: logger)
                try c.crypt(withPassword: pass)
            case .cat:
                let pass = CLI.getPassword()
        
                let c = try Decryptor(filepath: filepath, logger: logger)
                try c.crypt(withPassword: pass, dry: true)
            }
        } catch {
            if let e = error as? CryptException.In {
                CryptExceptionHandler.handleIn(e, logger: logger)
            } else if let e = error as? CryptException.Out {
                CryptExceptionHandler.handleOut(e, logger: logger)
            } else if let e = error as? CryptException.Crypt {
                CryptExceptionHandler.handleCrypt(e, logger: logger)
            } else {
                logger.error("Unexpected error occurred. Consider opening an issue on Github.")
            }
        
            Filecrypt.exit(withError: error)
        }
    }
}
