# QTI Quiz Editor - Implementation Roadmap

## Phase 1: Cleanup and perfection

### Feature requests

- [ ] Let's remove the special "Search" button. It's superfluous if I can just open the side info panel

### Bug fixes

- [ ] We need to be able to edit and save question points reliably.
  - Currently, I can edit the points and the new number appears persistent, but when I save the question, it reverts to 100 points
- [ ] There should also be an option to set points for all questions globally, perhaps with two parts
    - [ ] Have a toggle makes so that all questions have the same points. Obviously, if, I switch it to true, it will overwrite any individual point scores that were previously there.
    - [ ] If the toggle is set to true, allow me to set the global point score.
- [ ] The default number of points for a new/blank question should be 1, not 100

## Phase 2: Long-term projects

- [0] Robust undo/redo system
