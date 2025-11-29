# Architecture

## Overview
QtiEditor is a document-based SwiftUI application designed to edit QTI (Question and Test Interoperability) files.
Currently, it operates as a plain text editor using the architectural foundations intended for the full QTI implementation.

## Architectural Patterns

### Value Boundary
The application strictly separates **Data** (Value Types) from **State** (Reference Types).

1.  **Model (Data)**: `QTIDocument`
    -   Implemented as a `struct` conforming to `FileDocument`.
    -   Value semantics ensure thread safety and predictability.
    -   Conforms to `Sendable` and `Equatable`.
    -   Located in `Sources/QtiEditor/Models/`.

2.  **State (Logic)**: `EditorState`
    -   Implemented as a `@MainActor` class conforming to `@Observable`.
    -   Holds the active "working copy" of the `QTIDocument`.
    -   Manages the editing session logic.
    -   Located in `Sources/QtiEditor/State/`.

3.  **View**: `ContentView`
    -   Receives a `@Binding` to the `QTIDocument` (source of truth from `DocumentGroup`).
    -   Initializes and syncs with `EditorState`.
    -   Uses `EditorState` for binding UI components (e.g., `TextEditor`).

### Data Flow
1.  `DocumentGroup` loads the file and passes a Binding to `ContentView`.
2.  `ContentView` initializes `EditorState` with the document value.
3.  UI components bind to properties of `EditorState`.
4.  When `EditorState` changes, `ContentView` detects the change (via `onChange`) and updates the source `Binding`.
5.  If the source `Binding` changes externally (e.g., Undo/Redo), `ContentView` updates `EditorState`.

## Concurrency
-   **Strict Concurrency**: The app uses modern Swift concurrency.
-   **MainActor**: UI state (`EditorState`) is isolated to the Main Actor.
-   **Sendable**: Data models (`QTIDocument`) are Sendable to allow safe passing between actors if needed.

## Configuration
-   **Autosave**: Disabled in-place autosave via `Info.plist` key `NSAutosaveInPlace = false` (managed in `Bundler.toml`).
-   **File Type**: Currently configured for Plain Text (`public.plain-text`).
