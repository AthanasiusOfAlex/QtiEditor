//
//  EditorState.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation
import SwiftUI

/// Editor mode for question content
enum EditorMode: String, CaseIterable, Sendable {
    case html = "HTML"
    case richText = "Rich Text"
}

/// Global application state for the QTI Editor
/// Manages the current document, selection, and editor settings
@MainActor
@Observable
final class EditorState {
    /// Currently open document
    var document: QTIDocument?

    /// Currently selected question ID
    var selectedQuestionID: UUID?

    /// Current editor mode (HTML or Rich Text)
    var editorMode: EditorMode = .richText

    /// Search panel visibility
    var isSearchVisible: Bool = false

    /// Search text
    var searchText: String = ""

    /// Replacement text for search/replace
    var replacementText: String = ""

    /// Whether regex mode is enabled for search
    var isRegexEnabled: Bool = false

    /// Whether search is case-sensitive
    var isCaseSensitive: Bool = false

    init(document: QTIDocument? = nil) {
        self.document = document
    }

    /// Returns the currently selected question, if any
    var selectedQuestion: QTIQuestion? {
        guard let id = selectedQuestionID,
              let document = document else {
            return nil
        }
        return document.questions.first { $0.id == id }
    }

    /// Create a new question and add it to the document
    func addQuestion(type: QTIQuestionType = .multipleChoice) {
        guard let document = document else { return }

        let question = QTIQuestion(
            type: type,
            questionText: "<p>Enter your question here...</p>",
            points: 1.0,
            answers: []
        )

        // Add default answers for multiple choice
        if type == .multipleChoice {
            question.answers = [
                QTIAnswer(text: "<p>Answer 1</p>", isCorrect: true),
                QTIAnswer(text: "<p>Answer 2</p>", isCorrect: false),
                QTIAnswer(text: "<p>Answer 3</p>", isCorrect: false),
                QTIAnswer(text: "<p>Answer 4</p>", isCorrect: false)
            ]
        }

        document.questions.append(question)
        selectedQuestionID = question.id
    }

    /// Delete the specified question
    func deleteQuestion(_ question: QTIQuestion) {
        guard let document = document else { return }
        document.questions.removeAll { $0.id == question.id }
        if selectedQuestionID == question.id {
            selectedQuestionID = nil
        }
    }
}
