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

if encrypt {
    let c = try Encryptor(filepath: filepath, logger: logger)
    try c.crypt(withPassword: "abc")
} else if decrypt {
    let c = try Decryptor(filepath: filepath, logger: logger)
    try c.crypt(withPassword: "abc")
}
