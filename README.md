# QTI Quiz Editor

A macOS native application for editing Canvas LMS quiz exports in QTI 1.2 format.

## Overview

Canvas LMS exports quizzes as `.imscc` packages (ZIP files containing QTI XML). While Canvas provides a web-based quiz editor, it lacks certain power-user features like regex search-and-replace and easy bulk editing. This native macOS app fills that gap.

## Features

- **Open and edit Canvas .imscc quiz packages**
- **Dual editing modes**:
  - HTML mode: Direct code editing with syntax highlighting
  - Rich Text mode: WYSIWYG editing
- **Powerful search and replace**:
  - Simple text search
  - Regular expression search and replace (like VSCode)
  - Search across all questions or specific fields
- **Question support**:
  - Primary focus: Multiple choice questions
  - Universal question text editing for all types
- **Create new quizzes from scratch**
- **Export modified quizzes as .imscc packages**

## Requirements

- macOS Sequoia (14.0) or later
- Xcode 15+ with Swift 6.2.1+

## Project Status

Currently in **foundation phase**. See [TODO.md](TODO.md) for the implementation roadmap.

## Architecture

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Getting Started

### Setting Up Development Environment

1. Clone this repository
2. Open `QtiEditor.xcodeproj` in Xcode (to be created)
3. Build and run (Cmd+R)

### Usage (When Implemented)

1. **Open a quiz**: File → Open, select a Canvas `.imscc` export
2. **Edit questions**: Select a question from the sidebar, edit in HTML or Rich Text mode
3. **Search and replace**: Cmd+F to open search, enter patterns and replacements
4. **Save**: File → Save to create a new `.imscc` package

## Technology Stack

- **Language**: Swift 6.2.1+
- **UI**: SwiftUI with AppKit integration
- **Concurrency**: Swift async/await
- **Regex**: Swift native Regex API
- **XML**: Foundation XMLDocument
- **ZIP**: Native compression or ZIPFoundation

## Development

### Project Structure

```
QtiEditor/
├── App/              # Application entry point
├── Models/           # Data models (QTI structures)
├── Views/            # SwiftUI views
├── Services/         # Business logic (parsing, search, file I/O)
├── Resources/        # Assets and resources
└── QtiEditorTests/   # Unit and integration tests
```

### Building

```bash
# Open in Xcode
open QtiEditor.xcodeproj

# Or build from command line
xcodebuild -project QtiEditor.xcodeproj -scheme QtiEditor build
```

### Testing

```bash
# Run tests in Xcode: Cmd+U

# Or from command line
xcodebuild test -project QtiEditor.xcodeproj -scheme QtiEditor
```

## QTI 1.2 Format

Canvas uses QTI 1.2 (IMS Question & Test Interoperability) as its backup format. The `.imscc` files are ZIP archives containing:

- `imsmanifest.xml` - Package manifest
- `assessment_meta.xml` - Quiz settings
- `[quiz-id]/assessment.xml` - QTI 1.2 quiz content

This app focuses on editing the QTI XML while preserving Canvas-specific extensions.

## Roadmap

See [TODO.md](TODO.md) for the detailed implementation plan.

**Current Phase**: Foundation setup
**Next Phase**: Core data models and QTI parsing

## License

See [LICENSE](LICENSE) file.

## Contributing

This is a personal-use tool. Architecture is designed to be understandable and extensible. Feel free to fork and adapt for your own needs.

## Questions or Issues?

Check the documentation:
- [TODO.md](TODO.md) - Implementation roadmap
- [CLAUDE.md](CLAUDE.md) - Architecture details

---

*Built with Swift and SwiftUI for macOS*
