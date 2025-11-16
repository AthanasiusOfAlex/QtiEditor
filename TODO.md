# QTI Quiz Editor - Implementation Roadmap

## Project Status: Foundation Phase

This document tracks the implementation progress of the QTI Quiz Editor.

---

## Phase 0: Project Setup ✅

- [x] Create project directory structure
- [x] Create CLAUDE.md architecture documentation
- [x] Create TODO.md roadmap
- [x] Create Xcode project on macOS
  - [x] Set up macOS app target (macOS 14.0+)
  - [x] Configure Swift 6.2.1+ with strict concurrency
  - [x] Set up code signing for personal use
  - [x] Add .gitignore for Xcode/Swift
  - [x] Configure entitlements for file access

---

## Phase 1: Core Data Models ✅

### QTI Data Structures
- [x] `QTIDocument.swift` - Main document model
  - [x] Quiz metadata (title, description, settings)
  - [x] Collection of questions
  - [x] @Observable macro for SwiftUI
  - [x] Sendable conformance for Swift 6 concurrency
  - [x] @MainActor isolation

- [x] `QTIQuestion.swift` - Question model
  - [x] Question types enum (all QTI types supported)
  - [x] Question text (HTML stored as String)
  - [x] Question metadata (points, title, identifier)
  - [x] Answers collection
  - [x] Universal editing support for all types
  - [x] Multiple choice fully supported

- [x] `QTIAnswer.swift` - Answer/choice model
  - [x] Answer text (HTML)
  - [x] Correct/incorrect flag
  - [x] Feedback text (optional)
  - [x] Weight/points (for partial credit)

### Editor State
- [x] `EditorState.swift` - App state management
  - [x] Current document reference
  - [x] Selected question
  - [x] Editor mode (HTML vs Rich Text) - state only, views pending
  - [x] Search state (pattern, scope, field)
  - [x] File operation methods
  - [x] Use `@MainActor` for UI safety

---

## Phase 2: File Operations & QTI Parsing ✅

### IMSCC Package Handling
- [x] `IMSCCExtractor.swift` - ZIP extraction service (actor-based)
  - [x] Async extract .imscc files using system zip/unzip
  - [x] Parse imsmanifest.xml
  - [x] Locate QTI assessment files
  - [x] Extract to temp directory
  - [x] Create .imscc packages for saving
  - [x] Fixed permission issues with TMPDIR workaround

### QTI 1.2 XML Parsing
- [x] `QTIParser.swift` - XML to model conversion
  - [x] Parse `<questestinterop>` root
  - [x] Parse `<assessment>` quiz metadata
  - [x] Parse `<item>` questions
  - [x] Parse `<response_lid>` multiple choice responses
  - [x] Parse `<presentation>` question HTML (with mattext)
  - [x] Parse `<resprocessing>` scoring logic
  - [x] Handle Canvas-specific extensions (metadata preservation)
  - [x] Preserve unknown elements for round-trip fidelity
  - [x] Async operation with typed error handling

- [x] `QTISerializer.swift` - Model to XML conversion
  - [x] Generate valid QTI 1.2 XML
  - [x] Create complete .imscc package structure
  - [x] Generate imsmanifest.xml with proper resource references
  - [x] ZIP package files
  - [x] Async save operation
  - [x] Preserve Canvas extensions

### Document Management
- [x] `DocumentManager.swift` - File coordination
  - [x] New document creation
  - [x] Open existing .imscc files
  - [x] Save/Save As operations
  - [x] Proper error propagation
  - [x] QTIError.swift - Typed errors for all file operations
  - [ ] Track document dirty state (future enhancement)
  - [ ] Auto-save support (future enhancement)

---

## Phase 3: Search & Replace Engine ✅

### Core Search Engine
- [x] `SearchEngine.swift` - Regex search implementation
  - [x] Parse user regex strings using NSRegularExpression
  - [x] Handle regex compilation errors gracefully with SearchError
  - [x] Simple text search (non-regex mode)
  - [x] Regex search with NSRegularExpression (not Swift.Regex*)
  - [x] Search scopes:
    - [x] Current question only
    - [x] All questions
    - [x] Question text only
    - [x] Answer text only
    - [x] Feedback text only
    - [x] All text fields
  - [x] Return match locations and context with HTML stripping
  - [x] Replace operations (single match and replace-all)
  - [x] Full capture group support ($0, $1, $2, etc.)
  - [x] Case-sensitive/insensitive toggle
  - [x] Preserve HTML structure during replace

