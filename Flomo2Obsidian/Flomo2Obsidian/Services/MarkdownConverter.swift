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
            // Extract first line as heading, strip tag hashes and truncate at 20 chars
            let firstLine = stripTagHashes(note.firstLine)
            let heading = firstLine.count > 20 ? String(firstLine.prefix(20)) + "…" : firstLine

            // Add heading
            markdown += "# \(heading)\n\n"

            // Add full content (including first line)
            if !note.content.isEmpty {
                markdown += "\(note.content)\n\n"
            }

            // Add audio callouts before images
            markdown += appendAudioCallouts(note.audios)

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

        // Audio callouts before images
        markdown += appendAudioCallouts(note.audios)

        // Images at the end
        for image in note.images {
            let imageName = URL(fileURLWithPath: image).lastPathComponent
            markdown += "![](Attachments/\(imageName))\n\n"
        }

        return markdown
    }

    // MARK: - Audio Callout Helper

    private func appendAudioCallouts(_ audios: [AudioAttachment]) -> String {
        guard !audios.isEmpty else { return "" }
        var output = ""
        for audio in audios {
            let audioName = URL(fileURLWithPath: audio.filePath).lastPathComponent
            output += "> [!tip]+ 语音\n"
            output += "> ![[\(audioName)]]\n"
            if !audio.transcript.isEmpty {
                output += "> \(audio.transcript)\n"
            }
            output += "\n"
        }
        return output
    }

    // MARK: - Filename Helpers

    private func sanitizeFilename(_ firstLine: String, timestamp: Date) -> String {
        var name = stripTagHashes(firstLine).trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HHmmss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return "无标题 \(formatter.string(from: timestamp))"
        }

        // Truncate to 20 characters (Obsidian uses filename as note title)
        if name.count > 20 {
            name = String(name.prefix(20)) + "…"
        }

        // Replace invalid filename characters
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        name = name.unicodeScalars.map { invalidChars.contains($0) ? "-" : String($0) }.joined()

        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func truncateForDisplay(_ firstLine: String, timestamp: Date) -> String {
        let name = stripTagHashes(firstLine).trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HHmmss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return "无标题 \(formatter.string(from: timestamp))"
        }

        if name.count > 20 {
            return String(name.prefix(20)) + "…"
        }

        return name
    }

    // MARK: - Tag Helpers

    /// Remove # from Flomo-style tags in title text.
    /// e.g. "#知识管理 后续内容" → "知识管理 后续内容"
    private func stripTagHashes(_ text: String) -> String {
        // Match # followed by non-whitespace characters (Flomo tag pattern)
        // Handles cases like "#标签", "#知识管理", "#tag/subtag"
        let pattern = "#(\\S+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "$1"
        )
    }
}
