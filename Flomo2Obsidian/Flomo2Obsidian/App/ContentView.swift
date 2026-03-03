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

    private var exportFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "obsidian-notes-\(formatter.string(from: Date())).zip"
    }

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
                        exportGranularity: $appState.exportGranularity,
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
                    totalNotes: appState.exportItems.count
                )

            case .preview:
                PreviewView(
                    notes: appState.exportItems,
                    markdownContents: appState.markdownContents,
                    isExporting: appState.isProcessing,
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
            defaultFilename: exportFilename
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
