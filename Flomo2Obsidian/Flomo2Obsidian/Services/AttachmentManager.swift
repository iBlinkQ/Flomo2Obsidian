//
//  AttachmentManager.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation

class AttachmentManager {

    func copyAttachments(from sourceDir: URL, to destDir: URL, notes: [FlomoNote]) throws -> [String: String] {
        let fileManager = FileManager.default
        let attachmentsDir = destDir.appendingPathComponent("Attachments")

        try fileManager.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)

        var mapping: [String: String] = [:]

        for note in notes {
            for imagePath in note.images {
                let sourceImageURL = sourceDir.appendingPathComponent(imagePath)
                let imageName = sourceImageURL.lastPathComponent

                if fileManager.fileExists(atPath: sourceImageURL.path) {
                    let destImageURL = attachmentsDir.appendingPathComponent(imageName)
                    let finalDestURL = handleDuplicateFilename(destImageURL, in: attachmentsDir)

                    try fileManager.copyItem(at: sourceImageURL, to: finalDestURL)
                    mapping[imagePath] = finalDestURL.lastPathComponent
                }
            }
        }

        return mapping
    }

    private func handleDuplicateFilename(_ url: URL, in directory: URL) -> URL {
        let fileManager = FileManager.default
        var finalURL = url

        if fileManager.fileExists(atPath: finalURL.path) {
            let filename = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            var counter = 1

            repeat {
                let newFilename = "\(filename)_\(counter).\(ext)"
                finalURL = directory.appendingPathComponent(newFilename)
                counter += 1
            } while fileManager.fileExists(atPath: finalURL.path)
        }

        return finalURL
    }
}
