# Flomo 转 Obsidian 转换器 - 实现计划

## 项目设置

### 1. 创建 Xcode 项目
- 打开 Xcode
- 创建新的 macOS App 项目
- 名称："Flomo2Obsidian"
- 界面：SwiftUI
- 语言：Swift
- 最低部署版本：macOS 15.0+

### 2. 项目结构
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

## 第 1 阶段：核心数据模型（第 1 天）

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

## 第 2 阶段：文件处理（第 1-2 天）

### FileHandler.swift
主要职责：
- 验证 zip 文件格式
- 将 zip 解压到临时目录
- 查找并读取 HTML 文件
- 清理临时文件

```swift
class FileHandler {
    func validateZipFile(_ url: URL) -> Bool
    func extractZip(_ url: URL) throws -> URL
    func findHTMLFile(in directory: URL) -> URL?
    func cleanup(directory: URL)
}
```

## 第 3 阶段：HTML 解析（第 2-3 天）

### HTMLParser.swift
主要职责：
- 解析 HTML 结构
- 提取 memo 元素
- 解析时间戳、内容、图片
- 处理中文编码

```swift
class HTMLParser {
    func parseHTML(_ htmlContent: String) throws -> [FlomoNote]
    private func extractMemos(from html: String) -> [String]
    private func parseTimestamp(_ timeString: String) -> Date?
    private func extractImages(from memoHTML: String) -> [String]
}
```

### 实现说明：
- 使用 SwiftSoup 或原生 XML 解析
- 优雅地处理格式错误的 HTML
- 支持 UTF-8 编码

## 第 4 阶段：Markdown 转换（第 3-4 天）

### MarkdownConverter.swift
主要职责：
- 将 HTML 内容转换为 Markdown
- 提取第一行作为 H1 标题
- 保留标签和格式
- 按日期对笔记进行分组

```swift
class MarkdownConverter {
    func convertToDailyNotes(_ notes: [FlomoNote]) -> [DailyNote]
    func generateMarkdown(for dailyNote: DailyNote) -> String
    private func htmlToMarkdown(_ html: String) -> String
    private func extractFirstLineAsHeading(_ content: String) -> (heading: String, body: String)
}
```

## 第 5 阶段：附件管理（第 4 天）

### AttachmentManager.swift
主要职责：
- 将图片复制到 Attachments 文件夹
- 处理文件名冲突
- 更新 Markdown 中的图片引用

```swift
class AttachmentManager {
    func copyAttachments(from sourceDir: URL, to destDir: URL, notes: [FlomoNote]) throws -> [String: String]
    private func handleDuplicateFilename(_ filename: String, in directory: URL) -> String
    func updateImageReferences(in markdown: String, with mapping: [String: String]) -> String
}
```

## 第 6 阶段：Zip 生成（第 4-5 天）

### ZipGenerator.swift
主要职责：
- 创建输出 zip 结构
- 打包每日笔记和附件
- 生成最终导出文件

```swift
class ZipGenerator {
    func createZip(dailyNotes: [DailyNote], attachmentsDir: URL) throws -> URL
    private func createTempDirectory() -> URL
    private func writeMarkdownFiles(_ notes: [DailyNote], to directory: URL) throws
    private func zipDirectory(_ directory: URL) throws -> URL
}
```

## 第 7 阶段：UI 实现（第 5-7 天）

### WelcomeView.swift
- 拖放区域
- 文件选择器按钮
- 文件验证

### DateRangeView.swift
- 显示日期范围
- 日期选择器
- “全选”复选框
- 解析期间的加载指示器

### ConvertingView.swift
- 进度指示器
- 状态文本
- 进度计数器

### PreviewView.swift
- 每日笔记列表
- 点击预览 Markdown
- 导出按钮

## 第 8 阶段：集成与状态管理（第 7-8 天）

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

## 第 9 阶段：测试（第 8-9 天）

### 单元测试
- 使用 HTML 样本测试 HTMLParser
- 测试 MarkdownConverter 输出
- 测试 AttachmentManager 文件处理
- 测试日期范围过滤

### 集成测试
- 测试完整的转换流水线
- 测试各种文件大小
- 测试附件缺失的情况
- 测试各种边缘情况

