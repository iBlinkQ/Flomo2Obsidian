# Flomo to Obsidian Converter - Implementation Plan

## Project Setup

### 1. Create Xcode Project
- Open Xcode
- Create new macOS App project
- Name: "Flomo2Obsidian"
- Interface: SwiftUI
- Language: Swift
- Minimum deployment: macOS 13.0+

### 2. Project Structure
```
Flomo2Obsidian/
├── App/
│   ├── Flomo2ObsidianApp.swift
│   └── ContentView.swift
├── Models/
│   ├── FlomoNote.swift
│   └── DailyNote.swift
├── Services/
│   ├── FileHandler.swift
│   ├── HTMLParser.swift
│   ├── MarkdownConverter.swift
│   ├── AttachmentManager.swift
│   └── ZipGenerator.swift
├── Views/
│   ├── WelcomeView.swift
│   ├── DateRangeView.swift
│   ├── ConvertingView.swift
│   └── PreviewView.swift
└── Resources/
    └── Assets.xcassets
```

## Phase 1: Core Data Models (Day 1)

### FlomoNote.swift
```swift
struct FlomoNote: Identifiable {
    let id = UUID()
    let timestamp: Date
    let content: String
    let images: [String]
    
    var firstLine: String {
        content.components(separatedBy: "\n").first ?? ""
    }
}
```

### DailyNote.swift
```swift
struct DailyNote: Identifiable {
    let id = UUID()
    let date: Date
    var notes: [FlomoNote]
    
    var filename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: date)).md"
    }
}
```

## Phase 2: File Handling (Day 1-2)

### FileHandler.swift
Key responsibilities:
- Validate zip file format
- Extract zip to temporary directory
- Find and read HTML file
- Clean up temporary files

```swift
class FileHandler {
    func validateZipFile(_ url: URL) -> Bool
    func extractZip(_ url: URL) throws -> URL
    func findHTMLFile(in directory: URL) -> URL?
    func cleanup(directory: URL)
}
```

## Phase 3: HTML Parsing (Day 2-3)

### HTMLParser.swift
Key responsibilities:
- Parse HTML structure
- Extract memo elements
- Parse timestamp, content, images
- Handle Chinese encoding

```swift
class HTMLParser {
    func parseHTML(_ htmlContent: String) throws -> [FlomoNote]
    private func extractMemos(from html: String) -> [String]
    private func parseTimestamp(_ timeString: String) -> Date?
    private func extractImages(from memoHTML: String) -> [String]
}
```

### Implementation notes:
- Use SwiftSoup or native XML parsing
- Handle malformed HTML gracefully
- Support UTF-8 encoding

## Phase 4: Markdown Conversion (Day 3-4)

### MarkdownConverter.swift
Key responsibilities:
- Convert HTML content to Markdown
- Extract first line as H1 heading
- Preserve tags and formatting
- Group notes by date

```swift
class MarkdownConverter {
    func convertToDailyNotes(_ notes: [FlomoNote]) -> [DailyNote]
    func generateMarkdown(for dailyNote: DailyNote) -> String
    private func htmlToMarkdown(_ html: String) -> String
    private func extractFirstLineAsHeading(_ content: String) -> (heading: String, body: String)
}
```

## Phase 5: Attachment Management (Day 4)

### AttachmentManager.swift
Key responsibilities:
- Copy images to Attachments folder
- Handle filename conflicts
- Update image references in markdown

```swift
class AttachmentManager {
    func copyAttachments(from sourceDir: URL, to destDir: URL, notes: [FlomoNote]) throws -> [String: String]
    private func handleDuplicateFilename(_ filename: String, in directory: URL) -> String
    func updateImageReferences(in markdown: String, with mapping: [String: String]) -> String
}
```

## Phase 6: Zip Generation (Day 4-5)

### ZipGenerator.swift
Key responsibilities:
- Create output zip structure
- Package daily notes and attachments
- Generate final export file

```swift
class ZipGenerator {
    func createZip(dailyNotes: [DailyNote], attachmentsDir: URL) throws -> URL
    private func createTempDirectory() -> URL
    private func writeMarkdownFiles(_ notes: [DailyNote], to directory: URL) throws
    private func zipDirectory(_ directory: URL) throws -> URL
}
```

## Phase 7: UI Implementation (Day 5-7)

### WelcomeView.swift
- Drag & drop zone
- File picker button
- File validation

### DateRangeView.swift
- Display date range
- Date pickers
- "Select All" checkbox
- Loading indicator during parsing

### ConvertingView.swift
- Progress indicator
- Status text
- Progress counter

### PreviewView.swift
- List of daily notes
- Click to preview markdown
- Export button

## Phase 8: Integration & State Management (Day 7-8)

### AppState.swift
```swift
@MainActor
class AppState: ObservableObject {
    @Published var currentScreen: Screen = .welcome
    @Published var selectedFile: URL?
    @Published var flomoNotes: [FlomoNote] = []
    @Published var dailyNotes: [DailyNote] = []
    @Published var dateRange: (start: Date, end: Date)?
    @Published var isProcessing = false
    @Published var error: String?
    
    enum Screen {
        case welcome
        case dateRange
        case converting
        case preview
    }
}
```

