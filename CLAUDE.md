# QTI Quiz Editor - Architecture Documentation

## Project Overview

A macOS native application for editing Canvas LMS quiz exports in QTI 1.2 format. The app provides both HTML and rich-text editing modes with powerful regex search-and-replace capabilities.

## Target Platform

- **OS**: macOS Sequoia (14.0+)
- **Language**: Swift 6.2.1+
- **Framework**: SwiftUI with AppKit integration
- **Deployment**: Personal use (no App Store requirements)

**NOTE**: You will not be able to compile or test this code base directly on your Linux system. It only works in MacOS. Don't bother installing Swift. Let the user do the testing.

## Programming Princples

1. Always use modern APIs (SwiftUI, Swift Concurrency, Swift regex) when available
2. Don't attempt backward compatibility; don't be afraid to bump up the minimum requirements
3. For the UI: Keep It Simple Stupid (KISS)

## Core Features

### 1. File Operations
- Open Canvas .imscc packages (ZIP files containing QTI XML)
- Extract and parse QTI 1.2 XML content
- Create new QTI quizzes from scratch
- Save modified QTI packages

### 2. Editing Modes
- **HTML Mode**: Direct HTML code editing with syntax highlighting
  - Simple NSTextView-based editor
  - HTML validation and beautification
  - Direct access to raw HTML for regex operations
- **Rich Text Mode**: WYSIWYG editing
  - NSAttributedString-based editing
  - Bidirectional sync with HTML

### 3. Search & Replace
- Simple text search and replace
- **Regex search and replace** (user types patterns as strings, like VSCode)
- Scope options: current question, all questions, specific fields
- Uses Swift's native Regex API internally

### 4. Question Support
- **Primary focus**: Multiple choice questions
- **Universal**: All question types support question text editing
- Future: Additional question type-specific editors

## Technical Architecture

### Guidelines for Concurrency

Key principle: **"MainActor holds the State, Actors do the work, and Structs travel between them,"**

#### 1\. The Separation of Concerns: Actors vs. Values

The most common source of "Sendable conflicts" is the attempt to pass mutable reference types (classes) between threads. To solve this, your architecture must adhere to this rule: **Process logic in Actors, store state in MainActor classes, and communicate using Structs.**

##### What should be `@MainActor`?

In a SwiftUI app, the Main Actor is not just for the View code; it is for the **State that drives the View**.

  * **Views:** Implicitly `@MainActor`.
  * **View Models / UI State:** Explicitly `@MainActor`.
  * **Window/App Delegates:** Implicitly `@MainActor`.

**The Golden Rule:** If a class holds data that `body` reads directly, that class **must** be isolated to the `@MainActor`.

Do not try to make your UI State thread-safe using internal locks or queues. Instead, isolate the whole class to the Main Actor. This ensures that any update to a property (which triggers a UI redraw) happens safely on the main thread, automatically.

#### 2\. Weaving in `@Observable`

The Observation framework (`@Observable`) removes the need for `objectWillChange` and `@Published`. However, because it relies on tracking field access, it is vital that these accesses happen predictably.

**The Strategy:**
Annotate your entire `@Observable` class with `@MainActor`.

```swift
@MainActor
@Observable
class UserProfileViewModel {
    var username: String = ""
    var statistics: UserStats? // A struct, not a class

    // Since this is @MainActor, you can't call this synchronously 
    // from a background thread. You must 'await' it.
    func updateProfile() async {
        // logic
    }
}
```

**Why this fixes conflicts:**
When you annotate a class with `@MainActor`, Swift implicitly makes that class `Sendable`.

- **Why?** Because the compiler guarantees that all properties are only accessed on the Main Thread. Therefore, it is safe to pass a reference to this class to a background task, *provided* that the background task `await`s any calls back into the class.

#### 3\. Handling `Sendable` and Avoiding Conflicts

The "Sendable conflict" usually happens when you try to pass a non-Sendable object (like a plain class) into a `Task` or an `actor`.

Here is how to avoid them in a modern architecture:

##### A. The "Value Boundary" Pattern

Never pass your `@Observable` class *into* a background service to do work. Instead, extract the data needed into a `struct` (Value Type).

**Bad Architecture (Causes Conflict):**

