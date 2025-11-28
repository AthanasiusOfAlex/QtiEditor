//
//  SearchEngine.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//  Updated 2025-11-19 to use Swift Regex
//

import Foundation

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
    func replaceAll(
        matches: [SearchMatch],
        with replacement: String,
        pattern: String,
        isRegex: Bool,
        in document: inout QTIDocument
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
            guard let questionIndex = document.questions.firstIndex(where: { $0.id == key.questionID }) else {
                continue
            }

            try replaceInField(
                document: &document,
                questionIndex: questionIndex,
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

        // Search in question title
        if field == .questionTitle || field == .all {
            let titleText = question.metadata["canvas_title"] ?? ""
            if !titleText.isEmpty {
                let titleMatches = try searchInText(
                    text: titleText,
                    pattern: pattern,
                    isRegex: isRegex,
                    isCaseSensitive: isCaseSensitive,
                    questionID: question.id,
                    field: .questionTitle,
                    answerID: nil
                )
                matches.append(contentsOf: titleMatches)
            }
        }

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
            do {
                let regex = try Regex(pattern)
                let query = isCaseSensitive ? regex : regex.ignoresCase()

                let regexMatches = text.matches(of: query)

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
            } catch {
                throw SearchError.invalidRegexPattern(pattern)
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

        // Strip HTML tags for cleaner preview (using Regex!)
        try? context.replace(Regex("<[^>]+>"), with: "")
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
        document: inout QTIDocument,
        questionIndex: Int,
        answerID: UUID?,
        field: SearchField,
        pattern: String,
        replacement: String,
        isRegex: Bool
    ) throws {
        switch field {
        case .questionTitle:
            let titleText = document.questions[questionIndex].metadata["canvas_title"] ?? ""
            document.questions[questionIndex].metadata["canvas_title"] = try performReplace(
                in: titleText,
                pattern: pattern,
                replacement: replacement,
                isRegex: isRegex
            )

        case .questionText:
            document.questions[questionIndex].questionText = try performReplace(
                in: document.questions[questionIndex].questionText,
                pattern: pattern,
                replacement: replacement,
                isRegex: isRegex
            )

        case .answerText:
            guard let answerID = answerID,
                  let answerIndex = document.questions[questionIndex].answers.firstIndex(where: { $0.id == answerID }) else {
                return
            }
            document.questions[questionIndex].answers[answerIndex].text = try performReplace(
                in: document.questions[questionIndex].answers[answerIndex].text,
                pattern: pattern,
                replacement: replacement,
                isRegex: isRegex
            )

        case .feedback:
            document.questions[questionIndex].generalFeedback = try performReplace(
                in: document.questions[questionIndex].generalFeedback,
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
            // Use custom extension for template support ($1, etc)
            return try text.replacingWithTemplate(matching: pattern, with: replacement)
        } else {
            return text.replacingOccurrences(of: pattern, with: replacement)
        }
    }
}
