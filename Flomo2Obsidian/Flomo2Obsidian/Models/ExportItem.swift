//
//  ExportItem.swift
//  Flomo2Obsidian
//
//  Created on 2026-03-03.
//

import Foundation

struct ExportItem: Identifiable {
    let id = UUID()
    let filename: String
    let displayName: String
    let contentKey: String
}
