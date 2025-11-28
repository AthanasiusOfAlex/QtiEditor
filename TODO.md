# QTI Quiz Editor - Implementation Roadmap

## Phase 1: Fine Tuning

- [x] I need a toggle that turns autosave on or off (and stays persistent). Should be OFF by default. Right now, undo/redo is too primitive to make autosave worth it except to test.
- [x] I can't save new files. It get the following message: 'The document "Untitled" could not be saved as "Untitled". QtiEditor is unable to save using this document type.' I tried to fix this previously by employing a `.plist`, but I am not sure it is being used properly. The `.plist` can be found at `Sources/QtiEditor/Resources/FileAssociations.plist`. Steps to reproduce.
  - Open a new file (Cmd+N)
  - Add a new question (Shft+Cmd+N)
  - Attempt to save (Cmd+S)
  - Accept the proposed file (Untitled) by clicking on "Save".

## Phase 2: Long-term projects

- [ ] Robust undo/redo system that tracks the underlying HTML, not the rich text
- [ ] Make it so that editing in the rich-text editor doesn't mess up the underlying HTML. Right now, as soon as I edit complex HTML, the editor immediately simplifies the structure
- [ ] Actual HTML beautifying. Should we use the Tidy library? This project looks promising: https://github.com/htacg/SwLibTidy.git
