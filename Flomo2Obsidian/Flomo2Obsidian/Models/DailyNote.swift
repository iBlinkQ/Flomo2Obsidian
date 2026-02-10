//
//  DailyNote.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation

struct DailyNote: Identifiable {
    let id = UUID()
    let date: Date
    var notes: [FlomoNote]

    var filename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: date)).md"
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
