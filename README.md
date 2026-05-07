# Flomo2Obsidian

<div align="center">

**将你的 Flomo 笔记无缝转换为 Obsidian 格式**

一个轻量化的 macOS 应用，帮助你将 Flomo 的闪念笔记迁移到 Obsidian 知识库

🔒 **100% 离线处理 · 数据安全无忧**

[![下载最新版本](https://img.shields.io/github/v/release/iBlinkQ/flomo2obsidian?label=下载&style=for-the-badge&color=00C853)](https://github.com/iBlinkQ/flomo2obsidian/releases/latest)
<img width="1800" height="1504" alt="e006d184bbfa9b03f8a22a85415c902d" src="https://github.com/user-attachments/assets/3df5e7ca-de3f-487e-8f9c-1c495e2bd147" />
<img width="900" height="752" alt="image" src="https://github.com/user-attachments/assets/ed31af60-2893-49e4-b0e3-35f2669328c5" />

</div>

---

## 功能特性

- 🔒 **100% 离线处理** - 所有数据转换均在本地完成，不会上传到任何服务器，保障笔记隐私安全
- 📦 **一键导入** - 支持拖拽或选择 Flomo 导出的 ZIP 文件
- 📅 **灵活的日期筛选** - 自由选择需要转换的笔记时间范围
- 📝 **两种导出模式** - 支持「按天合并」和「按卡片独立」两种导出方式，适配不同笔记管理习惯
- 🏷️ **Frontmatter 支持** - 自动生成 `created` 和 `noteType` 等元数据，便于 Obsidian 检索和管理
- 🖼️ **附件支持** - 自动处理并导出图片和语音（M4A）附件文件，语音以 Obsidian Callout 格式展示，并保留 Flomo 的语音转文字文本
- 👀 **实时预览** - 转换前可预览 Markdown 格式的笔记内容
- ⚡ **快速高效** - 原生 SwiftUI 开发，性能优异

## 隐私安全

**你的笔记，只属于你自己**

Flomo2Obsidian 是一个完全离线的本地应用，我们深知笔记内容的私密性和重要性：

- ✅ **零网络传输** - 所有数据处理均在你的 Mac 本地完成
- ✅ **无服务器交互** - 不会连接任何远程服务器，不会上传任何数据
- ✅ **无数据收集** - 不收集、不存储、不分析你的任何笔记内容
- ✅ **开源透明** - 代码完全开源，欢迎审查和验证
- ✅ **本地存储** - 转换后的文件保存在你指定的本地位置

**工作原理：**
1. 你选择 Flomo 导出的 ZIP 文件
2. 应用在本地解压并解析文件
3. 在本地内存中完成格式转换
4. 生成新的 .md 和附件文件，保存到你的 Obsidian Vault 相应位置
5. 整个过程不涉及任何网络请求

> 💡 **提示**：你可以在完全断网的情况下使用本应用，功能不受任何影响。

## 安装使用

### 系统要求

- macOS 15.0 (Sequoia) 或更高版本
- 从 Flomo 导出的 ZIP 文件

### 安装步骤

1. 下载最新版本的 Flomo2Obsidian.app
2. 将应用拖入「应用程序」文件夹

### 首次打开应用

由于应用未经过 Apple 公证，macOS 会显示安全警告。请按以下步骤操作：

**方法一：右键打开（推荐）**

1. 右键点击（或按住 Control 点击）Flomo2Obsidian.app
2. 在菜单中选择「打开」
3. 在弹出的对话框中再次点击「打开」
4. 之后可以正常双击启动应用

**方法二：使用终端命令**

在终端中运行以下命令移除隔离属性：

```bash
xattr -cr /Applications/Flomo2Obsidian.app
```

> 💡 **说明**：这个安全警告是 macOS Gatekeeper 的保护机制。应用代码完全开源，你可以随时审查源代码以确保安全性。

## 使用指南

### 第一步：导出 Flomo 笔记

1. 登录 Flomo 
2. 点击「个人昵称」展开下拉菜单
3. 选择「导出/导入笔记」-「导出笔记」-「导出」
4. 下载生成的 ZIP 文件

### 第二步：导入并转换

1. **启动应用**
   - 打开 Flomo2Obsidian
   - 你会看到欢迎界面，可以拖拽 ZIP 文件或点击按钮选择文件

2. **选择日期范围和导出模式**
   - 应用会自动识别笔记的时间跨度
   - 你可以自定义起止日期，或选择「全选」导出所有笔记
   - 选择导出模式：
     - **按天导出** - 同一天的笔记合并到一个文件中（如 `2026-03-03.md`）
     - **按卡片导出** - 每条笔记独立生成一个文件，文件名取自笔记首行内容
   - 界面会显示发现的笔记总数

3. **转换处理**
   - 点击「转换为 Obsidian」按钮
   - 应用会显示转换进度
   - 转换完成后自动进入预览界面

4. **预览与导出**
   - 浏览生成的笔记列表
   - 点击任意笔记可预览 Markdown 内容
   - 确认无误后点击「Export to Obsidian」
   - 导出过程中按钮会显示加载动画
   - 选择保存位置，生成带日期的 `obsidian-notes-YYYY-MM-DD.zip` 文件

### 第三步：导入 Obsidian

1. 解压生成的 `obsidian-notes-YYYY-MM-DD.zip` 文件
2. 将解压后的文件复制到你的 Obsidian 库中
3. 在 Obsidian 中即可看到转换后的笔记

## 技术栈

- **SwiftUI** - 现代化的 UI 框架
- **Combine** - 响应式编程
- **Foundation** - 文件处理和数据解析
- **HTML Parser** - 解析 Flomo 导出的 HTML 格式
- **Markdown Generator** - 生成 Obsidian 兼容的 Markdown 文件

## 📝 笔记格式说明

### 按天导出

每个文件对应一天的笔记，文件名格式：`YYYY-MM-DD.md`

```markdown
---
created: 2026-03-03
noteType: CardNote
---

# 笔记首行内容（超20字截断...

笔记完整内容（含首行）...

> [!tip]+ 语音
> ![[audio_record_watch_xxx.m4a]]
> 语音转文字文本内容（若有）...

![](Attachments/image.jpg)

---

# 另一条笔记标题

另一条笔记完整内容...
```

- 每条笔记的首行作为一级标题，超过 20 字自动截断并显示 `...`
- 标题下方展示笔记完整内容（包含首行）
- 包含 Frontmatter 元数据（`created`、`noteType`）
- 同一天的多条笔记以 `---` 分隔
- 笔记按时间顺序排列

### 按卡片导出

每条笔记独立生成一个文件，文件名取自笔记首行（最多 20 字）

```markdown
---
created: 2026-03-03 14:30:00
noteType: CardNote
---

笔记完整内容...

> [!tip]+ 语音
> ![[audio_record_watch_xxx.m4a]]
> 语音转文字文本内容（若有）...

![](Attachments/image.jpg)
```

- 文件名自动清理非法字符，重名时自动编号
- 包含 Frontmatter 元数据（精确到秒的创建时间）

### 通用

- 附件（图片、语音 M4A）统一保存在 `Attachments` 文件夹中
- 语音以 `> [!tip]+ 语音` Callout 格式呈现，紧接正文内容之后、图片之前
- 语音 Callout 包含嵌入的音频文件和 Flomo 的语音转文字原文（无转文字时仅保留音频链接）
- 有序列表、无序列表等格式完整保留

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 开源协议

本项目采用 MIT 协议开源。

## 💝 致谢

感谢 Flomo 和 Obsidian 两个优秀的笔记工具，让知识管理变得更加美好。

---

<div align="center">

**Crafted with ❤️ by iBlinkQ**

将闪念转化为持久的知识

</div>
