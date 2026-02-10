//
//  FlomoNote.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation

struct FlomoNote: Identifiable {
    let id = UUID()
    let timestamp: Date
    let content: String
    let images: [String]

    var firstLine: String {
        content.components(separatedBy: "\n").first ?? ""
    }

    var bodyContent: String {
        let lines = content.components(separatedBy: "\n")
        return lines.dropFirst().joined(separator: "\n")
    }
}
