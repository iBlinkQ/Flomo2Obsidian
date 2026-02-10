//
//  AppState.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

class AppState: ObservableObject {
    @Published var currentScreen: Screen = .welcome
    @Published var selectedFile: URL?
    @Published var flomoNotes: [FlomoNote] = []
    @Published var dailyNotes: [DailyNote] = []
    @Published var markdownContents: [String: String] = [:]
    @Published var dateRange: (start: Date, end: Date)?
    @Published var isProcessing = false
    @Published var error: String?
    @Published var currentProgress: Int = 0
    @Published var showingExporter = false
    @Published var exportURL: URL?

    private let fileHandler = FileHandler()
    private let htmlParser = HTMLParser()
    private let markdownConverter = MarkdownConverter()
    private let attachmentManager = AttachmentManager()
    private let zipGenerator = ZipGenerator()

    private var extractedDir: URL?

    enum Screen {
        case welcome
        case dateRange
        case converting
        case preview
    }

    func processFile() {
        guard let fileURL = selectedFile else { return }

        Task {
            isProcessing = true
            error = nil

            do {
                // Extract zip
                extractedDir = try fileHandler.extractZip(fileURL)

                // Find HTML file
                guard let htmlURL = fileHandler.findHTMLFile(in: extractedDir!) else {
                    throw FileHandlerError.htmlFileNotFound
                }

                // Parse HTML
                let htmlContent = try String(contentsOf: htmlURL, encoding: .utf8)
                flomoNotes = try htmlParser.parseHTML(htmlContent)

                // Determine date range
                if let earliest = flomoNotes.first?.timestamp,
                   let latest = flomoNotes.last?.timestamp {
                    dateRange = (earliest, latest)
                }

                isProcessing = false
                currentScreen = .dateRange
            } catch {
                self.error = error.localizedDescription
                isProcessing = false
            }
        }
    }

    func convertNotes(startDate: Date, endDate: Date) {
        Task {
            isProcessing = true
            currentScreen = .converting
            error = nil

            do {
                // Filter notes by date range
                let filteredNotes = flomoNotes.filter { note in
                    note.timestamp >= startDate && note.timestamp <= endDate
                }

                currentProgress = 0

                // Convert to daily notes
                dailyNotes = markdownConverter.convertToDailyNotes(filteredNotes)

                // Generate markdown for each daily note
                for (index, dailyNote) in dailyNotes.enumerated() {
                    let markdown = markdownConverter.generateMarkdown(for: dailyNote)
                    markdownContents[dailyNote.dateString] = markdown
                    currentProgress = index + 1
                }

                isProcessing = false
                currentScreen = .preview
            } catch {
                self.error = error.localizedDescription
                isProcessing = false
            }
        }
    }

    func exportZip() {
        isProcessing = true
        error = nil

        // Do background work
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                guard let extractedDir = self.extractedDir else {
                    throw FileHandlerError.extractionFailed
                }

                // Copy attachments
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                let _ = try self.attachmentManager.copyAttachments(
                    from: extractedDir,
                    to: tempDir,
                    notes: self.flomoNotes
                )

                let attachmentsDir = tempDir.appendingPathComponent("Attachments")

                // Create zip
                let zipURL = try self.zipGenerator.createZip(
                    dailyNotes: self.dailyNotes,
                    markdownContents: self.markdownContents,
                    attachmentsDir: attachmentsDir
                )

                // Update UI on main thread
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.exportURL = zipURL

                    // Add small delay before showing exporter
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.showingExporter = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }

    func reset() {
        currentScreen = .welcome
        selectedFile = nil
        flomoNotes = []
        dailyNotes = []
        markdownContents = [:]
        dateRange = nil
        currentProgress = 0

        if let extractedDir = extractedDir {
            fileHandler.cleanup(directory: extractedDir)
            self.extractedDir = nil
        }
    }
}
