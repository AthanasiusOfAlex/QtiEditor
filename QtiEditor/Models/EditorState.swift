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
