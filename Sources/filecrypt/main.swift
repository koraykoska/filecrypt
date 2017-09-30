import Foundation
import Docopt

let programName = CommandLine.arguments.first ?? "filecrypt"
let help = """
Encrypts/Decrypts a given file with a given password.

Usage:
  \(programName) (encrypt | decrypt) <filepath>
  \(programName) (-h | --help)

Examples:
  \(programName) encrypt supersecure.txt
  \(programName) decrypt supersecure.txt.encrypted

Options:
  -h, --help  Show this screen.
"""

let logger = Logger(level: .debug)

var arguments = CommandLine.arguments
if arguments.count > 0 {
    arguments.remove(at: 0)
}

let result = Docopt.parse(help, argv: arguments, help: true, version: "1.0")

let encrypt = result["encrypt"] as? Int == 1
let decrypt = result["decrypt"] as? Int == 1
let filepath = result["<filepath>"] as? String

guard let filepath = filepath, encrypt ^^ decrypt else {
    logger.fatal("Docopt failed. Consider opening an issue on Github.")
    exit(1)
}

do {
    if encrypt {
        var pass: String
        var validation: String

        (pass, validation) = CLI.getPasswordWithValidation()
        while pass != validation {
            logger.warn("Your passwords didn't match. Please try again.")
            (pass, validation) = CLI.getPasswordWithValidation()
        }

        let c = try Encryptor(filepath: filepath, logger: logger)
        try c.crypt(withPassword: pass)
    } else if decrypt {
        let pass = CLI.getPassword()

        let c = try Decryptor(filepath: filepath, logger: logger)
        try c.crypt(withPassword: pass)
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

    exit(123)
}
