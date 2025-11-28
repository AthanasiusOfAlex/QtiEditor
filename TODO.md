# QTI Quiz Editor - Implementation Roadmap

## Phase 1: Fine Tuning

- [x] Fix the remaining issues with Swift concurrency.
  - [x] Read the section entitled "Guidelines for Concurrency" attentively
  - [x] Fix the following compiler errors
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:22:26 Conformance of 'QTIDocument' to protocol 'ReferenceFileDocument' crosses into main actor-isolated code and can cause data races
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:54:14 Main actor-isolated property 'title' can not be mutated from a nonisolated context
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:55:14 Main actor-isolated property 'description' can not be mutated from a nonisolated context
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:56:14 Main actor-isolated property 'questions' can not be mutated from a nonisolated context
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:57:14 Main actor-isolated property 'metadata' can not be mutated from a nonisolated context
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:92:18 Main actor-isolated property 'title' can not be mutated from a nonisolated context
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:93:18 Main actor-isolated property 'description' can not be mutated from a nonisolated context
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:94:18 Main actor-isolated property 'questions' can not be mutated from a nonisolated context
    - Sources/QtiEditor/Models/QTI/QTIDocument.swift:95:18 Main actor-isolated property 'metadata' can not be mutated from a nonisolated context
  - [x] See if there are still some refactoring to be done to follow the guidelines

## Phase 4: Long-term projects

- [ ] Robust undo/redo system that tracks the underlying HTML, not the rich text
- [ ] Make it so that editing in the rich-text editor doesn't mess up the underlying HTML. Right now, as soon as I edit complex HTML, the editor immediately simplifies the structure
- [ ] Actual HTML beautifying. Should we use the Tidy library? This project looks promising: https://github.com/htacg/SwLibTidy.git
- [ ] Refactor QTIDocument architecture to separate FileDocument (struct) from EditorState (MainActor class) to avoid unsafe initialization (remove `nonisolated(unsafe)` usage).
