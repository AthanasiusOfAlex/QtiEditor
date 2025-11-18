//
//  HTMLBeautifier.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import Foundation

/// Service for formatting and validating HTML content
actor HTMLBeautifier {
    /// Format HTML with proper indentation
    /// - Parameter html: Raw HTML string
    /// - Returns: Formatted HTML string
    func beautify(_ html: String) async -> String {
        // Simple HTML beautification without external dependencies
        // This adds proper indentation to HTML tags

        var result = ""
        var indentLevel = 0
        let indentString = "  " // 2 spaces

        // Remove extra whitespace first
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)

        // Simple tag-based formatting
        var currentTag = ""
        var inTag = false
        var inClosingTag = false

        for char in trimmed {
            if char == "<" {
                // Start of a tag
                if !currentTag.isEmpty && !inTag {
                    // Add the text content on current line
                    result += currentTag
                    currentTag = ""
                }
                inTag = true
                currentTag = String(char)
            } else if char == ">" {
                // End of a tag
                currentTag += String(char)

                // Determine if this is a closing tag or self-closing tag
                if currentTag.hasPrefix("</") {
                    // Closing tag - decrease indent before adding
                    indentLevel = max(0, indentLevel - 1)
                    result += String(repeating: indentString, count: indentLevel) + currentTag + "\n"
                    inClosingTag = true
                } else if currentTag.hasSuffix("/>") {
                    // Self-closing tag
                    result += String(repeating: indentString, count: indentLevel) + currentTag + "\n"
                } else {
                    // Opening tag
                    result += String(repeating: indentString, count: indentLevel) + currentTag + "\n"
                    // Increase indent for next content (unless it's a void element)
                    if !isVoidElement(currentTag) {
                        indentLevel += 1
                    }
                }

                currentTag = ""
                inTag = false
            } else {
                // Regular character
                currentTag += String(char)
            }
        }

        // Add any remaining content
        if !currentTag.isEmpty {
            let trimmedContent = currentTag.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedContent.isEmpty {
                result += String(repeating: indentString, count: indentLevel) + trimmedContent + "\n"
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Validate HTML structure
    /// - Parameter html: HTML string to validate
    /// - Returns: Validation result with error messages if any
    func validate(_ html: String) async -> ValidationResult {
        var errors: [String] = []
        var tagStack: [String] = []

        // Simple validation: check for matching tags
        let tagPattern = /<\/?([a-zA-Z][a-zA-Z0-9]*)[^>]*>/
        guard let regex = try? NSRegularExpression(pattern: tagPattern.pattern) else {
            return ValidationResult(isValid: false, errors: ["Failed to create validation regex"])
        }

        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        for match in matches {
            guard let tagRange = Range(match.range(at: 0), in: html),
                  let nameRange = Range(match.range(at: 1), in: html) else {
                continue
            }

            let fullTag = String(html[tagRange])
            let tagName = String(html[nameRange]).lowercased()

            // Skip void elements (self-closing tags)
            if isVoidElement(fullTag) {
                continue
            }

            if fullTag.hasPrefix("</") {
                // Closing tag
                if tagStack.isEmpty {
                    errors.append("Unexpected closing tag: \(fullTag)")
                } else {
                    let expectedTag = tagStack.removeLast()
                    if expectedTag != tagName {
                        errors.append("Mismatched tags: expected </\(expectedTag)>, found \(fullTag)")
                    }
                }
            } else if !fullTag.hasSuffix("/>") {
                // Opening tag (not self-closing)
                tagStack.append(tagName)
            }
        }

        // Check for unclosed tags
        if !tagStack.isEmpty {
            for tag in tagStack.reversed() {
                errors.append("Unclosed tag: <\(tag)>")
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    /// Check if a tag is a void element (self-closing by definition)
    private func isVoidElement(_ tag: String) -> Bool {
        let voidElements = [
            "area", "base", "br", "col", "embed", "hr", "img", "input",
            "link", "meta", "param", "source", "track", "wbr"
        ]

        let lowercased = tag.lowercased()
        return voidElements.contains { lowercased.contains("<\($0)") }
    }
}

/// Result of HTML validation
struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}
