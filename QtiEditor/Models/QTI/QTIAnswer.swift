//
//  QTIAnswer.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Represents an answer choice for a QTI question
@MainActor
@Observable
final class QTIAnswer: Sendable {
    /// Unique identifier
    var id: UUID

    /// Answer text (HTML content)
    var text: String

    /// Whether this is a correct answer
    var isCorrect: Bool

    /// Feedback shown when this answer is selected (optional)
    var feedback: String

    /// Weight/points for partial credit (default 100 for correct, 0 for incorrect)
    var weight: Double

    /// Additional metadata (Canvas-specific fields, etc.)
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        text: String = "",
        isCorrect: Bool = false,
        feedback: String = "",
        weight: Double? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
        self.feedback = feedback
        self.weight = weight ?? (isCorrect ? 100.0 : 0.0)
        self.metadata = metadata
    }
}

// MARK: - Identifiable Conformance
extension QTIAnswer: Identifiable {}