### 手动测试
- 测试拖放功能
- 测试 UI 响应速度
- 测试错误处理
- 在不同的 macOS 版本上测试

## 第 10 阶段：完善与打包（第 9-10 天）

### 应用图标
- 设计 1024x1024 图标
- 使用 SF Symbols 或自定义设计
- 添加到 Assets.xcassets

### 构建设置
- 设置应用名称和 Bundle Identifier
- 配置最低 macOS 版本
- 设置代码签名

### 发布
- 存档 (Archive) 应用用于发布
- 导出为 .app 包
- 在干净的 macOS 环境下测试
- 编写用户文档

## 依赖关系

### 所需库
1. **SwiftSoup** (HTML 解析)
   - 通过 Swift Package Manager 添加
   - URL: https://github.com/scinfu/SwiftSoup

2. **ZIPFoundation** (Zip 处理)
   - 通过 Swift Package Manager 添加
   - URL: https://github.com/weichsel/ZIPFoundation

### 安装
```swift
// 在 Xcode 中：File > Add Packages
// 添加以上 URL
```

## 关键实现细节

### HTML 解析策略
```swift
// 解析逻辑示例
let html = try String(contentsOf: htmlFileURL, encoding: .utf8)
let doc = try SwiftSoup.parse(html)
let memos = try doc.select("div.memo")

for memo in memos {
    let timeStr = try memo.select("div.time").text()
    let content = try memo.select("div.content").html()
    let images = try memo.select("div.files img").array()
}
```

### Markdown 生成策略
```swift
func generateMarkdown(for dailyNote: DailyNote) -> String {
    var markdown = ""
    
    for (index, note) in dailyNote.notes.enumerated() {
        // 提取第一行作为标题
        let lines = note.content.components(separatedBy: "\n")
        let heading = lines.first ?? "无标题"
        let body = lines.dropFirst().joined(separator: "\n")
        
        markdown += "# \(heading)\n\n"
        markdown += "\(body)\n\n"
        
        // 在末尾添加图片
        for image in note.images {
            markdown += "![](\(image))\n\n"
        }
        
        // 在笔记之间添加分隔符
        if index < dailyNote.notes.count - 1 {
            markdown += "---\n\n"
        }
    }
    
    return markdown
}
```

### 日期分组策略
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

## 错误处理策略

### 常见错误
1. zip 文件格式无效
2. 缺少 HTML 文件
3. HTML 结构损坏
4. 缺少附件
5. 磁盘空间问题
6. 文件权限错误

### 错误处理模式
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
            return "无效的 Flomo 导出文件"
        case .htmlFileNotFound:
            return "在导出文件中未找到 HTML 文件"
        case .parsingFailed(let detail):
            return "解析笔记失败：\(detail)"
        case .attachmentMissing(let filename):
            return "未找到附件：\(filename)"
        case .diskSpaceInsufficient:
            return "磁盘空间不足"
        }
    }
}
```

## 性能考量

### 异步操作
```swift
// 异步解析 HTML
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

### 内存管理
- 分块处理大文件
- 及时释放临时文件
- 对批量操作使用 autoreleasepool
- 在转换期间监控内存使用情况

## 时间表摘要

| 阶段 | 周期 | 交付成果 |
|-------|----------|-------------|
| 1. 数据模型 | 0.5 天 | 核心结构体 |
| 2. 文件处理 | 1 天 | Zip 解压 |
| 3. HTML 解析 | 1.5 天 | 笔记提取 |
| 4. Markdown 转换 | 1 天 | MD 生成 |
| 5. 附件管理 | 0.5 天 | 图片处理 |
| 6. Zip 生成 | 1 天 | 输出文件创建 |
| 7. UI 实现 | 2 天 | 所有界面 |
| 8. 集成 | 1 天 | 状态管理 |
| 9. 测试 | 1 天 | 质量保证 (QA) |
| 10. 完善与打包 | 1 天 | 应用分发 |
| **总计** | **10 天** | **完整的应用** |

## 下一步

1. ✅ 审查此实现计划
2. 设置 Xcode 项目
3. 添加依赖项 (SwiftSoup, ZIPFoundation)
4. 从第 1 阶段（数据模型）开始
5. 按顺序迭代各个阶段
