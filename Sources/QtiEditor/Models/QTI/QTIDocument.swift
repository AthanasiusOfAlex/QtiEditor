//
//  QTIDocument.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Represents a complete QTI quiz document
/// This is the root model that contains all quiz data
@MainActor
@Observable
final class QTIDocument: Sendable {
    /// Unique identifier for this quiz
    let id: UUID

    /// Quiz title
    var title: String

    /// Quiz description (optional)
    var description: String

    /// Collection of questions in this quiz
    var questions: [QTIQuestion]

    /// Quiz-level settings and metadata
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        title: String = "Untitled Quiz",
        description: String = "",
        questions: [QTIQuestion] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
        self.metadata = metadata
    }

    /// Create a new empty quiz
    static func empty() -> QTIDocument {
        QTIDocument()
    }
}

// MARK: - Identifiable Conformance
extension QTIDocument: Identifiable {}
