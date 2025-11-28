# QTI Quiz Editor - Implementation Roadmap

## Phase 1: Bug fixing

- [x] I need to turn autosave off. We attempted to do this using Info.plist (which gets updated via Bundler.toml). The correct keypair appears in the Info.plist file:
  ```
  <key>NSAutosaveInPlace</key>
	<false/>
  ```
  However, the app still silently autosaves. Any ideas? CRITICAL: use SwiftUI. Don't revert to AppKit.

  **SOLVED**: The `NSAutosaveInPlace` setting only controls one type of autosave. SwiftUI's `DocumentGroup` has additional autosave mechanisms through NSDocument. Created [AppDelegate.swift](Sources/QtiEditor/App/AppDelegate.swift) that intercepts document opening and disables all autosave features:
  - `autosavesInPlace = false`
  - `autosavesDrafts = false`
  - `autosavingIsImplicitlyCancellable = true`

  The app delegate is connected via `@NSApplicationDelegateAdaptor` in [QtiEditorApp.swift](Sources/QtiEditor/App/QtiEditorApp.swift:15).

## Phase 2: Long-term projects

- [ ] Robust undo/redo system that tracks the underlying HTML, not the rich text
- [ ] Make it so that editing in the rich-text editor doesn't mess up the underlying HTML. Right now, as soon as I edit complex HTML, the editor immediately simplifies the structure
- [ ] Actual HTML beautifying. Should we use the Tidy library? This project looks promising: https://github.com/htacg/SwLibTidy.git
