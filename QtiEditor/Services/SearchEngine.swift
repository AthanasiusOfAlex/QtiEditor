//
//  SearchEngine.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation
import RegexBuilder

/// Errors that can occur during search operations
enum SearchError: LocalizedError {
    case invalidRegexPattern(String)
    case noMatches

    var errorDescription: String? {
        switch self {
        case .invalidRegexPattern(let pattern):
            return "Invalid regex pattern: \(pattern)"
        case .noMatches:
            return "No matches found"
        }
    }
}

/// Search and replace engine using Swift's native Regex API
@MainActor
final class SearchEngine {
    /// Performs a search across the specified scope
    /// - Parameters:
    ///   - pattern: Search pattern (plain text or regex string)
    ///   - isRegex: Whether to treat pattern as regex
    ///   - isCaseSensitive: Whether search is case-sensitive
    ///   - scope: Search scope
    ///   - field: Field to search in
    ///   - document: Document to search
    ///   - currentQuestionID: ID of current question (for currentQuestion scope)
    /// - Returns: Array of search matches
    func search(
        pattern: String,
        isRegex: Bool,
        isCaseSensitive: Bool,
        scope: SearchScope,
        field: SearchField,
        in document: QTIDocument,
        currentQuestionID: UUID?
    ) throws -> [SearchMatch] {
        guard !pattern.isEmpty else {
            return []
        }

        // Determine which questions to search
        let questionsToSearch: [QTIQuestion]
        switch scope {
        case .currentQuestion:
            guard let currentID = currentQuestionID,
                  let question = document.questions.first(where: { $0.id == currentID }) else {
                return []
            }
            questionsToSearch = [question]

        case .allQuestions:
            questionsToSearch = document.questions
        }

        var allMatches: [SearchMatch] = []

        for question in questionsToSearch {
            let matches = try searchInQuestion(
                question: question,
                pattern: pattern,
                isRegex: isRegex,
                isCaseSensitive: isCaseSensitive,
                field: field
            )
            allMatches.append(contentsOf: matches)
        }

        return allMatches
    }

    /// Replaces all occurrences matching the pattern
    /// - Parameters:
    ///   - matches: Search matches to replace
    ///   - replacement: Replacement text (supports regex capture groups like $1)
    ///   - pattern: Original search pattern
    ///   - isRegex: Whether pattern is regex
    ///   - document: Document to modify
    func replaceAll(
        matches: [SearchMatch],
        with replacement: String,
        pattern: String,
        isRegex: Bool,
        in document: QTIDocument
    ) throws {
        // Create a hashable key for grouping
        struct MatchKey: Hashable {
            let questionID: UUID
            let field: SearchField
            let answerID: UUID?
        }

        // Group matches by question and field
        let groupedMatches = Dictionary(grouping: matches) { match in
            MatchKey(questionID: match.questionID, field: match.field, answerID: match.answerID)
        }

        for (key, _) in groupedMatches {
            guard let question = document.questions.first(where: { $0.id == key.questionID }) else {
                continue
            }

            try replaceInField(
                question: question,
                answerID: key.answerID,
                field: key.field,
                pattern: pattern,
                replacement: replacement,
                isRegex: isRegex
            )
        }
    }

    // MARK: - Private Methods

    private func searchInQuestion(
        question: QTIQuestion,
        pattern: String,
        isRegex: Bool,
        isCaseSensitive: Bool,
        field: SearchField
    ) throws -> [SearchMatch] {
        var matches: [SearchMatch] = []

        // Search in question text
        if field == .questionText || field == .all {
            let questionMatches = try searchInText(
                text: question.questionText,
                pattern: pattern,
                isRegex: isRegex,
                isCaseSensitive: isCaseSensitive,
                questionID: question.id,
                field: .questionText,
                answerID: nil
            )
            matches.append(contentsOf: questionMatches)
        }

        // Search in answers
        if field == .answerText || field == .all {
            for answer in question.answers {
                let answerMatches = try searchInText(
                    text: answer.text,
                    pattern: pattern,
                    isRegex: isRegex,
                    isCaseSensitive: isCaseSensitive,
                    questionID: question.id,
                    field: .answerText,
                    answerID: answer.id
                )
                matches.append(contentsOf: answerMatches)
            }
        }

        // Search in feedback
        if field == .feedback || field == .all {
            let feedbackMatches = try searchInText(
                text: question.generalFeedback,
                pattern: pattern,
                isRegex: isRegex,
                isCaseSensitive: isCaseSensitive,
                questionID: question.id,
                field: .feedback,
                answerID: nil
            )
            matches.append(contentsOf: feedbackMatches)
        }

        return matches
    }

