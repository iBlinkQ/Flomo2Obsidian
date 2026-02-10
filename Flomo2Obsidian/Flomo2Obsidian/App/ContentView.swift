//
//  ContentView.swift
//  Flomo2Obsidian
//
//  Created on 2026-02-10.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }

    var data: Data

    init(url: URL) throws {
        self.data = try Data(contentsOf: url)
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectAll = true

    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .welcome:
                WelcomeView(
                    selectedFile: $appState.selectedFile,
                    onFileSelected: {
                        appState.processFile()
                    }
                )

            case .dateRange:
                if let dateRange = appState.dateRange {
                    DateRangeView(
                        totalNotes: appState.flomoNotes.count,
                        earliestDate: dateRange.start,
                        latestDate: dateRange.end,
                        startDate: $startDate,
                        endDate: $endDate,
                        selectAll: $selectAll,
                        onCancel: {
                            appState.reset()
                        },
                        onConvert: {
                            appState.convertNotes(startDate: startDate, endDate: endDate)
                        }
                    )
                    .onAppear {
                        startDate = dateRange.start
                        endDate = dateRange.end
                    }
                }

            case .converting:
                ConvertingView(
                    currentProgress: appState.currentProgress,
                    totalNotes: appState.dailyNotes.count
                )

            case .preview:
                PreviewView(
                    dailyNotes: appState.dailyNotes,
                    markdownContents: appState.markdownContents,
                    onBack: {
                        appState.currentScreen = .dateRange
                    },
                    onExport: {
                        appState.exportZip()
                    }
                )
            }
        }
        .fileExporter(
            isPresented: Binding(
                get: { appState.showingExporter && appState.exportURL != nil },
                set: { appState.showingExporter = $0 }
            ),
            document: appState.exportURL.flatMap { url in
                try? ExportDocument(url: url)
            },
            contentType: .zip,
            defaultFilename: "obsidian-notes.zip"
        ) { result in
            switch result {
            case .success:
                appState.reset()
            case .failure(let error):
                appState.error = error.localizedDescription
            }
        }
        .alert("Error", isPresented: .constant(appState.error != nil)) {
            Button("OK") {
                appState.error = nil
            }
        } message: {
            Text(appState.error ?? "")
        }
    }
}
