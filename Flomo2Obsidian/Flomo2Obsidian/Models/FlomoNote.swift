//
//  FlomoNote.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import Foundation

struct AudioAttachment {
    let filePath: String   // e.g. "file/2025-06-18/101/audio_record_watch_xxx.m4a"
    let transcript: String // Flomo 语音转文字文本
}

struct FlomoNote: Identifiable {
    let id = UUID()
    let timestamp: Date
    let content: String
    let images: [String]
    let audios: [AudioAttachment]

    init(timestamp: Date, content: String, images: [String], audios: [AudioAttachment] = []) {
        self.timestamp = timestamp
        self.content = content
        self.images = images
        self.audios = audios
    }

    var firstLine: String {
        content.components(separatedBy: "\n").first ?? ""
    }

    var bodyContent: String {
        let lines = content.components(separatedBy: "\n")
        return lines.dropFirst().joined(separator: "\n")
    }
}
