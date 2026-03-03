//
//  ZipGenerator.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation
import ZIPFoundation

class ZipGenerator {

    func createZip(exportItems: [ExportItem], markdownContents: [String: String], attachmentsDir: URL?) throws -> URL {
        let tempDir = createTempDirectory()

        try writeExportItemFiles(exportItems, contents: markdownContents, to: tempDir)

        if let attachmentsDir = attachmentsDir {
            try copyAttachmentsDirectory(from: attachmentsDir, to: tempDir)
        }

        let zipURL = try zipDirectory(tempDir)

        return zipURL
    }

    private func createTempDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func writeExportItemFiles(_ items: [ExportItem], contents: [String: String], to directory: URL) throws {
        for item in items {
            let fileURL = directory.appendingPathComponent(item.filename)
            if let content = contents[item.contentKey] {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }

    private func copyAttachmentsDirectory(from source: URL, to destination: URL) throws {
        let destAttachments = destination.appendingPathComponent("Attachments")
        try FileManager.default.copyItem(at: source, to: destAttachments)
    }

    private func zipDirectory(_ directory: URL) throws -> URL {
        let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("obsidian-notes.zip")

        try? FileManager.default.removeItem(at: zipURL)

        try FileManager.default.zipItem(at: directory, to: zipURL)

        return zipURL
    }
}
