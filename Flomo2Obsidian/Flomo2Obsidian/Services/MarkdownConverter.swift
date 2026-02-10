//
//  MarkdownConverter.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation

class MarkdownConverter {

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

        for (index, note) in dailyNote.notes.enumerated() {
            // Extract first line as heading
            let firstLine = note.firstLine
            let body = note.bodyContent

            // Add heading
            markdown += "# \(firstLine)\n\n"

            // Add body content
            if !body.isEmpty {
                markdown += "\(body)\n\n"
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
}
