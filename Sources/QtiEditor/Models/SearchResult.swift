//
//  SearchResult.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Represents a single search match
struct SearchMatch: Identifiable, Sendable {
    let id = UUID()

    /// The question containing this match
    let questionID: UUID

    /// Field where the match was found
    let field: SearchField

    /// Answer ID if match is in an answer
    let answerID: UUID?

    /// Range of the match in the original text
    let range: Range<String.Index>

    /// The matched text
    let matchedText: String

    /// Context around the match (for preview)
    let context: String

    /// Line number (if applicable)
    let lineNumber: Int?
}

/// Fields that can be searched
enum SearchField: String, CaseIterable, Sendable {
    case questionTitle = "Question Title"
    case questionText = "Question Text"
    case answerText = "Answer Text"
    case feedback = "Feedback"
    case all = "All Fields"

    var displayName: String {
        rawValue
    }
}

/// Search scope
enum SearchScope: String, CaseIterable, Sendable {
    case currentQuestion = "Current Question"
    case allQuestions = "All Questions"

    var displayName: String {
        rawValue
    }
}