## Phase 9: Testing (Day 8-9)

### Unit Tests
- Test HTMLParser with sample HTML
- Test MarkdownConverter output
- Test AttachmentManager file handling
- Test date range filtering

### Integration Tests
- Test full conversion pipeline
- Test with various file sizes
- Test with missing attachments
- Test with edge cases

### Manual Testing
- Test drag & drop functionality
- Test UI responsiveness
- Test error handling
- Test on different macOS versions

## Phase 10: Polish & Packaging (Day 9-10)

### App Icon
- Design 1024x1024 icon
- Use SF Symbols or custom design
- Add to Assets.xcassets

### Build Settings
- Set app name and bundle identifier
- Configure minimum macOS version
- Set up code signing

### Distribution
- Archive app for distribution
- Export as .app bundle
- Test on clean macOS installation
- Create user documentation

## Dependencies

### Required Libraries
1. **SwiftSoup** (HTML parsing)
   - Add via Swift Package Manager
   - URL: https://github.com/scinfu/SwiftSoup

2. **ZIPFoundation** (Zip handling)
   - Add via Swift Package Manager
   - URL: https://github.com/weichsel/ZIPFoundation

### Installation
```swift
// In Xcode: File > Add Packages
// Add the above URLs
```

## Key Implementation Details

### HTML Parsing Strategy
```swift
// Example parsing logic
let html = try String(contentsOf: htmlFileURL, encoding: .utf8)
let doc = try SwiftSoup.parse(html)
let memos = try doc.select("div.memo")

for memo in memos {
    let timeStr = try memo.select("div.time").text()
    let content = try memo.select("div.content").html()
    let images = try memo.select("div.files img").array()
}
```

### Markdown Generation Strategy
```swift
func generateMarkdown(for dailyNote: DailyNote) -> String {
    var markdown = ""
    
    for (index, note) in dailyNote.notes.enumerated() {
        // Extract first line as heading
        let lines = note.content.components(separatedBy: "\n")
        let heading = lines.first ?? "Untitled"
        let body = lines.dropFirst().joined(separator: "\n")
        
        markdown += "# \(heading)\n\n"
        markdown += "\(body)\n\n"
        
        // Add images at the end
        for image in note.images {
            markdown += "![](\(image))\n\n"
        }
        
        // Add separator between notes
        if index < dailyNote.notes.count - 1 {
            markdown += "---\n\n"
        }
    }
    
    return markdown
}
```

### Date Grouping Strategy
```swift
func groupNotesByDate(_ notes: [FlomoNote]) -> [DailyNote] {
    let calendar = Calendar.current
    let grouped = Dictionary(grouping: notes) { note in
        calendar.startOfDay(for: note.timestamp)
    }
    
    return grouped.map { date, notes in
        DailyNote(date: date, notes: notes.sorted { $0.timestamp < $1.timestamp })
    }.sorted { $0.date < $1.date }
}
```

## Error Handling Strategy

### Common Errors
1. Invalid zip file format
2. Missing HTML file
3. Corrupted HTML structure
4. Missing attachments
5. Disk space issues
6. File permission errors

### Error Handling Pattern
```swift
enum ConversionError: LocalizedError {
    case invalidZipFile
    case htmlFileNotFound
    case parsingFailed(String)
    case attachmentMissing(String)
    case diskSpaceInsufficient
    
    var errorDescription: String? {
        switch self {
        case .invalidZipFile:
            return "Invalid Flomo export file"
        case .htmlFileNotFound:
            return "HTML file not found in export"
        case .parsingFailed(let detail):
            return "Failed to parse notes: \(detail)"
        case .attachmentMissing(let filename):
            return "Attachment not found: \(filename)"
        case .diskSpaceInsufficient:
            return "Insufficient disk space"
        }
    }
}
```

## Performance Considerations

### Async Operations
```swift
// Parse HTML asynchronously
Task {
    do {
        let notes = try await parseHTMLAsync(htmlContent)
        await MainActor.run {
            self.flomoNotes = notes
        }
    } catch {
        await MainActor.run {
            self.error = error.localizedDescription
        }
    }
}
```

### Memory Management
- Process large files in chunks
- Release temporary files promptly
- Use autoreleasepool for batch operations
- Monitor memory usage during conversion

## Timeline Summary

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1. Data Models | 0.5 day | Core structs |
| 2. File Handling | 1 day | Zip extraction |
| 3. HTML Parsing | 1.5 days | Note extraction |
| 4. Markdown Conversion | 1 day | MD generation |
| 5. Attachment Management | 0.5 day | Image handling |
| 6. Zip Generation | 1 day | Output creation |
| 7. UI Implementation | 2 days | All screens |
| 8. Integration | 1 day | State management |
| 9. Testing | 1 day | QA |
| 10. Polish & Packaging | 1 day | Distribution |
| **Total** | **10 days** | **Complete app** |

## Next Steps

1. ✅ Review this implementation plan
2. Set up Xcode project
3. Add dependencies (SwiftSoup, ZIPFoundation)
4. Start with Phase 1 (Data Models)
5. Iterate through phases sequentially
