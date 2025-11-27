# QTI Quiz Editor - Implementation Roadmap

## Phase 1: Cleanup and perfection

### Feature requests

- [ ] Let's remove the special "Search" button. It's superfluous if I can just open the side info panel

### Bug fixes

- [ ] Fix the following compile errora:
  ```
  Sources/QtiEditor/Models/QTI/QTIQuestion.swift:80:24 Conformance of 'QTIQuestion' to protocol 'Identifiable' crosses into main actor-isolated code and can cause data races
  Sources/QtiEditor/Models/QTI/QTIDocument.swift:51:24 Conformance of 'QTIDocument' to protocol 'Identifiable' crosses into main actor-isolated code and can cause data races
  ```
  - Remember: find a solution that respects modern Swift idiom. Fix the underlyinc concurrency issue. Don't patch it by regressing to Dispatch
  - Reference manual: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/
- [ ] We need to be able to edit and save question points reliably.
  - Currently, I can edit the points and the new number appears persistent, but when I save the question, it reverts to 100 points
- [ ] There should also be an option to set points for all questions globally, perhaps with two parts
    - [ ] Have a toggle makes so that all questions have the same points. Obviously, if, I switch it to true, it will overwrite any individual point scores that were previously there.
    - [ ] If the toggle is set to true, allow me to set the global point score.
- [ ] The default number of points for a new/blank question should be 1, not 100

## Phase 2: Long-term projects
- [ ] Review the code and and see if we can get rid of any legacy AppKit interfaces and modernize completely
- [ ] Robust undo/redo system
