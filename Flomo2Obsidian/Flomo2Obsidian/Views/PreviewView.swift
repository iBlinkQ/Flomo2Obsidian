//
//  PreviewView.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import SwiftUI

struct PreviewView: View {
    let dailyNotes: [DailyNote]
    let markdownContents: [String: String]

    @State private var selectedNote: DailyNote?

    let onBack: () -> Void
    let onExport: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Preview Converted Notes")
                .font(.title)
                .fontWeight(.semibold)

            Text("\(dailyNotes.count) daily notes created")
                .foregroundColor(.secondary)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(dailyNotes) { note in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.secondary)
                            Text(note.filename)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedNote?.id == note.id ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
                        )
                        .onTapGesture {
                            selectedNote = note
                        }
                    }
                }
            }
            .frame(height: 300)

            HStack(spacing: 16) {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Export") {
                    onExport()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .sheet(item: $selectedNote) { note in
            MarkdownPreviewSheet(note: note, content: markdownContents[note.dateString] ?? "")
        }
    }
}

struct MarkdownPreviewSheet: View {
    let note: DailyNote
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(note.filename)
                .font(.title2)
                .fontWeight(.semibold)

            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
    }
}
