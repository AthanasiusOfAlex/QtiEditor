# QTI Quiz Editor - Implementation Roadmap

## Phase 1: Bug fixing

- [x] I need to turn autosave off. We attempted to do this using Info.plist (which gets updated via Bundler.toml). The correct keypair appears in the Info.plist file:
  ```
  <key>NSAutosaveInPlace</key>
	<false/>
  ```
  However, the app still silently autosaves. Any ideas? CRITICAL: use SwiftUI. Don't revert to AppKit.

  **SOLVED**: Implemented manual save control with dirty state tracking. The root cause was that SwiftUI's DocumentGroup automatically saves whenever the document binding changes. The solution:
  - Removed the auto-sync .onChange handler in ContentView that was triggering saves on every keystroke
  - Added dirty state tracking (isDirty, markDirty(), markClean()) to EditorState
  - Integrated with NSDocument via updateChangeCount() to show "Save changes?" dialog
  - Added custom Save command (Cmd+S) that explicitly syncs to DocumentGroup binding
  - Added markDirty() calls to all document mutation methods (11 total)
  - Added markDirty() callbacks to text editors (HTML & Rich Text)
  - Files modified: ContentView.swift, EditorState.swift, QtiEditorApp.swift, QuestionEditorView.swift
  - Now saves ONLY on explicit Cmd+S, shows dirty indicator (•) in title, prompts on close

## Phase 2: Long-term projects

- [ ] Robust undo/redo system that tracks the underlying HTML, not the rich text
- [ ] Make it so that editing in the rich-text editor doesn't mess up the underlying HTML. Right now, as soon as I edit complex HTML, the editor immediately simplifies the structure
- [ ] Actual HTML beautifying. Should we use the Tidy library? This project looks promising: https://github.com/htacg/SwLibTidy.git
