//
//  FileHandler.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation
import ZIPFoundation

enum FileHandlerError: LocalizedError {
    case invalidZipFile
    case extractionFailed
    case htmlFileNotFound

    var errorDescription: String? {
        switch self {
        case .invalidZipFile:
            return "Invalid Flomo export file"
        case .extractionFailed:
            return "Failed to extract zip file"
        case .htmlFileNotFound:
            return "HTML file not found in export"
        }
    }
}

class FileHandler {

    func validateZipFile(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == "zip" && FileManager.default.fileExists(atPath: url.path)
    }

    func extractZip(_ url: URL) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: url, to: tempDir)

            // Find the root folder inside the extracted zip
            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.isDirectoryKey])
            if let rootFolder = contents.first(where: { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            }) {
                return rootFolder
            }

            return tempDir
        } catch {
            throw FileHandlerError.extractionFailed
        }
    }

    func findHTMLFile(in directory: URL) -> URL? {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            return nil
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension.lowercased() == "html" {
                return fileURL
            }
        }

        return nil
    }

    func cleanup(directory: URL) {
        try? FileManager.default.removeItem(at: directory)
    }
}
