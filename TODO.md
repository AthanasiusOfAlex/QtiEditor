# QTI Quiz Editor - Implementation Roadmap

## Phase 1: Fine Tuning

- [x] Refactor QTIDocument architecture to separate FileDocument (struct) from EditorState (MainActor class) to avoid unsafe initialization (remove `nonisolated(unsafe)` usage). It appears that Swift 6.2+ does not allow the `nonisolated(unsafe)` usage.

## Phase 2: Long-term projects

- [ ] Robust undo/redo system that tracks the underlying HTML, not the rich text
- [ ] Make it so that editing in the rich-text editor doesn't mess up the underlying HTML. Right now, as soon as I edit complex HTML, the editor immediately simplifies the structure
- [ ] Actual HTML beautifying. Should we use the Tidy library? This project looks promising: https://github.com/htacg/SwLibTidy.git
