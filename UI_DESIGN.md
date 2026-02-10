# Flomo to Obsidian Converter - UI Design

## Design System

### Typography
- **Title**: SF Pro Display, 24pt, Semibold
- **Heading**: SF Pro Text, 18pt, Medium
- **Body**: SF Pro Text, 14pt, Regular
- **Caption**: SF Pro Text, 12pt, Regular

### Spacing
- **XS**: 4px
- **S**: 8px
- **M**: 16px
- **L**: 24px
- **XL**: 32px
- **XXL**: 48px

### Colors (Light Mode)
- **Background**: #FFFFFF
- **Secondary Background**: #F5F5F7
- **Text Primary**: #1D1D1F
- **Text Secondary**: #86868B
- **Border**: #D2D2D7
- **Accent**: System Accent (user preference)

### Colors (Dark Mode)
- **Background**: #1C1C1E
- **Secondary Background**: #2C2C2E
- **Text Primary**: #F5F5F7
- **Text Secondary**: #98989D
- **Border**: #38383A
- **Accent**: System Accent (user preference)

## Screen 1: Welcome Screen

### Layout
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│         📦                          │
│                                     │
│   Drop Flomo export here            │
│   or click to select                │
│                                     │
│   ┌─────────────────┐              │
│   │  Select File    │              │
│   └─────────────────┘              │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

### Specifications
- Window size: 600x400px
- Drop zone: 400x200px, centered
- Icon: SF Symbol "doc.zipper", 48pt
- Text: 16pt, Secondary color
- Button: 140x36px, Accent color
- Corner radius: 8px

## Screen 2: Date Range Selection

### Layout
```
┌─────────────────────────────────────┐
│  Select Date Range                  │
│                                     │
│  Found 50 notes                     │
│  from 2025-12-28 to 2026-01-30     │
│                                     │
│  ┌─────────────┐  ┌─────────────┐ │
│  │ Start Date  │  │  End Date   │ │
│  │ 2025-12-28  │  │ 2026-01-30  │ │
│  └─────────────┘  └─────────────┘ │
│                                     │
│  ☑ Select All                      │
│                                     │
│  ┌────────┐  ┌────────┐           │
│  │ Cancel │  │Convert │           │
│  └────────┘  └────────┘           │
└─────────────────────────────────────┘
```

### Specifications
- Window size: 600x450px
- Title: 24pt, Semibold
- Info text: 14pt, Secondary color
- Date pickers: Native macOS style
- Checkbox: 14pt
- Buttons: 100x36px
- Spacing: 24px between elements

## Screen 3: Converting

### Layout
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│            ⏳                       │
│                                     │
│      Converting notes...            │
│                                     │
│      Processing 25 of 50            │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

### Specifications
- Window size: 600x400px
- Spinner: Native macOS activity indicator
- Text: 16pt, centered
- Progress text: 14pt, Secondary color
- Smooth animation

## Screen 4: Preview

### Layout
```
┌─────────────────────────────────────┐
│  Preview Converted Notes            │
│                                     │
│  8 daily notes created              │
│  (2025-12-28 to 2026-01-30)        │
│                                     │
│  ┌─────────────────────────────┐  │
│  │ 📄 2025-12-28.md            │  │
│  │ 📄 2025-12-29.md            │  │
│  │ 📄 2026-01-05.md            │  │
│  │ 📄 2026-01-10.md            │  │
│  │ 📄 2026-01-13.md            │  │
│  │ 📄 2026-01-23.md            │  │
│  │ 📄 2026-01-28.md            │  │
│  │ 📄 2026-01-30.md            │  │
│  └─────────────────────────────┘  │
│                                     │
│  ┌────────┐  ┌────────┐           │
│  │  Back  │  │ Export │           │
│  └────────┘  └────────┘           │
└─────────────────────────────────────┘
```

### Specifications
- Window size: 600x500px
- List: Scrollable, 300px height
- List items: 40px height, hover effect
- Click to preview markdown content
- Buttons: 100x36px

## Interaction States

### Hover States
- Buttons: Slight opacity change (0.8)
- Drop zone: Border color changes to Accent
- List items: Background changes to Secondary Background

### Active States
- Buttons: Scale down slightly (0.98)
- Date pickers: Native macOS focus ring

### Loading States
- Spinner: Native macOS activity indicator
- Progress text: Updates in real-time
- Disable all interactive elements during processing

## Animations

### Transitions
- Screen transitions: Fade + slide (0.3s ease-in-out)
- Button hover: 0.2s ease
- List item hover: 0.15s ease

### Loading
- Spinner: Continuous rotation
- Progress text: Fade in/out when updating

## Accessibility

### VoiceOver Support
- All buttons have clear labels
- Drop zone announces "Drop Flomo export file here"
- Progress updates announced during conversion
- List items announce filename and date

### Keyboard Navigation
- Tab through all interactive elements
- Enter/Space to activate buttons
- Arrow keys to navigate list
- Cmd+O to open file picker
- Esc to cancel/go back

## Error States

### Invalid File
```
┌─────────────────────────────────────┐
│         ⚠️                          │
│                                     │
│   Invalid Flomo export file         │
│   Please select a valid .zip file   │
│                                     │
│   ┌─────────────────┐              │
│   │   Try Again     │              │
│   └─────────────────┘              │
└─────────────────────────────────────┘
```

### No Notes Found
```
┌─────────────────────────────────────┐
│         ℹ️                          │
│                                     │
│   No notes found in date range      │
│   Please select a different range   │
│                                     │
│   ┌─────────────────┐              │
│   │      Back       │              │
│   └─────────────────┘              │
└─────────────────────────────────────┘
```

## Design Principles Applied

### 1. Minimalism
- Clean, uncluttered layouts
- Ample white space
- Focus on essential elements only
- No unnecessary decorations

### 2. Native macOS Feel
- SF Pro font family
- System colors and accent
- Native UI controls (date pickers, buttons)
- Standard window chrome

### 3. Fast & Responsive
- Instant visual feedback
- Smooth animations (< 0.3s)
- Progress indicators for long operations
- No blocking operations

### 4. Clear Hierarchy
- Large titles for context
- Secondary text for details
- Visual grouping of related elements
- Consistent spacing system
