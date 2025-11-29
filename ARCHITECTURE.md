# Architecture

## Overview
QtiEditor is a document-based SwiftUI application designed to edit QTI (Question and Test Interoperability) 1.2 files packaged as ZIP bundles.
The application validates the "Value Boundary" architecture by extracting the main assessment XML from the ZIP, allowing plain text editing, and repacking the ZIP upon save.

## Architectural Patterns

### Value Boundary
The application strictly separates **Data** (Value Types) from **State** (Reference Types).

1.  **Model (Data)**: `QTIDocument`
    -   Implemented as a `struct` conforming to `FileDocument`.
    -   **Persistence**: Handles the lifecycle of QTI ZIP bundles. It preserves the original ZIP binary data and tracks the path to the internal assessment XML.
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
1.  `DocumentGroup` loads the ZIP file as a `FileWrapper`.
2.  `QTIDocument` uses `ZipHelper` to unzip the data to a temporary location.
3.  The app parses `imsmanifest.xml` to locate the main assessment XML.
4.  The content of the assessment XML is loaded into memory (`QTIDocument.text`).
5.  `ContentView` initializes `EditorState` with this text.
6.  UI components bind to properties of `EditorState`.
7.  When `EditorState` changes, `ContentView` updates the source `Binding`.
8.  On Save, `QTIDocument` overwrites the XML in the temporary structure and re-zips the directory using `ZipHelper`.

## Persistence & File Handling
-   **Zip Strategy**: The app uses a stateless `ZipHelper` utility (`Sources/QtiEditor/Utils/ZipHelper.swift`) to interface with system commands (`/usr/bin/unzip` and `/usr/bin/zip`) via `Process`.
-   **Manifest Parsing**: Swift `Regex` is used to parse `imsmanifest.xml` to identify the resource with type `imsqti_xmlv1p2`.
-   **Data Integrity**: The original ZIP structure is preserved. Only the modified assessment XML is overwritten within the bundle.

## Concurrency
-   **Strict Concurrency**: The app uses modern Swift concurrency.
-   **MainActor**: UI state (`EditorState`) is isolated to the Main Actor.
-   **Sendable**: Data models (`QTIDocument`) are Sendable to allow safe passing between actors if needed.

## Configuration
-   **Autosave**: Disabled in-place autosave via `Info.plist` key `NSAutosaveInPlace = false` (managed in `Bundler.toml`).
-   **File Type**: Configured for QTI Quiz Bundles (`public.zip-archive`).
