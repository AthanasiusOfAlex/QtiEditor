//
//  QTIQuestion.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Question types supported by QTI 1.2
enum QTIQuestionType: String, Codable, CaseIterable, Sendable {
    case multipleChoice = "multiple_choice_question"
    case trueFalse = "true_false_question"
    case essay = "essay_question"
    case fillInBlank = "fill_in_multiple_blanks_question"
    case matching = "matching_question"
    case multipleAnswers = "multiple_answers_question"
    case numerical = "numerical_question"
    case other = "other"

    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .trueFalse: return "True/False"
        case .essay: return "Essay"
        case .fillInBlank: return "Fill in the Blank"
        case .matching: return "Matching"
        case .multipleAnswers: return "Multiple Answers"
        case .numerical: return "Numerical"
        case .other: return "Other"
        }
    }
}

/// Represents a single question in a QTI quiz
@MainActor
@Observable
final class QTIQuestion: Sendable {
    /// Unique identifier
    let id: UUID

    /// Question type
    var type: QTIQuestionType

    /// Question text (HTML content)
    var questionText: String

    /// Points awarded for correct answer
    var points: Double

    /// Answer choices (for multiple choice, true/false, etc.)
    var answers: [QTIAnswer]

    /// General feedback shown after answering
    var generalFeedback: String

    /// Additional metadata (Canvas-specific fields, etc.)
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        type: QTIQuestionType = .multipleChoice,
        questionText: String = "",
        points: Double = 1.0,
        answers: [QTIAnswer] = [],
        generalFeedback: String = "",
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.questionText = questionText
        self.points = points
        self.answers = answers
        self.generalFeedback = generalFeedback
        self.metadata = metadata
    }
}

// MARK: - Identifiable Conformance
extension QTIQuestion: Identifiable {}

// MARK: - Codable Conformance
extension QTIQuestion: Codable {
    enum CodingKeys: String, CodingKey {
        case id, type, questionText, points, answers, generalFeedback, metadata
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let type = try container.decode(QTIQuestionType.self, forKey: .type)
        let questionText = try container.decode(String.self, forKey: .questionText)
        let points = try container.decode(Double.self, forKey: .points)
        let answers = try container.decode([QTIAnswer].self, forKey: .answers)
        let generalFeedback = try container.decode(String.self, forKey: .generalFeedback)
        let metadata = try container.decode([String: String].self, forKey: .metadata)

        self.init(
            id: id,
            type: type,
            questionText: questionText,
            points: points,
            answers: answers,
            generalFeedback: generalFeedback,
            metadata: metadata
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(questionText, forKey: .questionText)
        try container.encode(points, forKey: .points)
        try container.encode(answers, forKey: .answers)
        try container.encode(generalFeedback, forKey: .generalFeedback)
        try container.encode(metadata, forKey: .metadata)
    }
}

// MARK: - Helper Methods
extension QTIQuestion {
    /// Returns the correct answer(s) for this question
    var correctAnswers: [QTIAnswer] {
        answers.filter { $0.isCorrect }
    }

    /// Returns whether this question has at least one correct answer defined
    var hasCorrectAnswer: Bool {
        !correctAnswers.isEmpty
    }

    /// Extracts plain text preview from HTML question text
    /// - Parameter maxLength: Maximum length of preview (default: 100)
    /// - Returns: Plain text preview with ellipsis if truncated
    func previewText(maxLength: Int = 100) -> String {
        // Strip HTML tags
        let stripped = questionText
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Decode common HTML entities
        let decoded = stripped
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        // Collapse multiple spaces into one
        let cleaned = decoded
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Return empty message if no text
        if cleaned.isEmpty {
            return "(Empty question)"
        }

        // Truncate at word boundary if too long
        if cleaned.count > maxLength {
            let truncated = String(cleaned.prefix(maxLength))
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            }
            return truncated + "..."
        }

        return cleaned
    }

    /// Creates a deep copy of this question with new UUIDs
    /// - Parameter preserveCanvasIdentifier: If false, removes canvas_identifier from metadata
    /// - Returns: A new QTIQuestion instance with copied properties
    func duplicate(preserveCanvasIdentifier: Bool = false) -> QTIQuestion {
        // Deep copy all answers with new UUIDs
        let copiedAnswers = answers.map { $0.duplicate(preserveCanvasIdentifier: preserveCanvasIdentifier) }

        // Copy metadata, optionally removing canvas_identifier
        var copiedMetadata = metadata
        if !preserveCanvasIdentifier {
            copiedMetadata.removeValue(forKey: "canvas_identifier")
        }

        return QTIQuestion(
            id: UUID(), // New UUID for the copy
            type: type,
            questionText: questionText,
            points: points,
            answers: copiedAnswers,
            generalFeedback: generalFeedback,
            metadata: copiedMetadata
        )
    }
}
