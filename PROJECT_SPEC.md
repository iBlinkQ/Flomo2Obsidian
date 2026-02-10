# Flomo to Obsidian Converter - Project Specification

## Project Overview

A lightweight macOS desktop application that converts Flomo note exports into Obsidian-compatible Markdown format.

**Key Principles:**
- Offline-only operation
- Lightweight and fast startup
- Simple, clean UI (avoid blue-purple gradients)
- Native macOS experience

## Technology Stack

**Platform:** Swift + SwiftUI (Native macOS)

**Rationale:**
- Smallest app size and best performance
- Native macOS look and feel
- Fast startup time
- Direct access to system APIs

## Core Features

### 1. File Upload
- Drag & drop support for .zip files
- File picker dialog as alternative
- Validate file is a Flomo export

### 2. Date Range Selection
- Parse all notes to extract date range
- Display date range to user (earliest to latest)
- Allow user to select custom date range
- Default: select all dates
- Show loading animation during parsing

### 3. Conversion Process
- Convert selected notes to daily markdown files
- Show loading animation during conversion
- Progress indicator if possible

### 4. Preview (Before Download)
- Show list of generated daily notes
- Allow user to preview markdown content
- Display file count and date range summary

### 5. Export
- Generate zip file with converted notes
- Save dialog for user to choose location
- Zip structure:
  - Daily notes at root (YYYY-MM-DD.md)
  - Attachments/ folder with all images

## Conversion Rules

### Daily Note Format
- Filename: `YYYY-MM-DD.md` (e.g., `2026-02-04.md`)
- One file per day
- Multiple Flomo notes from same day merged into one file
- Notes sorted by creation time (earliest first)

### Note Structure
```markdown
# First line of Flomo note becomes H1 heading

Rest of the note content here...

![](Attachments/image.png)

---

# Next note's first line

Content of second note...
```

### Content Transformation
1. **First line → H1 heading**: Extract first line, convert to `# Heading`
2. **Tags**: Keep as-is (e.g., `#知识管理`, `#AI洞见`)
3. **Images**:
   - Move to end of note content
   - Use relative path: `![](Attachments/filename.png)`
   - Preserve original filenames
4. **Separators**: Add `---` between notes from same day

### Attachment Handling
- All images moved to `Attachments/` folder (flat structure)
- Preserve original filenames
- Handle duplicate filenames (append number if needed)
- Update image references in markdown

## Flomo Export Structure

**Input Format:**
```
flomo@Username-YYYYMMDD.zip
├── Username的笔记.html          # Contains all note content
└── file/                        # Attachments folder
    ├── YYYY-MM-DD/
    │   └── 101/
    │       └── [image files]
    └── ...
```

**HTML Structure:**
```html
<div class="memo">
  <div class="time">2026-01-30 15:38:14</div>
  <div class="content">
    <p>First line becomes heading</p>
    <p>Rest of content...</p>
  </div>
  <div class="files">
    <img src="file/2026-01-28/101/image.png" />
  </div>
</div>
```

## UI/UX Design

### Design Principles
- **Minimalist**: Clean, uncluttered interface
- **Native**: Follow macOS Human Interface Guidelines
- **Fast**: Instant feedback, smooth animations
- **Clear**: Obvious next steps at each stage

