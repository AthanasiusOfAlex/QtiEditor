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

    /// Currently selected question ID (focused for editing)
    var selectedQuestionID: UUID?

    /// Set of selected question IDs for multi-selection operations
    var selectedQuestionIDs: Set<UUID> = []

    /// Dictionary mapping question IDs to their selected answer IDs (for persistence)
    private var answerSelectionByQuestion: [UUID: Set<UUID>] = [:]

    /// Set of selected answer IDs for the current question
    var selectedAnswerIDs: Set<UUID> {
        get {
            guard let questionID = selectedQuestionID else { return [] }
            return answerSelectionByQuestion[questionID] ?? []
        }
        set {
            guard let questionID = selectedQuestionID else { return }
            answerSelectionByQuestion[questionID] = newValue
        }
    }

    /// Current editor mode (HTML or Rich Text)
    var editorMode: EditorMode = .richText

    // MARK: - Global Points
    /// Whether global points mode is enabled
    var isGlobalPointsEnabled: Bool = false {
        didSet {
            if isGlobalPointsEnabled {
                applyGlobalPoints()
            }
        }
    }

    /// Global points value
    var globalPointsValue: Double = 1.0 {
        didSet {
            if isGlobalPointsEnabled {
                applyGlobalPoints()
            }
        }
    }

    /// Left panel visibility (Questions list)
    var isLeftPanelVisible: Bool = true {
        didSet {
            UserDefaults.standard.set(isLeftPanelVisible, forKey: "isLeftPanelVisible")
        }
    }

    /// Left panel width (persisted)
    var leftPanelWidth: CGFloat = 250 {
        didSet {
            UserDefaults.standard.set(leftPanelWidth, forKey: "leftPanelWidth")
        }
    }

    /// Right panel visibility (Utilities: Search, Quiz Settings)
    var isRightPanelVisible: Bool = true {
        didSet {
            UserDefaults.standard.set(isRightPanelVisible, forKey: "isRightPanelVisible")
        }
    }

    /// Right panel width (persisted)
    var rightPanelWidth: CGFloat = 300 {
        didSet {
            UserDefaults.standard.set(rightPanelWidth, forKey: "rightPanelWidth")
        }
    }

    /// Selected tab in the right panel
    var rightPanelTab: RightPanelTab = .quizSettings {
        didSet {
            UserDefaults.standard.set(rightPanelTab.rawValue, forKey: "rightPanelTab")
        }
    }

    /// Search panel visibility (deprecated - now part of right panel)
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

    /// Whether the document has unsaved changes
    var isDocumentEdited: Bool = false

    init(document: QTIDocument? = nil) {
        // Set the document (may be nil - that's okay, will be created later)
        self.document = document

        // Load panel visibility from UserDefaults (default to true if not set)
        if UserDefaults.standard.object(forKey: "isLeftPanelVisible") != nil {
            self.isLeftPanelVisible = UserDefaults.standard.bool(forKey: "isLeftPanelVisible")
        }
        if UserDefaults.standard.object(forKey: "isRightPanelVisible") != nil {
            self.isRightPanelVisible = UserDefaults.standard.bool(forKey: "isRightPanelVisible")
        }

        // Load panel widths from UserDefaults (defaults: left=250, right=300)
        if UserDefaults.standard.object(forKey: "leftPanelWidth") != nil {
            self.leftPanelWidth = CGFloat(UserDefaults.standard.double(forKey: "leftPanelWidth"))
        }
        if UserDefaults.standard.object(forKey: "rightPanelWidth") != nil {
            self.rightPanelWidth = CGFloat(UserDefaults.standard.double(forKey: "rightPanelWidth"))
        }

        // Load right panel tab selection (default to quizSettings)
        if let rawValue = UserDefaults.standard.string(forKey: "rightPanelTab"),
           let tab = RightPanelTab(rawValue: rawValue) {
            self.rightPanelTab = tab
        }
    }

    /// Returns the currently selected question, if any
    var selectedQuestion: QTIQuestion? {
        guard let id = selectedQuestionID,
              let document = document else {
            return nil
        }
        return document.questions.first { $0.id == id }
    }

    /// Apply global points to all questions
    private func applyGlobalPoints() {
        guard let document = document else { return }
        for question in document.questions {
            if question.points != globalPointsValue {
                question.points = globalPointsValue
                isDocumentEdited = true
            }
        }
    }

    /// Ensures that an answer is selected for the current question
    /// If no answer is selected and the question has answers, selects the first one
    func ensureAnswerSelected() {
        guard let question = selectedQuestion else { return }

        // If no answers, nothing to select
        if question.answers.isEmpty {
            return
        }

        // If an answer is already selected and it still exists, keep it
        if !selectedAnswerIDs.isEmpty {
            let validAnswerIDs = Set(question.answers.map { $0.id })
            // Keep only valid selections
            let validSelections = selectedAnswerIDs.intersection(validAnswerIDs)
            if !validSelections.isEmpty {
                selectedAnswerIDs = validSelections
                return
            }
        }

        // No valid selection - select the first answer
        if let firstAnswer = question.answers.first {
            selectedAnswerIDs = [firstAnswer.id]
        }
    }

    /// Create a new question and add it to the document
    func addQuestion(type: QTIQuestionType = .multipleChoice) {
        guard let document = document else { return }

        let points = isGlobalPointsEnabled ? globalPointsValue : 1.0

        let question = QTIQuestion(
            type: type,
            questionText: "<p>Enter your question here...</p>",
            points: points,
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
        selectedQuestionIDs = [question.id]
        isDocumentEdited = true
    }

    /// Delete the specified question
    func deleteQuestion(_ question: QTIQuestion) {
        guard let document = document else { return }
        document.questions.removeAll { $0.id == question.id }
        if selectedQuestionID == question.id {
            selectedQuestionID = nil
        }
        selectedQuestionIDs.remove(question.id)
        isDocumentEdited = true
    }

    /// Delete all currently selected questions
    func deleteSelectedQuestions() {
        guard let document = document else { return }

        // If no multi-selection, delete the focused question
        let idsToDelete = selectedQuestionIDs.isEmpty
            ? (selectedQuestionID.map { Set([$0]) } ?? [])
            : selectedQuestionIDs

        document.questions.removeAll { idsToDelete.contains($0.id) }

        // Clear selections
        if let selectedID = selectedQuestionID, idsToDelete.contains(selectedID) {
            selectedQuestionID = nil
        }
        selectedQuestionIDs.removeAll()
        isDocumentEdited = true
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
        selectedQuestionIDs = [duplicatedQuestion.id]
        isDocumentEdited = true
    }

    /// Duplicate the currently selected question
    func duplicateSelectedQuestion() {
        guard let question = selectedQuestion else { return }
        duplicateQuestion(question)
    }

    /// Duplicate all currently selected questions
    func duplicateSelectedQuestions() {
        guard let document = document else { return }

        // If no multi-selection, duplicate the focused question
        let idsToDuplicate = selectedQuestionIDs.isEmpty
            ? (selectedQuestionID.map { Set([$0]) } ?? [])
            : selectedQuestionIDs

        // Find questions to duplicate (in order)
        let questionsToDuplicate = document.questions.filter { idsToDuplicate.contains($0.id) }

        // Duplicate each question and insert after the original
        var newQuestionIDs: Set<UUID> = []
        for question in questionsToDuplicate.reversed() {
            guard let index = document.questions.firstIndex(where: { $0.id == question.id }) else {
                continue
            }

            let duplicatedQuestion = question.duplicate(preserveCanvasIdentifier: false)
            document.questions.insert(duplicatedQuestion, at: index + 1)
            newQuestionIDs.insert(duplicatedQuestion.id)
        }

        // Select the duplicated questions
        selectedQuestionIDs = newQuestionIDs
        selectedQuestionID = newQuestionIDs.first
        isDocumentEdited = true
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
        isDocumentEdited = true
    }

    // MARK: - Copy/Paste Operations

    /// Custom pasteboard type for QTI questions
    private static let questionPasteboardType = NSPasteboard.PasteboardType("com.qti-editor.question")

    /// Custom pasteboard type for QTI answers
    private static let answerPasteboardType = NSPasteboard.PasteboardType("com.qti-editor.answer")

    /// Custom pasteboard type for multiple QTI answers
    private static let answersArrayPasteboardType = NSPasteboard.PasteboardType("com.qti-editor.answers-array")

    /// Copy the selected question(s) to the pasteboard
    func copySelectedQuestion() {
        guard let document = document else { return }

        // If no multi-selection, copy the focused question
        let idsToCopy = selectedQuestionIDs.isEmpty
            ? (selectedQuestionID.map { Set([$0]) } ?? [])
            : selectedQuestionIDs

        // Find questions to copy (in order)
        let questionsToCopy = document.questions.filter { idsToCopy.contains($0.id) }

        guard !questionsToCopy.isEmpty else { return }

        let pasteboard = NSPasteboard.general

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(questionsToCopy)

            // Use NSPasteboardItem (modern API)
            let item = NSPasteboardItem()
            item.setData(data, forType: Self.questionPasteboardType)

            pasteboard.clearContents()
            pasteboard.writeObjects([item])
        } catch {
            showError("Failed to copy question(s): \(error.localizedDescription)")
        }
    }

    /// Copy a specific question to the pasteboard
    func copyQuestion(_ question: QTIQuestion) {
        let pasteboard = NSPasteboard.general

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode([question])

            // Use NSPasteboardItem (modern API)
            let item = NSPasteboardItem()
            item.setData(data, forType: Self.questionPasteboardType)

            // clearContents() + writeObjects() is the atomic modern pattern
            pasteboard.clearContents()
            pasteboard.writeObjects([item])
        } catch {
            showError("Failed to copy question: \(error.localizedDescription)")
        }
    }

    /// Paste question(s) from the pasteboard
    func pasteQuestion() {
        guard let document = document else { return }

        let pasteboard = NSPasteboard.general
        guard let data = pasteboard.data(forType: Self.questionPasteboardType) else { return }

        do {
            let decoder = JSONDecoder()
            let pastedQuestions = try decoder.decode([QTIQuestion].self, from: data)

            guard !pastedQuestions.isEmpty else { return }

            // Generate new UUIDs for all pasted questions
            var newQuestions: [QTIQuestion] = []
            var newQuestionIDs: Set<UUID> = []

            for pastedQuestion in pastedQuestions {
                let newQuestion = pastedQuestion.duplicate(preserveCanvasIdentifier: false)
                newQuestions.append(newQuestion)
                newQuestionIDs.insert(newQuestion.id)
            }

            // Insert after currently selected question, or at the end
            if let selectedID = selectedQuestionID,
               let index = document.questions.firstIndex(where: { $0.id == selectedID }) {
                // Insert all questions starting from index + 1
                for (offset, question) in newQuestions.enumerated() {
                    document.questions.insert(question, at: index + 1 + offset)
                }
            } else {
                document.questions.append(contentsOf: newQuestions)
            }

            // Select the pasted questions
            selectedQuestionIDs = newQuestionIDs
            selectedQuestionID = newQuestions.first?.id
            isDocumentEdited = true
        } catch {
            showError("Failed to paste question(s): \(error.localizedDescription)")
        }
    }

    /// Paste question(s) from the pasteboard after a specific question
    /// - Parameter afterQuestion: The question to paste after
    func pasteQuestionAfter(_ afterQuestion: QTIQuestion) {
        guard let document = document else { return }
        guard let index = document.questions.firstIndex(where: { $0.id == afterQuestion.id }) else { return }

        let pasteboard = NSPasteboard.general
        guard let data = pasteboard.data(forType: Self.questionPasteboardType) else { return }

        do {
            let decoder = JSONDecoder()
            let pastedQuestions = try decoder.decode([QTIQuestion].self, from: data)

            guard !pastedQuestions.isEmpty else { return }

            // Generate new UUIDs for all pasted questions
            var newQuestions: [QTIQuestion] = []
            var newQuestionIDs: Set<UUID> = []

            for pastedQuestion in pastedQuestions {
                let newQuestion = pastedQuestion.duplicate(preserveCanvasIdentifier: false)
                newQuestions.append(newQuestion)
                newQuestionIDs.insert(newQuestion.id)
            }

            // Insert all questions starting after the specified question
            for (offset, question) in newQuestions.enumerated() {
                document.questions.insert(question, at: index + 1 + offset)
            }

            // Select the pasted questions
            selectedQuestionIDs = newQuestionIDs
            selectedQuestionID = newQuestions.first?.id
            isDocumentEdited = true
        } catch {
            showError("Failed to paste question(s): \(error.localizedDescription)")
        }
    }

    /// Check if pasteboard contains questions
    func canPasteQuestion() -> Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.types?.contains(Self.questionPasteboardType) ?? false
    }

    /// Check if pasteboard contains answers
    func canPasteAnswers() -> Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.types?.contains(Self.answersArrayPasteboardType) ?? false
    }

    /// Get the count of questions in the clipboard (with race condition protection)
    func clipboardQuestionCount() -> Int {
        let pasteboard = NSPasteboard.general

        // Safe Read Pattern: Check changeCount before and after read
        let beforeChangeCount = pasteboard.changeCount

        guard let data = pasteboard.data(forType: Self.questionPasteboardType) else {
            return 0
        }

        let afterChangeCount = pasteboard.changeCount

        // Race condition detection: If changeCount changed during read, discard and retry
        if beforeChangeCount != afterChangeCount {
            return clipboardQuestionCount() // Recursive retry
        }

        // Data is consistent - decode it
        do {
            let decoder = JSONDecoder()
            let questions = try decoder.decode([QTIQuestion].self, from: data)
            return questions.count
        } catch {
            return 0
        }
    }

    /// Get the count of answers in the clipboard (with race condition protection)
    func clipboardAnswerCount() -> Int {
        let pasteboard = NSPasteboard.general

        // Safe Read Pattern: Check changeCount before and after read
        let beforeChangeCount = pasteboard.changeCount

        guard let data = pasteboard.data(forType: Self.answersArrayPasteboardType) else {
            return 0
        }

        let afterChangeCount = pasteboard.changeCount

        // Race condition detection: If changeCount changed during read, discard and retry
        if beforeChangeCount != afterChangeCount {
            return clipboardAnswerCount() // Recursive retry
        }

        // Data is consistent - decode it
        do {
            let decoder = JSONDecoder()
            let answers = try decoder.decode([QTIAnswer].self, from: data)
            return answers.count
        } catch {
            return 0
        }
    }

    /// Paste answers from pasteboard into a specific question
    /// - Parameter question: The question to paste answers into
    func pasteAnswersIntoQuestion(_ question: QTIQuestion) {
        pasteAnswers(into: question)
    }

    /// Copy an answer to the pasteboard
    /// - Parameter answer: The answer to copy
    func copyAnswer(_ answer: QTIAnswer) {
        let pasteboard = NSPasteboard.general

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(answer)

            // Use NSPasteboardItem (modern API)
            let item = NSPasteboardItem()
            item.setData(data, forType: Self.answerPasteboardType)

            pasteboard.clearContents()
            pasteboard.writeObjects([item])
        } catch {
            showError("Failed to copy answer: \(error.localizedDescription)")
        }
    }

    /// Paste an answer from the pasteboard into a question
    /// - Parameter question: The question to paste into
    func pasteAnswer(into question: QTIQuestion) {
        let pasteboard = NSPasteboard.general
        guard let data = pasteboard.data(forType: Self.answerPasteboardType) else { return }

        do {
            let decoder = JSONDecoder()
            let pastedAnswer = try decoder.decode(QTIAnswer.self, from: data)

            // Generate new UUID for the pasted answer
            let newAnswer = pastedAnswer.duplicate(preserveCanvasIdentifier: false)

            // For multiple choice, ensure the new answer is not correct
            if question.type == .multipleChoice || question.type == .trueFalse {
                newAnswer.isCorrect = false
            }

            // Add at the end of the answer list
            question.answers.append(newAnswer)
            isDocumentEdited = true
        } catch {
            showError("Failed to paste answer: \(error.localizedDescription)")
        }
    }

    /// Copy multiple answers to the pasteboard
    /// - Parameter answers: The answers to copy
    func copyAnswers(_ answers: [QTIAnswer]) {
        guard !answers.isEmpty else { return }

        let pasteboard = NSPasteboard.general

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(answers)

            // Use NSPasteboardItem (modern API)
            let item = NSPasteboardItem()
            item.setData(data, forType: Self.answersArrayPasteboardType)

            // clearContents() + writeObjects() is the atomic modern pattern
            pasteboard.clearContents()
            pasteboard.writeObjects([item])
        } catch {
            showError("Failed to copy answers: \(error.localizedDescription)")
        }
    }

    /// Paste multiple answers from the pasteboard into a question
    /// - Parameters:
    ///   - question: The question to paste into
    ///   - afterIndex: Optional index to insert after (if nil, appends to end)
    func pasteAnswers(into question: QTIQuestion, afterIndex: Int? = nil) {
        let pasteboard = NSPasteboard.general
        guard let data = pasteboard.data(forType: Self.answersArrayPasteboardType) else { return }

        do {
            let decoder = JSONDecoder()
            let pastedAnswers = try decoder.decode([QTIAnswer].self, from: data)

            var insertIndex = afterIndex.map { $0 + 1 } ?? question.answers.count

            for pastedAnswer in pastedAnswers {
                // Generate new UUID for each pasted answer
                let newAnswer = pastedAnswer.duplicate(preserveCanvasIdentifier: false)

                // For multiple choice, ensure pasted answers are not correct
                if question.type == .multipleChoice || question.type == .trueFalse {
                    newAnswer.isCorrect = false
                }

                // Insert at the specified position or append to end
                question.answers.insert(newAnswer, at: insertIndex)
                insertIndex += 1
            }

            isDocumentEdited = true
        } catch {
            showError("Failed to paste answers: \(error.localizedDescription)")
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
            self.isDocumentEdited = false
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
            self.isDocumentEdited = false
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
            self.isDocumentEdited = false
        } catch let error as QTIError {
            showError(error.localizedDescription)
        } catch {
            showError("Failed to save document: \(error.localizedDescription)")
        }
    }

    /// Creates a new empty document
    func createNewDocument() async {
        document = await documentManager.createNewDocument()
        selectedQuestionID = nil
        isDocumentEdited = false
    }

    // MARK: - Document State

    /// Mark the document as having unsaved changes
    /// Call this method when modifying question/answer properties directly
    func markDocumentEdited() {
        isDocumentEdited = true
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
