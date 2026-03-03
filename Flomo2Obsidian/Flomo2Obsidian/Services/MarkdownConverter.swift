//
//  MarkdownConverter.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation

class MarkdownConverter {

    // MARK: - Per-Day Mode (existing)

    func convertToDailyNotes(_ notes: [FlomoNote]) -> [DailyNote] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notes) { note in
            calendar.startOfDay(for: note.timestamp)
        }

        return grouped.map { date, notes in
            DailyNote(date: date, notes: notes.sorted { $0.timestamp < $1.timestamp })
        }.sorted { $0.date < $1.date }
    }

    func generateMarkdown(for dailyNote: DailyNote) -> String {
        var markdown = ""

        // Frontmatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let createdStr = dateFormatter.string(from: dailyNote.date)

        markdown += "---\n"
        markdown += "created: \(createdStr)\n"
        markdown += "noteType: CardNote\n"
        markdown += "---\n\n"

        for (index, note) in dailyNote.notes.enumerated() {
            // Extract first line as heading, truncate at 20 chars
            let firstLine = note.firstLine
            let heading = firstLine.count > 20 ? String(firstLine.prefix(20)) + "..." : firstLine

            // Add heading
            markdown += "# \(heading)\n\n"

            // Add full content (including first line)
            if !note.content.isEmpty {
                markdown += "\(note.content)\n\n"
            }

            // Add images at the end
            for image in note.images {
                let imageName = URL(fileURLWithPath: image).lastPathComponent
                markdown += "![](Attachments/\(imageName))\n\n"
            }

            // Add separator between notes
            if index < dailyNote.notes.count - 1 {
                markdown += "---\n\n"
            }
        }

        return markdown
    }

    // MARK: - Per-Day ExportItem Conversion

    func convertToDailyExportItems(_ dailyNotes: [DailyNote]) -> [ExportItem] {
        return dailyNotes.map { dailyNote in
            ExportItem(
                filename: dailyNote.filename,
                displayName: dailyNote.filename,
                contentKey: dailyNote.dateString
            )
        }
    }

    // MARK: - Per-Card Mode

    func convertToCardExportItems(_ notes: [FlomoNote]) -> ([ExportItem], [String: String]) {
        var exportItems: [ExportItem] = []
        var markdownContents: [String: String] = [:]
        var usedFilenames: [String: Int] = [:]

        for note in notes {
            let baseFilename = sanitizeFilename(note.firstLine, timestamp: note.timestamp)
            let filename: String

            if let count = usedFilenames[baseFilename] {
                usedFilenames[baseFilename] = count + 1
                filename = "\(baseFilename)-\(count + 1).md"
            } else {
                usedFilenames[baseFilename] = 1
                filename = "\(baseFilename).md"
            }

            let displayName = truncateForDisplay(note.firstLine, timestamp: note.timestamp)
            let markdown = generateCardMarkdown(for: note)

            let item = ExportItem(
                filename: filename,
                displayName: displayName,
                contentKey: filename
            )

            exportItems.append(item)
            markdownContents[filename] = markdown
        }

        return (exportItems, markdownContents)
    }

    func generateCardMarkdown(for note: FlomoNote) -> String {
        var markdown = ""

        // Frontmatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let createdStr = formatter.string(from: note.timestamp)

        markdown += "---\n"
        markdown += "created: \(createdStr)\n"
        markdown += "noteType: CardNote\n"
        markdown += "---\n\n"

        // Full content
        if !note.content.isEmpty {
            markdown += "\(note.content)\n\n"
        }

        // Images at the end
        for image in note.images {
            let imageName = URL(fileURLWithPath: image).lastPathComponent
            markdown += "![](Attachments/\(imageName))\n\n"
        }

        return markdown
    }

    // MARK: - Filename Helpers

    private func sanitizeFilename(_ firstLine: String, timestamp: Date) -> String {
        var name = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HHmmss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return "无标题 \(formatter.string(from: timestamp))"
        }

        // Truncate to 20 characters
        if name.count > 20 {
            name = String(name.prefix(20))
        }

        // Replace invalid filename characters
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        name = name.unicodeScalars.map { invalidChars.contains($0) ? "-" : String($0) }.joined()

        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func truncateForDisplay(_ firstLine: String, timestamp: Date) -> String {
        let name = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HHmmss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return "无标题 \(formatter.string(from: timestamp))"
        }

        if name.count > 20 {
            return String(name.prefix(20)) + "..."
        }

        return name
    }
}
