//
//  BufferedWriter.swift
//  filecrypt
//
//  Created by Koray Koska on 30.09.17.
//

import Foundation

/**
 * A buffered writer for files.
 */
class BufferedWriter {

    let filepath: String
    let chunkSize: Int
    private var fileHandle: FileHandle!

    private(set) var atEof = false

    /**
     * Initializes this `BufferedWriter` with the given filepath and optional chunkSize.
     * Fails and throws if filepath points to an existing file.
     *
     * - parameter filepath: The path to the file.
     * - parameter chunkSize: The number of bytes to write per operation. Defaults to 4096.
     *
     * - throws: `CryptException.Out.fileAlreadyExists` if the file already exists.
     *           `CryptException.Out.cannotWriteFile` if the file is not writable.
     */
    init(filepath: String, chunkSize: Int = 4096) throws {
        var isDirectory: ObjCBool = true
        guard !FileManager.default.fileExists(atPath: filepath, isDirectory: &isDirectory) else {
            throw CryptException.Out.fileAlreadyExists(path: filepath)
        }

        guard FileManager.default.createFile(atPath: filepath, contents: nil, attributes: nil) else {
            throw CryptException.Out.cannotWriteFile(path: filepath)
        }

        // Does not guarantee that our file is writable because of possible file system race conditions.
        // But it helps terminating gracefully before trying to write the file if it is indeed not writable.
        // Better for debugging...
        guard FileManager.default.isWritableFile(atPath: filepath) else {
            throw CryptException.Out.cannotWriteFile(path: filepath)
        }

        guard let fileHandle = FileHandle(forWritingAtPath: filepath) else {
            throw CryptException.Out.cannotWriteFile(path: filepath)
        }
        self.fileHandle = fileHandle

        self.filepath = filepath
        self.chunkSize = chunkSize
    }

    deinit {
        close()
    }

    /**
     * Writes the given Data chunked into the underlaying file.
     *
     * - parameter data: The data to write to the file
     */
    func write(data: Data) {
        precondition(fileHandle != nil, "Attempt to write to closed file")

        fileHandle.write(data)
    }

    /**
     * Closes the underlaying file. `write(data)` __will__ fail after calling this method.
     */
    func close() {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}
