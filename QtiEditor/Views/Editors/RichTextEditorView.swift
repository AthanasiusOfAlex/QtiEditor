//
//  RichTextEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI
import AppKit

/// SwiftUI wrapper for NSTextView configured for rich text (WYSIWYG) editing
struct RichTextEditorView: NSViewRepresentable {
    @Binding var htmlText: String
    var onTextChange: ((String) -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // Configure text view for rich text editing
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 8, height: 8)

        // Enable standard text substitutions
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true

        // Enable line wrapping
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)

        // Add formatting toolbar
        textView.isAutomaticTextCompletionEnabled = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Convert HTML to attributed string
        let attributedString = htmlToAttributedString(htmlText)

        // Only update if content has changed to avoid cursor jumping
        if !textView.attributedString().isEqual(to: attributedString) {
            let selectedRange = textView.selectedRange()

            // Disable undo registration for programmatic updates to prevent crashes
            textView.undoManager?.disableUndoRegistration()
            textView.textStorage?.setAttributedString(attributedString)
            textView.undoManager?.enableUndoRegistration()

            // Restore cursor position if possible
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Convert HTML string to NSAttributedString
    private func htmlToAttributedString(_ html: String) -> NSAttributedString {
        // Strip explicit black colors to support dark mode
        let processedHTML = stripBlackColors(from: html)

        // Clean HTML by wrapping in proper HTML structure if needed
        let wrappedHTML: String
        if !processedHTML.lowercased().contains("<html") {
            wrappedHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        font-size: 14px;
                        color: -apple-system-label;
                    }
                </style>
            </head>
            <body>
            \(processedHTML)
            </body>
            </html>
            """
        } else {
            wrappedHTML = processedHTML
        }

        guard let data = wrappedHTML.data(using: .utf8) else {
            return NSAttributedString(string: html)
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        do {
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return attributedString
        } catch {
            // Fallback to plain text if HTML parsing fails
            return NSAttributedString(string: html)
        }
    }

    /// Strip explicit black colors from HTML to support dark mode
    /// Removes: color: black, color: #000, color: #000000, color: rgb(0,0,0)
    private func stripBlackColors(from html: String) -> String {
        var result = html

        // Patterns for black colors (case-insensitive)
        let blackPatterns = [
            "color:\\s*black\\s*;?",           // color: black
            "color:\\s*#000\\s*;?",            // color: #000
            "color:\\s*#000000\\s*;?",         // color: #000000
            "color:\\s*rgb\\s*\\(\\s*0\\s*,\\s*0\\s*,\\s*0\\s*\\)\\s*;?" // color: rgb(0,0,0)
        ]

        for pattern in blackPatterns {
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        // Clean up empty style attributes: style="" or style="  "
        result = result.replacingOccurrences(
            of: "style\\s*=\\s*[\"']\\s*[\"']",
            with: "",
            options: .regularExpression
        )

        return result
    }

    /// Convert NSAttributedString to HTML string
    private func attributedStringToHTML(_ attributedString: NSAttributedString) -> String {
        let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        do {
            let htmlData = try attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: documentAttributes
            )

            guard var html = String(data: htmlData, encoding: .utf8) else {
                return attributedString.string
            }

            // Extract only the body content
            html = extractBodyContent(from: html)

            return html
        } catch {
            // Fallback to plain text
            return attributedString.string
        }
    }

    /// Extract content from HTML body tag
    private func extractBodyContent(from html: String) -> String {
        // Try to extract content between <body> and </body>
        if let bodyRange = html.range(of: "<body[^>]*>", options: .regularExpression),
           let endBodyRange = html.range(of: "</body>", options: .caseInsensitive) {
            let startIndex = bodyRange.upperBound
            let endIndex = endBodyRange.lowerBound
            let bodyContent = html[startIndex..<endIndex]
            return String(bodyContent).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Fallback: return original HTML
        return html
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorView

        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Convert attributed string back to HTML
            let newHTML = parent.attributedStringToHTML(textView.attributedString())

            if parent.htmlText != newHTML {
                parent.htmlText = newHTML
                parent.onTextChange?(newHTML)
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
        Text("Rich Text Editor")
            .font(.headline)
        RichTextEditorView(htmlText: $htmlText)
            .frame(height: 300)
        Divider()
        Text("HTML Output:")
            .font(.caption)
        ScrollView {
            Text(htmlText)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        .frame(height: 100)
    }
    .padding()
}
