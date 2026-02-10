//
//  WelcomeView.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import SwiftUI
import UniformTypeIdentifiers

struct WelcomeView: View {
    @Binding var selectedFile: URL?
    let onFileSelected: () -> Void

    @State private var isDragging = false
    @State private var isHovering = false

    var body: some View {
        ZStack {
            // Subtle background gradient
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App Title with refined typography
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(isDragging ? 180 : 0))
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isDragging)

                        HStack(spacing: 0) {
                            Text("Flomo")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                            Text(" → ")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundColor(.secondary)
                            Text("Obsidian")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.primary)
                    }

                    Text("Transform your fleeting thoughts into lasting knowledge")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                        .tracking(0.3)
                }
                .padding(.bottom, 56)

                // Enhanced drop zone
                VStack(spacing: 24) {
                    ZStack {
                        // Animated background layers
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: isDragging ?
                                        [Color.blue.opacity(0.15), Color.purple.opacity(0.15)] :
                                        [Color.secondary.opacity(0.04), Color.secondary.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: isDragging ?
                                                [.blue, .purple] :
                                                [Color.secondary.opacity(0.2), Color.secondary.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isDragging ? 2.5 : 1.5
                                    )
                            )
                            .shadow(
                                color: isDragging ? Color.blue.opacity(0.2) : Color.black.opacity(0.03),
                                radius: isDragging ? 20 : 8,
                                x: 0,
                                y: isDragging ? 8 : 4
                            )

                        VStack(spacing: 20) {
                            Image(systemName: isDragging ? "arrow.down.doc.fill" : "doc.zipper")
                                .font(.system(size: 56, weight: .thin))
                                .foregroundColor(isDragging ? .blue : .secondary)
                                .symbolEffect(.bounce, value: isDragging)
                                .scaleEffect(isDragging ? 1.1 : 1.0)

                            VStack(spacing: 8) {
                                Text(isDragging ? "Release to import" : "Drop your Flomo export")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(isDragging ? .primary : .secondary)

                                Text("or click below to browse")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                        }
                        .padding(48)
                    }
                    .frame(width: 460, height: 240)
                    .scaleEffect(isDragging ? 1.02 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isDragging)
                    .onDrop(of: ["public.file-url"], isTargeted: $isDragging) { providers in
                        handleDrop(providers: providers)
                    }

                    // Custom styled button
                    Button(action: selectFile) {
                        HStack(spacing: 10) {
                            Image(systemName: "folder")
                                .font(.system(size: 14, weight: .medium))

                            Text("Select ZIP File")
                                .font(.system(size: 15, weight: .semibold))
                                .tracking(0.2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(isHovering ? 0.9 : 1.0))
                        )
                        .shadow(
                            color: Color.blue.opacity(isHovering ? 0.4 : 0.3),
                            radius: isHovering ? 12 : 8,
                            x: 0,
                            y: isHovering ? 6 : 4
                        )
                        .scaleEffect(isHovering ? 1.03 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHovering = hovering
                        }
                    }
                }

                Spacer()

                // Refined footer
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Crafted with")
                            .font(.system(size: 11, weight: .regular))
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.red.opacity(0.8))
                        Text("by iBlinkQ")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.bottom, 20)
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension.lowercased() == "zip" else {
                return
            }

            DispatchQueue.main.async {
                self.selectedFile = url
                self.onFileSelected()
            }
        }

        return true
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedFile = panel.url
            onFileSelected()
        }
    }
}