```swift
// Background Actor
actor DataService {
    func process(model: UserProfileViewModel) { ... } // Error: ViewModel is not Sendable (or isolated to MainActor)
}
```

**Correct Architecture (Value Semantics):**

```swift
struct UserInput: Sendable { // Structs are implicitly Sendable
    let name: String
    let age: Int
}

@MainActor
class ViewModel: Observable {
    var state: AppState

    func save() async {
        // 1. Extract data into a Value Type (Snapshot)
        let input = UserInput(name: state.name, age: state.age)
        
        // 2. Pass the Value Type to the background actor
        let result = await databaseActor.save(input)
        
        // 3. Update state with the result (back on MainActor automatically)
        self.state.lastSaved = result.timestamp
    }
}
```

##### B. Services should be `Actors` or `Stateless`

Your heavy lifting (Database, Networking, Image Processing) should not run on the Main Actor.

- **Stateless logic:** Use `structs` with static functions.
- **Stateful logic:** Use `actor` (not `@MainActor class`).

#### Summary of the Blueprint

1. **The UI Layer (`@MainActor`):**

   - SwiftUI Views.
   - `@Observable` classes that store the data for those views.
   - These handle user input and decide *what* needs to be done.

2. **The Transport Layer (Boundaries):**

   - Data are passed between layers using **Structs** and **Enums** only. These are `Sendable` by default.

3. **The Domain Layer (Background / `actor`):**

   - Networking, Database, and heavy computation.
   - These return simple data types (Structs) back to the `@MainActor` to consume.

### Technology Stack

#### Core Technologies

- **Swift Regex**: Modern regex engine for search/replace
  - User inputs patterns as strings (e.g., `<p>(.*?)</p>`)
  - Engine parses and executes using Swift.Regex type
  - Cleaner, safer than NSRegularExpression

- **Swift Concurrency**: async/await throughout
  - `@MainActor` for UI state
  - Background operations for I/O and parsing
  - Swift 6 strict concurrency checking

- **ZIP Handling**: Native compression APIs or ZIPFoundation
  - Extract .imscc packages
  - Parse manifest.xml
  - Access QTI XML files

- **XML Parsing**: Foundation's XMLDocument
  - QTI 1.2 specific parsing
  - Generate valid QTI XML on save

#### UI Framework
- **SwiftUI**: Primary UI framework
- **AppKit Integration**: Where needed (NSTextView for HTML editing)
- **Document-based app architecture**: NSDocument pattern for file management

### Project Structure

```
QtiEditor/
├── App/
│   ├── QtiEditorApp.swift          # SwiftUI App entry point
│   └── AppDelegate.swift           # AppKit delegate if needed
│
├── Models/
│   ├── QTI/
│   │   ├── QTIDocument.swift       # Main document model
│   │   ├── QTIQuestion.swift       # Question model (all types)
│   │   ├── QTIAnswer.swift         # Answer/choice model
│   │   ├── QTIParser.swift         # XML parser for QTI 1.2
│   │   └── QTISerializer.swift     # XML generator
│   └── EditorState.swift           # App state management
│
├── Views/
│   ├── MainWindow/
│   │   ├── ContentView.swift           # Main container view
│   │   ├── QuestionListView.swift      # Sidebar navigation
│   │   ├── QuestionInspectorView.swift # Question metadata & settings (Sidebar)
│   │   ├── RightPanelView.swift        # Utilities panel (Right side)
│   │   └── QuestionHeaderView.swift    # Question top bar
│   │
│   ├── Editors/
│   │   ├── HTMLEditorView.swift    # Code editor for HTML
│   │   ├── RichTextEditorView.swift # WYSIWYG editor
│   │   └── EditorModeToggle.swift  # Switch between modes
│   │
│   └── Search/
│       └── SearchReplaceView.swift # Search UI (text fields for patterns)
│
└── Services/
    ├── IMSCCExtractor.swift        # Extract .imscc ZIP files
    ├── HTMLBeautifier.swift        # Format/validate HTML
    ├── SearchEngine.swift          # Regex search implementation
    └── DocumentManager.swift       # File I/O coordination
```

## QTI 1.2 Format Notes

