import Foundation

let programName = CommandLine.arguments.first ?? "filecrypt"
let help = """
Encrypts/Decrypts a given file with a given password.

Usage:
  \(programName) (encrypt | decrypt | cat) <filepath>
  \(programName) (-h | --help)

Examples:
  \(programName) encrypt supersecure.txt
  \(programName) decrypt supersecure.txt.encrypted
  \(programName) cat supersecure.txt.encrypted

Options:
  -h, --help  Show this screen.
"""

let logger = Logger(level: .warn)

var arguments = CommandLine.arguments
if arguments.count > 0 {
    arguments.remove(at: 0)
}

if arguments.contains("-h") || arguments.contains("--help") {
    print(help)
    exit(0)
}

guard arguments.count == 2 else {
    print(help)
    exit(1)
}

guard let command = TopLevelCommand(rawValue: arguments[0]) else {
    print(help)
    exit(1)
}
let filepath = arguments[1]

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

    exit(123)
}