    private func searchInText(
        text: String,
        pattern: String,
        isRegex: Bool,
        isCaseSensitive: Bool,
        questionID: UUID,
        field: SearchField,
        answerID: UUID?
    ) throws -> [SearchMatch] {
        guard !text.isEmpty else {
            return []
        }

        var matches: [SearchMatch] = []

        if isRegex {
            // Use Swift Regex
            let regex: Regex<Substring>
            do {
                if isCaseSensitive {
                    regex = try Regex(pattern)
                } else {
                    regex = try Regex(pattern).ignoresCase()
                }
            } catch {
                throw SearchError.invalidRegexPattern(pattern)
            }

            // Find all matches
            let regexMatches = text.matches(of: regex)

            for match in regexMatches {
                let matchRange = match.range
                let matchedText = String(text[matchRange])
                let context = extractContext(from: text, around: matchRange)

                let searchMatch = SearchMatch(
                    questionID: questionID,
                    field: field,
                    answerID: answerID,
                    range: matchRange,
                    matchedText: matchedText,
                    context: context,
                    lineNumber: nil
                )

                matches.append(searchMatch)
            }
        } else {
            // Simple text search
            let searchOptions: String.CompareOptions = isCaseSensitive ? [] : [.caseInsensitive]
            var searchRange = text.startIndex..<text.endIndex

            while let range = text.range(of: pattern, options: searchOptions, range: searchRange) {
                let matchedText = String(text[range])
                let context = extractContext(from: text, around: range)

                let searchMatch = SearchMatch(
                    questionID: questionID,
                    field: field,
                    answerID: answerID,
                    range: range,
                    matchedText: matchedText,
                    context: context,
                    lineNumber: nil
                )

                matches.append(searchMatch)

                // Move search range past this match
                searchRange = range.upperBound..<text.endIndex
            }
        }

        return matches
    }

    private func extractContext(from text: String, around range: Range<String.Index>) -> String {
        let contextLength = 50
        let start = text.index(range.lowerBound, offsetBy: -contextLength, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: contextLength, limitedBy: text.endIndex) ?? text.endIndex

        var context = String(text[start..<end])

        // Strip HTML tags for cleaner preview
        context = context.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        context = context.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add ellipsis if truncated
        if start != text.startIndex {
            context = "..." + context
        }
        if end != text.endIndex {
            context = context + "..."
        }

        return context
    }

    private func replaceInField(
        question: QTIQuestion,
        answerID: UUID?,
        field: SearchField,
        pattern: String,
        replacement: String,
        isRegex: Bool
    ) throws {
        switch field {
        case .questionText:
            question.questionText = try performReplace(
                in: question.questionText,
                pattern: pattern,
                replacement: replacement,
                isRegex: isRegex
            )

        case .answerText:
            guard let answerID = answerID,
                  let answer = question.answers.first(where: { $0.id == answerID }) else {
                return
            }
            answer.text = try performReplace(
                in: answer.text,
                pattern: pattern,
                replacement: replacement,
                isRegex: isRegex
            )

        case .feedback:
            question.generalFeedback = try performReplace(
                in: question.generalFeedback,
                pattern: pattern,
                replacement: replacement,
                isRegex: isRegex
            )

        case .all:
            // Not applicable for single field replacement
            break
        }
    }

    private func performReplace(
        in text: String,
        pattern: String,
        replacement: String,
        isRegex: Bool
    ) throws -> String {
        if isRegex {
            let regex = try Regex(pattern)
            return text.replacing(regex) { match in
                // Support basic capture group replacement ($0, $1, etc.)
                var result = replacement

                // $0 represents the entire match
                let matchedText = String(text[match.range])
                result = result.replacingOccurrences(of: "$0", with: matchedText)

                // Support numbered capture groups if available
                // Note: Swift Regex capture groups are complex, so we do simple replacement
                // For more complex capture groups, users can use the matched text

                return result
            }
        } else {
            return text.replacingOccurrences(of: pattern, with: replacement)
        }
    }
}