### Color Palette
- **Primary**: System accent color (user's preference)
- **Background**: System background (light/dark mode support)
- **Text**: System text colors
- **Avoid**: Blue-purple gradients
- **Use**: Subtle grays, system colors, minimal decoration

### App Flow
```
1. Welcome Screen
   ↓ (Drag & Drop or Select File)
2. Date Range Selection
   ↓ (Confirm)
3. Converting... (Loading)
   ↓
4. Preview Screen
   ↓ (Export)
5. Save Dialog
   ↓
6. Success / Return to Start
```

### Screen Designs

#### 1. Welcome Screen
- Large drop zone in center
- Text: "Drop Flomo export here or click to select"
- Small icon (document/folder)
- "Select File" button below
- Minimal, centered layout

#### 2. Date Range Selection
- Title: "Select Date Range"
- Display: "Found X notes from [earliest] to [latest]"
- Date pickers: Start Date | End Date
- "Select All" checkbox (default: checked)
- Loading spinner during parsing
- "Cancel" and "Convert" buttons

#### 3. Converting Screen
- Progress indicator (spinner or progress bar)
- Text: "Converting notes..."
- Optional: "X of Y notes processed"
- Clean, centered layout

#### 4. Preview Screen
- Title: "Preview Converted Notes"
- Summary: "X daily notes created (YYYY-MM-DD to YYYY-MM-DD)"
- List of daily note files (scrollable)
- Click to preview markdown content
- "Back" and "Export" buttons

## Technical Architecture

### Core Components

1. **FileHandler**
   - Validate zip file
   - Extract and parse HTML
   - Extract attachments
   - Handle file I/O

2. **HTMLParser**
   - Parse Flomo HTML structure
   - Extract memo data (time, content, images)
   - Handle Chinese encoding

3. **DateRangeManager**
   - Extract date range from notes
   - Filter notes by date range
   - Sort notes by timestamp

4. **MarkdownConverter**
   - Convert HTML content to Markdown
   - Extract first line as H1 heading
   - Handle tags, formatting
   - Generate daily note files

5. **AttachmentManager**
   - Copy images to Attachments folder
   - Handle filename conflicts
   - Update image references

6. **ZipGenerator**
   - Create output zip structure
   - Package daily notes and attachments
   - Generate final export file

### Data Models

```swift
struct FlomoNote {
    let timestamp: Date
    let content: String
    let images: [String]
}

struct DailyNote {
    let date: Date
    let notes: [FlomoNote]
    var markdown: String
}
```

### Processing Flow

```
1. User drops zip file
   ↓
2. Extract zip to temp directory
   ↓
3. Parse HTML file
   ↓
4. Extract all FlomoNote objects
   ↓
5. Determine date range
   ↓
6. User selects date range
   ↓
7. Filter notes by date range
   ↓
8. Group notes by date
   ↓
9. Convert to DailyNote objects
   ↓
10. Generate markdown for each day
   ↓
11. Copy attachments to Attachments/
   ↓
12. Create output zip
   ↓
13. Present to user for download
```

## Implementation Considerations

### Error Handling
- Invalid zip file format
- Missing HTML file
- Corrupted HTML structure
- Missing attachments
- Disk space issues
- File permission errors

### Performance Optimization
- Parse HTML asynchronously
- Show progress during conversion
- Use background threads for file operations
- Lazy loading for preview

### Testing Strategy
- Test with various Flomo export sizes
- Test with Chinese characters
- Test with missing attachments
- Test date range edge cases
- Test with corrupted HTML

## Development Phases

### Phase 1: Core Parsing (Week 1)
- Set up Swift project
- Implement FileHandler
- Implement HTMLParser
- Test with sample Flomo export

### Phase 2: Conversion Logic (Week 1-2)
- Implement MarkdownConverter
- Implement AttachmentManager
- Test conversion accuracy

### Phase 3: UI Development (Week 2)
- Build Welcome screen
- Build Date Range Selection screen
- Build Converting screen
- Build Preview screen

### Phase 4: Integration & Polish (Week 3)
- Connect UI to backend
- Add loading animations
- Error handling
- Testing and bug fixes

### Phase 5: Packaging (Week 3)
- App icon and branding
- Build for distribution
- User testing
- Documentation

## Example Output

### Input: Flomo Export
- 50 notes from 2025-12-28 to 2026-01-30
- 15 images attached

### Output: Obsidian-ready Zip
```
obsidian-notes.zip
├── 2025-12-28.md
├── 2025-12-29.md
├── 2026-01-05.md
├── 2026-01-10.md
├── 2026-01-13.md
├── 2026-01-23.md
├── 2026-01-28.md
├── 2026-01-30.md
└── Attachments/
    ├── 08c1f7b901c802616041e882fc37efa6.png
    ├── 4ac5a8b7d7ae3e12df1bfe78d28d646d.png
    ├── 1768294963838_H5QRcaGr.jpg
    └── ...
```

### Sample Daily Note (2026-01-30.md)
```markdown
# 知识管理 学习的蔓延成本

最近系统学习AI 编程，这是一个充满大量成熟知识与习新知识的陌生世界。

有时候希望学一个A点，但过程中发现有一个B点，认为也是需要掌握的，就可能去探索B点，然后花费了很多时间（花费时间多可能意味着探索比较成功），就比预期学习 A 点用了更多时间，但好处是你掌握了 A+B，甚至更多。

这既可能带来兴奋，也可能带来疲惫。

需要随时知道自己在哪里 Where am I。

也不一定任何分支都要探索，可以先记录下过程中遇到的 B，之后再探索。

---

#AI洞见

那种因为被B点吸引而花费的额外时间，如果促使你完成了深刻的连接，它就不是成本，而是高价值的「必要难度」投资。
```

## Next Steps

1. Review and approve this specification
2. Set up Xcode project
3. Begin Phase 1 development
4. Iterate based on testing feedback
