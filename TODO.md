# QTI Quiz Editor - Implementation Roadmap

## Phase 1: Fine Tuning

### Features
- [ ] I need to be able to turn off autosave until we get undo/redo fine-tuned

### Bugs
- [ ] It won't save new files. I get this strange popup message instead: 'The document "Untitled" could not be saved as "Untitled.zip". QtiEditor is unable to save using this document type.'
- [ ] When I validate the HTML, and the HTML is valid, I get a popup entitled "Error" with text "HTML is valid!" The title is obviously wrong.
- [ ] We should disable beautification until we fix it. It doesn't work and just messes up the HTML. Leave the button in place, but gray it out.
- [ ] Should `QtiAnswer`, `ReferenceFileDocument`, and `QtiQuestion` really be `@unchecked`, or is there something wrong with how we are handling the concurrency? I see `var` variables, but no manual dispatch/NSLock. Reminder: we want those unless we are forced to use legacy APIs; we want to follow modern Swift concurrency best practices. Why are we sending things with a mutable state anyhow?

## Phase 4: Long-term projects
- [ ] Robust undo/redo system that tracks the underlying HTML, not the rich text
- [ ] Make it so that editing in the rich-text editor doesn't mess up the underlying HTML. Right now, as soon as I edit complex HTML, the editor immediately simplifies the structure
- [ ] Actual HTML beautifying. Should we use the Tidy library? This project looks promising: https://github.com/htacg/SwLibTidy.git
