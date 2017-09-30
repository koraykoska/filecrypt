//
//  BufferedReader.swift
//  filecrypt
//
//  Created by Koray Koska on 29.09.17.
//

import Foundation

/**
 * A buffered reader for files.
 */
class BufferedReader {

    let filepath: String
    let chunkSize: Int
    private var fileHandle: FileHandle!

    private(set) var atEof = false

    /**
     * Initializes this `BufferedReader` with the given filepath and optional chunkSize.
     * Fails and throws if filepath is not a file or not readable (or does not exist).
     *
     * - parameter filepath: The path to the file.
     * - parameter chunkSize: The number of bytes to read in each `read()` call. Defaults to 4096.
     *
     * - throws: `CryptException.In.fileDoesNotExist` if the file does not exists or is not a file.
     *           `CryptException.In.cannotReadFile` if the file is not readable.
     */
    init(filepath: String, chunkSize: Int = 4096) throws {
        var isDirectory: ObjCBool = true
        guard FileManager.default.fileExists(atPath: filepath, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw CryptException.In.fileDoesNotExist(path: filepath)
        }
        // Does not guarantee that our file is readable because of possible file system race conditions.
        // But it helps terminating gracefully before trying to read the file if it is indeed not readable.
        // Better for debugging...
        guard FileManager.default.isReadableFile(atPath: filepath) else {
            throw CryptException.In.cannotReadFile(path: filepath)
        }

        guard let fileHandle = FileHandle(forReadingAtPath: filepath) else {
            throw CryptException.In.cannotReadFile(path: filepath)
        }
        self.fileHandle = fileHandle

        self.filepath = filepath
        self.chunkSize = chunkSize
    }

    deinit {
        close()
    }

    /**
     * Reads and returns the next `chunkSize` bytes from the underlaying file.
     *
     * - returns: The next `chunkSize` Bytes as Data or `nil` if EOF was already reached.
     */
    func read() -> Data? {
        precondition(fileHandle != nil, "Attempt to read from closed file")

        if !atEof {
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count > 0 {
                return tmpData
            } else {
                // EOF reached
                atEof = true
            }
        }
        return nil
    }

    /**
     * Rewinds the file to the beginning.
     */
    func rewind() {
        fileHandle.seek(toFileOffset: 0)
        atEof = false
    }

    /**
     * Closes the underlaying file. `read()` __will__ fail after calling this method.
     */
    func close() {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}

/**
 * Iterator for BufferedReader.
 */
extension BufferedReader: Sequence {

    func makeIterator() -> BufferedReader.Iterator {
        return BufferedReader.Iterator(self)
    }

    struct Iterator: IteratorProtocol {

        let reader: BufferedReader

        init(_ reader: BufferedReader) {
            self.reader = reader
        }

        mutating func next() -> Data? {
            return reader.read()
        }
    }
}
