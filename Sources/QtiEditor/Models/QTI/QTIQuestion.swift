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
@Observable
final class QTIQuestion: @unchecked Sendable {
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

        // Ensure canvas_identifier exists
        if self.metadata["canvas_identifier"] == nil {
            self.metadata["canvas_identifier"] = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
    }
}

// MARK: - Identifiable Conformance
extension QTIQuestion: Identifiable {}

// MARK: - DTO for Serialization
extension QTIQuestion {
    struct DTO: Codable, Sendable {
        let id: UUID
        let type: QTIQuestionType
        let questionText: String
        let points: Double
        let answers: [QTIAnswer.DTO]
        let generalFeedback: String
        let metadata: [String: String]
    }

    var dto: DTO {
        DTO(
            id: id,
            type: type,
            questionText: questionText,
            points: points,
            answers: answers.map { $0.dto },
            generalFeedback: generalFeedback,
            metadata: metadata
        )
    }

    convenience init(dto: DTO) {
        self.init(
            id: dto.id,
            type: dto.type,
            questionText: dto.questionText,
            points: dto.points,
            answers: dto.answers.map { QTIAnswer(dto: $0) },
            generalFeedback: dto.generalFeedback,
            metadata: dto.metadata
        )
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
