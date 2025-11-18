//
//  HTMLEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
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
            textView.string = text

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

    /// Apply basic syntax highlighting to HTML
    private func applySyntaxHighlighting(to textView: NSTextView) {
        let text = textView.string
        let fullRange = NSRange(location: 0, length: text.count)

        // Create attributed string with default attributes
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)

        // Highlight HTML tags
        if let tagRegex = try? NSRegularExpression(pattern: "</?[a-zA-Z][a-zA-Z0-9]*[^>]*>", options: []) {
            let matches = tagRegex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: match.range)
            }
        }

        // Highlight attribute names
        if let attrNameRegex = try? NSRegularExpression(pattern: "\\s([a-zA-Z-]+)=", options: []) {
            let matches = attrNameRegex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                if match.numberOfRanges > 1 {
                    let nameRange = match.range(at: 1)
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: nameRange)
                }
            }
        }

        // Highlight attribute values (quoted strings)
        if let stringRegex = try? NSRegularExpression(pattern: "\"[^\"]*\"", options: []) {
            let matches = stringRegex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: match.range)
            }
        }

        // Store current selection
        let selectedRange = textView.selectedRange()

        // Update text view with highlighting
        textView.textStorage?.setAttributedString(attributedString)

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

#Preview {
    @Previewable @State var htmlText = """
    <p>This is a <strong>sample</strong> HTML text with <em>formatting</em>.</p>
    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
    </ul>
    """

    return VStack {
        Text("HTML Editor")
            .font(.headline)
        HTMLEditorView(text: $htmlText)
            .frame(height: 300)
    }
    .padding()
}
