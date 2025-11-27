//
//  HTMLEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//  Updated 2025-11-19 to use Swift Regex
//

import SwiftUI
import AppKit

/// SwiftUI wrapper for NSTextView configured for HTML code editing
struct HTMLEditorView: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: ((String) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // Configure text view for code editing
        textView.delegate = context.coordinator
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 8, height: 8)

        // Enable line wrapping
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Only update if text has changed to avoid cursor jumping
        if textView.string != text {
            let selectedRange = textView.selectedRange()

            // Disable undo registration for programmatic updates to prevent crashes
            textView.undoManager?.disableUndoRegistration()
            textView.string = text
            textView.undoManager?.enableUndoRegistration()

            // Apply syntax highlighting
            applySyntaxHighlighting(to: textView)

            // Restore cursor position if possible
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Cached Regexes
    private static let tagRegex = try? Regex("</?[a-zA-Z][a-zA-Z0-9]*[^>]*>")
    private static let attrNameRegex = try? Regex("\\s([a-zA-Z-]+)=")
    private static let stringRegex = try? Regex("\"[^\"]*\"")

    /// Apply basic syntax highlighting to HTML
    private func applySyntaxHighlighting(to textView: NSTextView) {
        let text = textView.string
        let fullRange = NSRange(location: 0, length: text.count)

        // Create attributed string with default attributes
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)

        // Highlight HTML tags
        if let tagRegex = Self.tagRegex {
            let matches = text.matches(of: tagRegex)
            for match in matches {
                let nsRange = NSRange(match.range, in: text)
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: nsRange)
            }
        }

        // Highlight attribute names
        if let attrNameRegex = Self.attrNameRegex {
            let matches = text.matches(of: attrNameRegex)
            for match in matches {
                if let range = match.output[1].range {
                    let nsRange = NSRange(range, in: text)
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: nsRange)
                }
            }
        }

        // Highlight attribute values (quoted strings)
        if let stringRegex = Self.stringRegex {
            let matches = text.matches(of: stringRegex)
            for match in matches {
                let nsRange = NSRange(match.range, in: text)
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: nsRange)
            }
        }

        // Store current selection
        let selectedRange = textView.selectedRange()

        // Disable undo for syntax highlighting changes
        textView.undoManager?.disableUndoRegistration()

        // Update text view with highlighting
        textView.textStorage?.setAttributedString(attributedString)

        // Re-enable undo
        textView.undoManager?.enableUndoRegistration()

        // Restore selection
        textView.setSelectedRange(selectedRange)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HTMLEditorView

        init(_ parent: HTMLEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            let newText = textView.string
            if parent.text != newText {
                parent.text = newText
                parent.onTextChange?(newText)

                // Reapply syntax highlighting after text changes
                parent.applySyntaxHighlighting(to: textView)
            }
        }
    }
}
