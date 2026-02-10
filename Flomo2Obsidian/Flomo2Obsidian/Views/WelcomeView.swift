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

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Drop zone
            VStack(spacing: 16) {
                Image(systemName: "doc.zipper")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("Drop Flomo export here\nor click to select")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .frame(width: 400, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isDragging ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                    .background(isDragging ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .onDrop(of: ["public.file-url"], isTargeted: $isDragging) { providers in
                handleDrop(providers: providers)
            }

            Button("Select File") {
                selectFile()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