### Search Data Models
- [x] `SearchResult.swift` - Search data structures
  - [x] SearchMatch struct with context
  - [x] SearchScope enum
  - [x] SearchField enum

### Search UI
- [x] `SearchReplaceView.swift` - VSCode-style search interface
  - [x] Pattern input field (text)
  - [x] Replacement input field (text)
  - [x] Regex toggle (enable/disable regex mode)
  - [x] Case sensitivity toggle
  - [x] Scope selector (current/all questions)
  - [x] Field selector (question/answer/feedback/all)
  - [x] Find Next/Previous buttons with navigation
  - [x] Replace button (one-by-one replacement)
  - [x] Replace All button
  - [x] Match counter (X/Y format)
  - [x] Results list with click-to-navigate
  - [x] Resizable results panel (drag handle)
  - [x] Match highlighting in results (orange, yellow when selected)
  - [x] Match highlighting in editor (orange background)
  - [x] Auto-focus search field on Cmd+F
  - [x] Error display for invalid regex

*Note: Changed from Swift.Regex to NSRegularExpression for consistent behavior and full regex template support

---

## Phase 4: User Interface (In Progress)

### Main Window Structure
- [x] `QtiEditorApp.swift` - App entry point
  - [x] SwiftUI App structure
  - [x] Window configuration
  - [x] Menu bar commands (New, Open, Save, Save As)
  - [x] Keyboard shortcuts (Cmd+N, Cmd+O, Cmd+S, Cmd+Shift+S)
  - [x] Sample data for development
  - [x] EditorState environment injection

- [x] `ContentView.swift` - Main layout
  - [x] NavigationSplitView three-pane layout
  - [x] Collapsible search panel (Cmd+F)
  - [x] Loading overlay for async operations
  - [x] Error alert display
  - [x] Question display with HTML stripping
  - [x] Answer list display
  - [x] Search match highlighting in question/answers
  - [ ] Toolbar with common actions
  - [ ] Inspector pane integration

- [x] `QuestionListView.swift` - Question navigator (Sidebar)
  - [x] List all questions
  - [x] Question preview/summary
  - [x] Selection binding
  - [ ] Add/delete question buttons
  - [ ] Reorder questions (drag & drop)
  - [ ] Question type indicators

- [ ] `InspectorView.swift` - Metadata panel
  - [ ] Question settings (points, type, etc.)
  - [ ] Quiz metadata when no question selected
  - [ ] Conditional display based on selection

### Editor Views (Not Yet Implemented)
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
- **Regex**: NSRegularExpression (changed from Swift.Regex for full template support)
  - Search uses NSRegularExpression with case-insensitive option support
  - Replace uses NSRegularExpression template engine for $0, $1, $2, etc.
  - User enters patterns as plain strings (VSCode-style)
- **Concurrency**: async/await with Swift 6 strict checking
  - @MainActor for UI-bound state and operations
  - actor for IMSCCExtractor to isolate file operations
  - nonisolated for system command wrappers
- **State Management**: @Observable macro (not @ObservableObject)
- **HTML Editor**: Simple NSTextView (not web-based editor) - TBD
- **File Format**: Full .imscc package support with manifest generation
- **QTI Version**: 1.2 (Canvas standard)
- **ZIP Handling**: System zip/unzip commands with TMPDIR workaround for permissions

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

## Recent Accomplishments (2025-11-16)

### Search & Replace Engine
- Implemented complete regex search with capture group support ($0, $1, $2, etc.)
- Fixed regex parsing issue (switched from Swift.Regex to NSRegularExpression)
- Added auto-focus to search field when opening with Cmd+F
- Implemented resizable results panel with drag handle
- Added match highlighting in both results and editor views
- Implemented one-by-one replace functionality
- Added navigation between matches with Previous/Next buttons
- Match counter displays current position (X/Y format)

### File Operations
- Complete .imscc package extraction and creation
- QTI 1.2 XML parsing for multiple choice questions
- Round-trip preservation of Canvas metadata
- Fixed macOS permission issues with ZIP operations
- Proper async/await throughout with Swift 6 concurrency

### UI Foundation
- Three-pane NavigationSplitView layout
- Collapsible search panel
- Question list sidebar with selection
- Question display with HTML stripping
- File menu commands (New, Open, Save, Save As)
- Loading states and error handling

---

*Last updated: 2025-11-16*
*Current phase: Phase 4 - User Interface (Editor Views)*
*Status: Foundation complete, search/replace fully functional, ready for editor views*
