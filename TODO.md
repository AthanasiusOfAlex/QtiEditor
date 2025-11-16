# QTI Quiz Editor - Implementation Roadmap

## Project Status: Foundation Phase

This document tracks the implementation progress of the QTI Quiz Editor.

---

## Phase 0: Project Setup ✅

- [x] Create project directory structure
- [x] Create CLAUDE.md architecture documentation
- [x] Create TODO.md roadmap
- [ ] Create Xcode project on macOS
  - [ ] Set up macOS app target (macOS 14.0+)
  - [ ] Configure Swift 6.2.1+ with strict concurrency
  - [ ] Set up code signing for personal use
  - [ ] Add .gitignore for Xcode/Swift

---

## Phase 1: Core Data Models

### QTI Data Structures
- [ ] `QTIDocument.swift` - Main document model
  - [ ] Quiz metadata (title, description, settings)
  - [ ] Collection of questions
  - [ ] Observable/Published properties for SwiftUI
  - [ ] Sendable conformance for Swift 6 concurrency

- [ ] `QTIQuestion.swift` - Question model
  - [ ] Question types enum (multiple_choice, essay, etc.)
  - [ ] Question text (HTML stored as String)
  - [ ] Question metadata (points, difficulty, etc.)
  - [ ] Answers collection
  - [ ] Universal editing support for all types
  - [ ] Focus on multiple choice initially

- [ ] `QTIAnswer.swift` - Answer/choice model
  - [ ] Answer text (HTML)
  - [ ] Correct/incorrect flag
  - [ ] Feedback text (optional)
  - [ ] Weight/points (for partial credit)

### Editor State
- [ ] `EditorState.swift` - App state management
  - [ ] Current document reference
  - [ ] Selected question
  - [ ] Editor mode (HTML vs Rich Text)
  - [ ] Search state
  - [ ] Use `@MainActor` for UI safety

---

## Phase 2: File Operations & QTI Parsing

### IMSCC Package Handling
- [ ] `IMSCCExtractor.swift` - ZIP extraction service
  - [ ] Async extract .imscc files
  - [ ] Parse imsmanifest.xml
  - [ ] Locate QTI assessment files
  - [ ] Extract to temp directory
  - [ ] Clean up temp files on close

### QTI 1.2 XML Parsing
- [ ] `QTIParser.swift` - XML to model conversion
  - [ ] Parse `<questestinterop>` root
  - [ ] Parse `<assessment>` quiz metadata
  - [ ] Parse `<item>` questions
  - [ ] Parse `<response_lid>` multiple choice
  - [ ] Parse `<presentation>` question HTML
  - [ ] Parse `<resprocessing>` scoring logic
  - [ ] Handle Canvas-specific extensions
  - [ ] Preserve unknown elements (for round-trip)
  - [ ] Async operation with error handling

- [ ] `QTISerializer.swift` - Model to XML conversion
  - [ ] Generate valid QTI 1.2 XML
  - [ ] Create .imscc package structure
  - [ ] ZIP package files
  - [ ] Async save operation
  - [ ] Preserve Canvas extensions

### Document Management
- [ ] `DocumentManager.swift` - File coordination
  - [ ] New document creation
  - [ ] Open existing .imscc
  - [ ] Save/Save As operations
  - [ ] Track document dirty state
  - [ ] Auto-save support (optional)

---

## Phase 3: Search & Replace Engine

### Core Search Engine
- [ ] `SearchEngine.swift` - Regex search implementation
  - [ ] Parse user regex strings into Swift.Regex
  - [ ] Handle regex compilation errors gracefully
  - [ ] Simple text search (non-regex mode)
  - [ ] Regex search with Swift's Regex API
  - [ ] Search scopes:
    - [ ] Current question only
    - [ ] All questions
    - [ ] Question text only
    - [ ] Answer text only
    - [ ] All text fields
  - [ ] Return match locations and context
  - [ ] Replace operations (single and replace-all)
  - [ ] Preserve HTML structure during replace

### Search UI
- [ ] `SearchReplaceView.swift` - Search interface
  - [ ] Pattern input field (text)
  - [ ] Replacement input field (text)
  - [ ] Regex toggle (enable/disable regex mode)
  - [ ] Case sensitivity toggle
  - [ ] Scope selector
  - [ ] Find Next/Previous buttons
  - [ ] Replace/Replace All buttons
  - [ ] Match counter
  - [ ] Error display for invalid regex

---

## Phase 4: User Interface

### Main Window Structure
- [ ] `QtiEditorApp.swift` - App entry point
  - [ ] SwiftUI App structure
  - [ ] Window configuration
  - [ ] Menu bar commands (New, Open, Save, etc.)

- [ ] `ContentView.swift` - Main layout
  - [ ] Three-pane layout (Sidebar, Editor, Inspector)
  - [ ] Toolbar with common actions
  - [ ] Editor mode toggle
  - [ ] Search panel toggle

- [ ] `QuestionListView.swift` - Question navigator (Sidebar)
  - [ ] List all questions
  - [ ] Question preview/summary
  - [ ] Add/delete question buttons
  - [ ] Reorder questions (drag & drop)
  - [ ] Question type indicators