### Canvas .imscc Package Structure
```
quiz_export.imscc (ZIP file)
├── imsmanifest.xml              # Package manifest
├── assessment_meta.xml          # Quiz settings/metadata
└── [quiz-id]/
    └── assessment.xml           # QTI 1.2 quiz content
```

### Key QTI 1.2 Elements
- `<questestinterop>`: Root element
- `<assessment>`: Quiz container
- `<section>`: Question groups
- `<item>`: Individual question
- `<presentation>`: Question display
- `<response_lid>`: Multiple choice response
- `<resprocessing>`: Answer scoring logic

### Canvas-Specific Extensions
- Canvas may use custom metadata fields
- Store unknown/custom elements to preserve on save

## Data Flow

### Opening a File
1. User selects .imscc file
2. `IMSCCExtractor` extracts ZIP to temp directory (async)
3. `QTIParser` reads and parses XML (async)
4. Build `QTIDocument` model with questions
5. Display in UI (MainActor)

### Editing
1. User modifies content in HTML or Rich Text mode
2. Changes update `QTIQuestion` model
3. Model notifies observers
4. Other views refresh if needed

### Search & Replace
1. User enters pattern (e.g., `<em>(.*?)</em>`) and replacement in text fields
2. `SearchEngine` compiles Swift.Regex from string pattern
3. Execute search across selected scope
4. Present matches to user
5. Apply replacements to model
6. Update views

### Saving
1. `QTISerializer` generates QTI 1.2 XML from model
2. Create .imscc package structure
3. ZIP files together
4. Write to disk (async)

## Development Principles

### Swift 6 Concurrency
- All I/O operations are async
- UI updates on `@MainActor`
- Use actors for shared mutable state
- Leverage strict concurrency checking

### Error Handling
- Typed errors for each domain (Parsing, File I/O, etc.)
- User-friendly error messages
- Graceful degradation (preserve unrecognized QTI elements)

### Testing Strategy
- Unit tests for QTI parser/serializer
- Unit tests for search engine
- Integration tests for document operations
- UI tests for critical workflows

### Code Organization
- Models are pure Swift (no UIKit/AppKit dependencies)
- Services are reusable and testable
- Views are thin, delegate to view models
- Clear separation of concerns

## Future Considerations

### Possible Enhancements
- Support for additional question types (true/false, essay, matching, etc.)
- Question import/export (individual questions)
- Templates for common question patterns
- Undo/redo support
- Multiple document windows
- Find in files across multiple quizzes
- Preview mode (how quiz appears in Canvas)
- Bulk operations across questions

### Performance
- Lazy loading for large quizzes
- Incremental parsing
- Efficient regex compilation (cache compiled patterns)

## Dependencies

### Potential Third-Party Libraries
- **HTML Tidying**: Consider HTMLTidy or swift-html-beautifier
- **ZIP**: Apple's native compression or ZIPFoundation
- **Syntax Highlighting**: Build simple highlighter or use lightweight library

Keep dependencies minimal for maintainability.

## Development Workflow

### Setting Up the Project (macOS Development)
1. Create Xcode project on macOS
2. Configure for macOS Sequoia target
3. Enable Swift 6 strict concurrency
4. Set up project structure as outlined above

### Building
- **macOS**: Standard Xcode build (Cmd+B)
- Run tests (Cmd+U on macOS)
- Personal code signing for local use (macOS only)

### Version Control
- Git repository with clear commit messages
- Branch: `claude/add-swift-toolchain-01LkaopkvPD4NGbgG7RviEdC`
- Regular commits as features are implemented

## Questions & Decisions Log

### Decision: Swift Regex vs NSRegularExpression
**Choice**: Swift's native Regex
**Rationale**: Type-safe, modern, better error messages, performance

### Decision: Concurrency Model
**Choice**: Swift async/await with actors
**Rationale**: Swift 6 best practices, prevents data races

### Decision: HTML Editor Complexity
**Choice**: Simple NSTextView with basic highlighting
**Rationale**: Focus on search/replace functionality, not complex IDE features

### Decision: File Format
**Choice**: Support .imscc packages (not just raw XML)
**Rationale**: Match Canvas export format exactly

## Contact & Maintenance

This is a personal-use tool. Architecture designed for:
- Easy understanding and modification
- Minimal dependencies
- Clear, maintainable code
- Extensibility for future features
