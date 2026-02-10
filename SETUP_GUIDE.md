# Flomo2Obsidian - 项目设置指南

## 项目概述

Flomo2Obsidian 是一个原生 macOS 应用，用于将 Flomo 笔记导出文件转换为 Obsidian 兼容的 Markdown 格式。

## 前置要求

- macOS 13.0 或更高版本
- Xcode 14.0 或更高版本
- Swift 5.7 或更高版本

## 项目结构

```
Flomo2Obsidian/
├── App/
│   ├── Flomo2ObsidianApp.swift    # 应用入口
│   ├── ContentView.swift          # 主视图
│   └── AppState.swift             # 状态管理
├── Models/
│   ├── FlomoNote.swift            # Flomo 笔记数据模型
│   └── DailyNote.swift            # 日记数据模型
├── Services/
│   ├── FileHandler.swift          # 文件处理
│   ├── HTMLParser.swift           # HTML 解析
│   ├── MarkdownConverter.swift    # Markdown 转换
│   ├── AttachmentManager.swift    # 附件管理
│   └── ZipGenerator.swift         # Zip 生成
├── Views/
│   ├── WelcomeView.swift          # 欢迎页面
│   ├── DateRangeView.swift        # 日期选择页面
│   ├── ConvertingView.swift       # 转换中页面
│   └── PreviewView.swift          # 预览页面
└── Resources/
    └── Assets.xcassets            # 资源文件
```

## 设置步骤

### 1. 创建 Xcode 项目

1. 打开 Xcode
2. 选择 "File" > "New" > "Project"
3. 选择 "macOS" > "App"
4. 填写项目信息：
   - Product Name: Flomo2Obsidian
   - Interface: SwiftUI
   - Language: Swift
   - 取消勾选 "Use Core Data"
   - 取消勾选 "Include Tests"
5. 选择保存位置（选择 `/Users/blinkq/flomo2obsidian`）

### 2. 添加依赖库

1. 在 Xcode 中，选择项目文件（左侧导航栏顶部）
2. 选择 "Package Dependencies" 标签
3. 点击 "+" 按钮添加以下依赖：

**SwiftSoup** (HTML 解析)
- URL: `https://github.com/scinfu/SwiftSoup`
- Version: 2.6.0 或更高

**ZIPFoundation** (Zip 文件处理)
- URL: `https://github.com/weichsel/ZIPFoundation`
- Version: 0.9.0 或更高

### 3. 导入代码文件

1. 删除 Xcode 自动生成的文件（保留 Assets.xcassets）
2. 将 `Flomo2Obsidian` 文件夹中的所有代码文件拖入 Xcode 项目
3. 确保勾选 "Copy items if needed"
4. 确保 "Add to targets" 选中了 Flomo2Obsidian

### 4. 配置项目设置

1. 选择项目 > Target > "Signing & Capabilities"
2. 选择你的开发团队（Team）
3. 确保 Bundle Identifier 是唯一的（例如：`com.yourname.Flomo2Obsidian`）

### 5. 构建和运行

1. 选择目标设备："My Mac"
2. 点击 "Run" 按钮（或按 Cmd+R）
3. 应用将启动并显示欢迎界面

## 使用说明

### 转换 Flomo 笔记

1. **上传文件**
   - 将 Flomo 导出的 .zip 文件拖放到应用窗口
   - 或点击 "Select File" 按钮选择文件

2. **选择日期范围**
   - 应用会自动解析笔记的日期范围
   - 可以自定义开始和结束日期
   - 或勾选 "Select All" 选择全部笔记

3. **转换**
   - 点击 "Convert" 按钮开始转换
   - 等待转换完成（会显示进度）

4. **预览和导出**
   - 查看生成的日记文件列表
   - 点击文件名可预览 Markdown 内容
   - 点击 "Export" 按钮保存 zip 文件

### 输出格式

转换后的 zip 文件包含：
- 每日笔记文件（YYYY-MM-DD.md）
- Attachments 文件夹（包含所有图片）

每个日记文件格式：
```markdown
# 笔记第一行作为标题

笔记内容...

![](Attachments/image.png)

---

# 下一条笔记的标题

内容...
```

## 故障排除

### 常见问题

**1. 编译错误：找不到 SwiftSoup 或 ZIPFoundation**
- 确保已正确添加 Package Dependencies
- 尝试 Product > Clean Build Folder
- 重启 Xcode

**2. 无法解析 HTML 文件**
- 确保上传的是 Flomo 官方导出的 zip 文件
- 检查 zip 文件是否包含 .html 文件

**3. 图片无法显示**
- 确保 Flomo 导出文件包含 file 文件夹
- 检查图片路径是否正确

**4. 应用无法启动**
- 检查 macOS 版本是否为 13.0 或更高
- 确保已正确配置代码签名

### 调试技巧

1. 在 Xcode 中查看控制台输出
2. 使用断点调试关键方法
3. 检查 AppState 的状态变化

## 项目文件清单

### 已创建的文件

**数据模型** (Models/)
- ✅ FlomoNote.swift - Flomo 笔记数据模型
- ✅ DailyNote.swift - 日记数据模型

**服务层** (Services/)
- ✅ FileHandler.swift - 文件处理和 zip 解压
- ✅ HTMLParser.swift - HTML 解析
- ✅ MarkdownConverter.swift - Markdown 转换
- ✅ AttachmentManager.swift - 附件管理
- ✅ ZipGenerator.swift - Zip 文件生成

**视图层** (Views/)
- ✅ WelcomeView.swift - 欢迎页面
- ✅ DateRangeView.swift - 日期选择页面
- ✅ ConvertingView.swift - 转换中页面
- ✅ PreviewView.swift - 预览页面

**应用层** (App/)
- ✅ Flomo2ObsidianApp.swift - 应用入口
- ✅ ContentView.swift - 主视图
- ✅ AppState.swift - 状态管理

**文档**
- ✅ PROJECT_SPEC.md - 项目规格说明
- ✅ UI_DESIGN.md - UI/UX 设计文档
- ✅ IMPLEMENTATION_PLAN.md - 实现计划
- ✅ SETUP_GUIDE.md - 设置指南（本文件）

## 下一步

1. **在 Xcode 中设置项目**
   - 按照上述步骤创建项目
   - 添加依赖库
   - 导入代码文件

2. **测试应用**
   - 使用提供的 flomo@Blink-20260209.zip 测试
   - 验证转换结果
   - 检查 Markdown 格式

3. **优化和完善**
   - 添加应用图标
   - 优化 UI 动画
   - 添加更多错误处理

4. **打包分发**
   - Archive 应用
   - 导出为 .app 文件
   - 分发给用户

## 技术支持

如有问题，请检查：
- Xcode 版本是否符合要求
- 依赖库是否正确安装
- 代码文件是否完整导入