- [ ] `InspectorView.swift` - Metadata panel
  - [ ] Question settings (points, type, etc.)
  - [ ] Quiz metadata when no question selected
  - [ ] Conditional display based on selection

### Editor Views
- [ ] `EditorModeToggle.swift` - Mode switcher
  - [ ] Segmented control (HTML / Rich Text)
  - [ ] Update state on change
  - [ ] Warning when switching modes

- [ ] `HTMLEditorView.swift` - HTML code editor
  - [ ] NSTextView integration with SwiftUI
  - [ ] Basic syntax highlighting
    - [ ] HTML tags
    - [ ] Attributes
    - [ ] Text content
  - [ ] Line numbers (optional)
  - [ ] Monospace font
  - [ ] Bind to question HTML
  - [ ] Validate HTML button
  - [ ] Beautify HTML button

- [ ] `RichTextEditorView.swift` - WYSIWYG editor
  - [ ] NSTextView with rich text editing
  - [ ] HTML to NSAttributedString conversion
  - [ ] NSAttributedString to HTML conversion
  - [ ] Bidirectional sync with model
  - [ ] Formatting toolbar (bold, italic, lists, etc.)
  - [ ] Handle common HTML elements

### Supporting Services
- [ ] `HTMLBeautifier.swift` - HTML formatting
  - [ ] Pretty-print HTML
  - [ ] Validate HTML structure
  - [ ] Fix common issues
  - [ ] Consider HTMLTidy integration

---

## Phase 5: Polish & Testing

### User Experience
- [ ] Error handling and user feedback
  - [ ] Alert dialogs for errors
  - [ ] Progress indicators for async operations
  - [ ] Validation messages
- [ ] Keyboard shortcuts
  - [ ] Cmd+F for search
  - [ ] Cmd+S for save
  - [ ] Cmd+N for new question
  - [ ] Cmd+Delete for delete question
- [ ] Preferences/Settings (if needed)
- [ ] Help menu with basic documentation

### Testing
- [ ] Unit tests for QTIParser
  - [ ] Parse sample Canvas QTI files
  - [ ] Handle malformed XML
  - [ ] Preserve unknown elements
- [ ] Unit tests for QTISerializer
  - [ ] Round-trip test (parse → serialize → parse)
  - [ ] Validate generated XML
- [ ] Unit tests for SearchEngine
  - [ ] Simple text search
  - [ ] Regex patterns
  - [ ] Replace operations
  - [ ] Edge cases
- [ ] Integration tests
  - [ ] Open .imscc → Edit → Save
  - [ ] Create new → Add questions → Save
- [ ] Manual testing with real Canvas exports

### Documentation
- [ ] README.md with usage instructions
- [ ] Sample QTI files for testing
- [ ] Known limitations document

---

## Phase 6: Future Enhancements

These are potential features for future development:

### Additional Question Types
- [ ] True/False editor
- [ ] Essay question editor
- [ ] Fill-in-the-blank editor
- [ ] Matching question editor
- [ ] Multiple answers (select all that apply)
- [ ] Numeric answer questions

### Advanced Features
- [ ] Question templates
- [ ] Question bank/library
- [ ] Import questions from other formats
- [ ] Export individual questions
- [ ] Bulk operations (apply changes to multiple questions)
- [ ] Find and replace across multiple files
- [ ] Canvas preview mode
- [ ] Diff view (compare before/after)
- [ ] Version history

### Quality of Life
- [ ] Undo/redo support
- [ ] Multiple document windows
- [ ] Split editor view
- [ ] Customizable keyboard shortcuts
- [ ] Dark mode support
- [ ] Export to other formats (PDF, Markdown, etc.)
- [ ] Statistics (question count, average difficulty, etc.)

---

## Development Notes

### Next Session Goals
When resuming development, prioritize:
1. Create Xcode project (requires macOS environment)
2. Implement core data models (Phase 1)
3. Set up basic UI structure (Phase 4 basics)
4. Implement QTI parser for multiple choice (Phase 2)

### Technical Decisions Made
- **Regex**: Swift native Regex API (not NSRegularExpression)
- **Concurrency**: async/await with Swift 6 strict checking
- **HTML Editor**: Simple NSTextView (not web-based editor)
- **File Format**: Full .imscc package support
- **QTI Version**: 1.2 (Canvas standard)

### Dependencies to Consider
- ZIP handling: Native compression or ZIPFoundation pod/package
- HTML Tidy: For beautification (evaluate if needed)
- Syntax highlighting: Build simple custom solution first

### Testing Approach
- Create sample .imscc files from Canvas exports
- Test with real quiz data
- Focus on data integrity (round-trip preservation)

---

## Quick Start for Future Sessions

```bash
# Build the project
open QtiEditor.xcodeproj
# Cmd+B to build

# Run tests
# Cmd+U

# Run the app
# Cmd+R
```

### Key Files Reference
- Architecture: `CLAUDE.md`
- Main app: `QtiEditor/App/QtiEditorApp.swift`
- Models: `QtiEditor/Models/QTI/`
- Views: `QtiEditor/Views/`
- Services: `QtiEditor/Services/`

---

*Last updated: 2025-11-16*
*Current phase: Phase 0 - Project Setup*
