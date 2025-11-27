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

    nonisolated init(
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

// MARK: - Codable Conformance
extension QTIAnswer: Codable {
    enum CodingKeys: String, CodingKey {
        case id, text, isCorrect, feedback, weight, metadata
    }

    nonisolated convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let text = try container.decode(String.self, forKey: .text)
        let isCorrect = try container.decode(Bool.self, forKey: .isCorrect)
        let feedback = try container.decode(String.self, forKey: .feedback)
        let weight = try container.decode(Double.self, forKey: .weight)
        let metadata = try container.decode([String: String].self, forKey: .metadata)

        self.init(
            id: id,
            text: text,
            isCorrect: isCorrect,
            feedback: feedback,
            weight: weight,
            metadata: metadata
        )
    }

    nonisolated func encode(to encoder: Encoder) throws {
        try MainActor.assumeIsolated {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(text, forKey: .text)
            try container.encode(isCorrect, forKey: .isCorrect)
            try container.encode(feedback, forKey: .feedback)
            try container.encode(weight, forKey: .weight)
            try container.encode(metadata, forKey: .metadata)
        }
    }
}

// MARK: - Helper Methods
extension QTIAnswer {
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
