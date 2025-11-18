//
//  EditorState.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation
import SwiftUI
import AppKit

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
    /// Document manager for file operations
    let documentManager = DocumentManager()

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

    /// Search scope
    var searchScope: SearchScope = .allQuestions

    /// Search field
    var searchField: SearchField = .all

    /// Current search match being viewed (for highlighting)
    var currentSearchMatch: SearchMatch?

    /// Alert message to display
    var alertMessage: String?

    /// Whether an alert should be shown
    var showAlert: Bool = false

    /// Whether a file operation is in progress
    var isLoading: Bool = false

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

    /// Duplicate the specified question and insert it after the original
    /// - Parameter question: The question to duplicate
    func duplicateQuestion(_ question: QTIQuestion) {
        guard let document = document else { return }

        // Find the index of the original question
        guard let index = document.questions.firstIndex(where: { $0.id == question.id }) else {
            return
        }

        // Create a deep copy
        let duplicatedQuestion = question.duplicate(preserveCanvasIdentifier: false)

        // Insert after the original
        document.questions.insert(duplicatedQuestion, at: index + 1)

        // Select the new question
        selectedQuestionID = duplicatedQuestion.id
    }

    /// Duplicate the currently selected question
    func duplicateSelectedQuestion() {
        guard let question = selectedQuestion else { return }
        duplicateQuestion(question)
    }

    /// Duplicate an answer and add it after the original
    /// - Parameters:
    ///   - answer: The answer to duplicate
    ///   - question: The question containing the answer
    func duplicateAnswer(_ answer: QTIAnswer, in question: QTIQuestion) {
        // Find the index of the original answer
        guard let index = question.answers.firstIndex(where: { $0.id == answer.id }) else {
            return
        }

        // Create a deep copy
        let duplicatedAnswer = answer.duplicate(preserveCanvasIdentifier: false)

        // For multiple choice, reset isCorrect to avoid multiple correct answers
        if question.type == .multipleChoice {
            duplicatedAnswer.isCorrect = false
        }

        // Insert after the original
        question.answers.insert(duplicatedAnswer, at: index + 1)
    }

    // MARK: - Copy/Paste Operations

    /// Custom pasteboard type for QTI questions
    private static let questionPasteboardType = NSPasteboard.PasteboardType("com.qti-editor.question")

    /// Copy the selected question to the pasteboard
    func copySelectedQuestion() {
        guard let question = selectedQuestion else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(question)
            pasteboard.setData(data, forType: Self.questionPasteboardType)
        } catch {
            showError("Failed to copy question: \(error.localizedDescription)")
        }
    }

    /// Paste a question from the pasteboard
    func pasteQuestion() {
        guard document != nil else { return }

        let pasteboard = NSPasteboard.general
        guard let data = pasteboard.data(forType: Self.questionPasteboardType) else { return }

        do {
            let decoder = JSONDecoder()
            let pastedQuestion = try decoder.decode(QTIQuestion.self, from: data)

            // Generate new UUIDs for the pasted question
            let newQuestion = pastedQuestion.duplicate(preserveCanvasIdentifier: false)

            // Insert after currently selected question, or at the end
            if let selectedID = selectedQuestionID,
               let index = document?.questions.firstIndex(where: { $0.id == selectedID }) {
                document?.questions.insert(newQuestion, at: index + 1)
            } else {
                document?.questions.append(newQuestion)
            }

            // Select the pasted question
            selectedQuestionID = newQuestion.id
        } catch {
            showError("Failed to paste question: \(error.localizedDescription)")
        }
    }

    // MARK: - File Operations

    /// Opens a QTI document from a file
    /// - Parameter url: URL to the .imscc file
    func openDocument(from url: URL) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedDocument = try await documentManager.openDocument(from: url)
            self.document = loadedDocument
            self.selectedQuestionID = loadedDocument.questions.first?.id
        } catch let error as QTIError {
            showError(error.localizedDescription)
        } catch {
            showError("Failed to open document: \(error.localizedDescription)")
        }
    }

    /// Saves the current document
    func saveDocument() async {
        guard let document = document else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await documentManager.saveDocument(document)
        } catch let error as QTIError {
            showError(error.localizedDescription)
        } catch {
            showError("Failed to save document: \(error.localizedDescription)")
        }
    }

    /// Saves the current document to a new location
    /// - Parameter url: Destination URL
    func saveDocument(to url: URL) async {
        guard let document = document else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await documentManager.saveDocument(document, to: url)
        } catch let error as QTIError {
            showError(error.localizedDescription)
        } catch {
            showError("Failed to save document: \(error.localizedDescription)")
        }
    }

    /// Creates a new empty document
    func createNewDocument() {
        document = documentManager.createNewDocument()
        selectedQuestionID = nil
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
