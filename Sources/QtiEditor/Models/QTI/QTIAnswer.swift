//
//  QTIAnswer.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Represents an answer choice for a QTI question
struct QTIAnswer: Identifiable, Codable, Sendable, Equatable {
    /// Unique identifier
    let id: UUID

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

        // Ensure canvas_identifier exists
        if self.metadata["canvas_identifier"] == nil {
            self.metadata["canvas_identifier"] = UUID().uuidString.lowercased()
        }
    }

    /// Creates a deep copy of this answer with a new UUID
    /// - Parameter preserveCanvasIdentifier: If false, removes canvas_identifier from metadata
    /// - Returns: A new QTIAnswer instance with copied properties
    func duplicate(preserveCanvasIdentifier: Bool = false) -> QTIAnswer {
        // Copy metadata, optionally removing canvas_identifier
        var copiedMetadata = metadata
        if !preserveCanvasIdentifier {
            copiedMetadata.removeValue(forKey: "canvas_identifier")
        }

        return QTIAnswer(
            id: UUID(), // New UUID for the copy
            text: text,
            isCorrect: isCorrect,
            feedback: feedback,
            weight: weight,
            metadata: copiedMetadata
        )
    }
}
