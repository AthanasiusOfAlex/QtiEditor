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

        // Ensure canvas_identifier exists
        if self.metadata["canvas_identifier"] == nil {
            self.metadata["canvas_identifier"] = UUID().uuidString.lowercased()
        }
    }
}

// MARK: - Identifiable Conformance
extension QTIAnswer: Identifiable {}

// MARK: - DTO for Serialization
extension QTIAnswer {
    struct DTO: Codable, Sendable {
        let id: UUID
        let text: String
        let isCorrect: Bool
        let feedback: String
        let weight: Double
        let metadata: [String: String]
    }

    var dto: DTO {
        DTO(
            id: id,
            text: text,
            isCorrect: isCorrect,
            feedback: feedback,
            weight: weight,
            metadata: metadata
        )
    }

    nonisolated convenience init(dto: DTO) {
        self.init(
            id: dto.id,
            text: dto.text,
            isCorrect: dto.isCorrect,
            feedback: dto.feedback,
            weight: dto.weight,
            metadata: dto.metadata
        )
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
