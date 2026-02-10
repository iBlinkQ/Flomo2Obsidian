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
    @State private var isHoveringBack = false
    @State private var isHoveringExport = false

    let onBack: () -> Void
    let onExport: () -> Void

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 32) {
                headerSection
                notesListSection
                actionButtonsSection
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $selectedNote) { note in
            MarkdownPreviewSheet(note: note, content: markdownContents[note.dateString] ?? "")
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .windowBackgroundColor).opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.flomoGreen, .obsidianPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Preview Notes")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            HStack(spacing: 6) {
                Text("\(dailyNotes.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.flomoGreen, .obsidianPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("daily notes created")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var notesListSection: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(dailyNotes) { note in
                    noteRow(for: note)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .frame(height: 340)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }

    private func noteRow(for note: DailyNote) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedNote = note
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            selectedNote?.id == note.id ?
                                LinearGradient(
                                    colors: [.flomoGreen.opacity(0.2), .obsidianPurple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedNote?.id == note.id ? .obsidianPurple : .secondary)
                }

                Text(note.filename)
                    .font(.system(size: 14, weight: selectedNote?.id == note.id ? .semibold : .regular, design: .monospaced))
                    .foregroundColor(selectedNote?.id == note.id ? .primary : .secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(noteRowBackground(isSelected: selectedNote?.id == note.id))
            .overlay(noteRowBorder(isSelected: selectedNote?.id == note.id))
        }
        .buttonStyle(.plain)
    }

    private func noteRowBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: isSelected ?
                        [Color.flomoGreen.opacity(0.08), Color.obsidianPurple.opacity(0.08)] :
                        [Color.secondary.opacity(0.04), Color.secondary.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: isSelected ? Color.obsidianPurple.opacity(0.1) : Color.black.opacity(0.02),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: 2
            )
    }

    private func noteRowBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
                isSelected ?
                    LinearGradient(
                        colors: [.flomoGreen.opacity(0.3), .obsidianPurple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [.clear, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                lineWidth: 1
            )
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Back")
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(0.2)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(isHoveringBack ? 0.12 : 0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(isHoveringBack ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveringBack = hovering
                }
            }

            Button(action: onExport) {
                HStack(spacing: 10) {
                    Text("Export to Obsidian")
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(0.2)

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.flomoGreen, .obsidianPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(isHoveringExport ? 0.9 : 1.0)
                )
                .shadow(
                    color: Color.obsidianPurple.opacity(isHoveringExport ? 0.4 : 0.3),
                    radius: isHoveringExport ? 12 : 8,
                    x: 0,
                    y: isHoveringExport ? 6 : 4
                )
                .scaleEffect(isHoveringExport ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoveringExport = hovering
                }
            }
        }
        .padding(.top, 8)
    }
}

struct MarkdownPreviewSheet: View {
    let note: DailyNote
    let content: String

    @Environment(\.dismiss) private var dismiss
    @State private var isHoveringClose = false

    var body: some View {
        ZStack {
            // Background
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with refined styling
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.flomoGreen.opacity(0.15), .obsidianPurple.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.flomoGreen, .obsidianPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(note.filename)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)

                        Text("Markdown Preview")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                            .tracking(0.3)
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(isHoveringClose ? 0.15 : 0.08))
                                .frame(width: 32, height: 32)

                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .scaleEffect(isHoveringClose ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHoveringClose = hovering
                        }
                    }
                }
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [
                            Color.secondary.opacity(0.04),
                            Color.secondary.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Divider()
                    .background(Color.secondary.opacity(0.2))

                // Content with enhanced styling
                ScrollView {
                    Text(content)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.03))
                        )
                        .padding(20)
                }

                Divider()
                    .background(Color.secondary.opacity(0.2))

                // Footer with solid color button
                HStack {
                    Spacer()

                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(0.2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [.flomoGreen, .obsidianPurple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color.obsidianPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [
                            Color.secondary.opacity(0.04),
                            Color.secondary.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(width: 700, height: 600)
    }
}
