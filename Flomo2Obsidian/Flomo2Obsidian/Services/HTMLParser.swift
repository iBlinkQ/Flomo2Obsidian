//
//  HTMLParser.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation
import SwiftSoup

enum HTMLParserError: LocalizedError {
    case parsingFailed(String)
    case invalidTimestamp

    var errorDescription: String? {
        switch self {
        case .parsingFailed(let detail):
            return "Failed to parse HTML: \(detail)"
        case .invalidTimestamp:
            return "Invalid timestamp format"
        }
    }
}

class HTMLParser {

    func parseHTML(_ htmlContent: String) throws -> [FlomoNote] {
        do {
            let doc = try SwiftSoup.parse(htmlContent)
            let memos = try doc.select("div.memo")

            var notes: [FlomoNote] = []

            for memo in memos {
                if let note = try parseMemo(memo) {
                    notes.append(note)
                }
            }

            return notes.sorted { $0.timestamp < $1.timestamp }
        } catch {
            throw HTMLParserError.parsingFailed(error.localizedDescription)
        }
    }

    private func parseMemo(_ memo: Element) throws -> FlomoNote? {
        let timeStr = try memo.select("div.time").text()
        guard let timestamp = parseTimestamp(timeStr) else {
            return nil
        }

        guard let contentElement = try memo.select("div.content").first() else {
            return nil
        }
        let content = try extractContent(from: contentElement)

        let images = try extractImages(from: memo)

        return FlomoNote(timestamp: timestamp, content: content, images: images)
    }

    private func parseTimestamp(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: timeString)
    }

    private func extractContent(from element: Element) throws -> String {
        var content = ""
        let paragraphs = try element.select("p")

        for p in paragraphs {
            let text = try p.text()
            if !text.isEmpty {
                content += text + "\n"
            }
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractImages(from memo: Element) throws -> [String] {
        let images = try memo.select("div.files img")
        var imagePaths: [String] = []

        for img in images {
            if let src = try? img.attr("src"), !src.isEmpty {
                imagePaths.append(src)
            }
        }

        return imagePaths
    }
}
