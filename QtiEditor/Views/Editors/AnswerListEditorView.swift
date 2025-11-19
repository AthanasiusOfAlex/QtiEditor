//
//  AnswerListEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI
import AppKit  // For NSPasteboard

/// Helper class to expose answer list actions for keyboard shortcuts
@MainActor
class AnswerListActionsHelper: AnswerListActions {
    var selectedAnswerIDsBinding: Binding<Set<UUID>>?
    var editorState: EditorState?
    var question: QTIQuestion?

    var hasSelection: Bool {
        !(selectedAnswerIDsBinding?.wrappedValue.isEmpty ?? true)
    }

    var selectionCount: Int {
        selectedAnswerIDsBinding?.wrappedValue.count ?? 0
    }

    func copySelectedAnswers() {
        guard let question = question,
              let selectedIDs = selectedAnswerIDsBinding?.wrappedValue else { return }
        let selectedAnswers = question.answers.filter { selectedIDs.contains($0.id) }
        editorState?.copyAnswers(selectedAnswers)
    }

    func pasteAnswers() {
        guard let question = question else { return }
        editorState?.pasteAnswers(into: question)
    }

    func cutSelectedAnswers() {
        guard let question = question,
              let binding = selectedAnswerIDsBinding else { return }
        let selectedAnswers = question.answers.filter { binding.wrappedValue.contains($0.id) }
        editorState?.copyAnswers(selectedAnswers)
        question.answers.removeAll { binding.wrappedValue.contains($0.id) }
        binding.wrappedValue.removeAll()
    }

    func clearSelection() {
        selectedAnswerIDsBinding?.wrappedValue.removeAll()
    }
}

/// Container view for editing all answers of a question
struct AnswerListEditorView: View {
    @Environment(EditorState.self) private var editorState
    let question: QTIQuestion

    // Selection state
    @State private var selectedAnswerIDs: Set<UUID> = []
    @State private var lastSelectedID: UUID? = nil

    // Actions helper for keyboard shortcuts
    @State private var actionsHelper = AnswerListActionsHelper()
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Answers")
                    .font(.title2)
                    .bold()

                if !selectedAnswerIDs.isEmpty {
                    Text("(\(selectedAnswerIDs.count) selected)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection action buttons
                if !selectedAnswerIDs.isEmpty {
                    Button(action: copySelectedAnswers) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .help("Copy selected answer(s) (Shift-Cmd-C)")

                    Button(action: duplicateSelectedAnswers) {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    .buttonStyle(.bordered)
                    .help("Duplicate selected answer(s)")

                    Button(action: deleteSelectedAnswers) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .help("Delete selected answer(s)")
                }

                // Paste button (always visible when answers exist, to allow cross-question paste)
                if canPasteAnswers() {
                    Button(action: pasteAnswers) {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                    .help("Paste answer(s) (Shift-Cmd-V)")
                }

                // Add Answer button
                Button(action: addAnswer) {
                    Label("Add Answer", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.bordered)
                .help("Add a new answer choice")
            }

            // List of answers
            if question.answers.isEmpty {
                ContentUnavailableView(
                    "No Answers",
                    systemImage: "list.bullet",
                    description: Text("Click 'Add Answer' to create answer choices")
                )
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                List(selection: $selectedAnswerIDs) {
                    ForEach(Array(question.answers.enumerated()), id: \.element.id) { index, answer in
                        AnswerEditorView(
                            answer: answer,
                            index: index,
                            isSelected: selectedAnswerIDs.contains(answer.id),
                            onDelete: {
                                deleteAnswer(answer)
                            },
                            onDuplicate: {
                                duplicateAnswer(answer)
                            },
                            onCorrectChanged: { isCorrect in
                                handleCorrectChanged(for: answer, isCorrect: isCorrect)
                            }
                        )
                        .tag(answer.id)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    }
                    .onMove { fromOffsets, toOffset in
                        question.answers.move(fromOffsets: fromOffsets, toOffset: toOffset)
                        // Clear selection after reordering
                        selectedAnswerIDs.removeAll()
                        lastSelectedID = nil
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .focused($isFocused)
        .focusedSceneValue(\.answerListActions, isFocused ? actionsHelper : nil)
        .onAppear {
            actionsHelper.editorState = editorState
            actionsHelper.question = question
            actionsHelper.selectedAnswerIDsBinding = $selectedAnswerIDs
            // Give focus to answer list when it appears
            isFocused = true
        }
        .onChange(of: selectedAnswerIDs) { oldValue, newValue in
            // Update last selected ID for potential future use
            if let lastID = newValue.last {
                lastSelectedID = lastID
            } else if newValue.isEmpty {
                lastSelectedID = nil
            }
        }
    }

    // MARK: - Actions

    private func addAnswer() {
        let newAnswer = QTIAnswer(
            text: "<p>New answer choice</p>",
            isCorrect: false
        )
        question.answers.append(newAnswer)
    }

    private func deleteAnswer(_ answer: QTIAnswer) {
        question.answers.removeAll { $0.id == answer.id }
    }

    private func duplicateAnswer(_ answer: QTIAnswer) {
        // Find the index of the original answer
        guard let index = question.answers.firstIndex(where: { $0.id == answer.id }) else {
            return
        }

        // Create a deep copy
        let duplicatedAnswer = answer.duplicate(preserveCanvasIdentifier: false)

        // For multiple choice, reset isCorrect to avoid multiple correct answers
        if question.type == .multipleChoice || question.type == .trueFalse {
            duplicatedAnswer.isCorrect = false
        }

        // Insert after the original
        question.answers.insert(duplicatedAnswer, at: index + 1)
    }

    private func handleCorrectChanged(for answer: QTIAnswer, isCorrect: Bool) {
        // For multiple choice and true/false questions, only one answer can be correct
        if isCorrect && (question.type == .multipleChoice || question.type == .trueFalse) {
            // Uncheck all other answers
            for otherAnswer in question.answers where otherAnswer.id != answer.id {
                otherAnswer.isCorrect = false
            }
        }
    }

    // MARK: - Selection Management

    func clearSelection() {
        selectedAnswerIDs.removeAll()
        lastSelectedID = nil
    }

    // MARK: - Multi-Answer Operations

    func copySelectedAnswers() {
        let selectedAnswers = question.answers.filter { selectedAnswerIDs.contains($0.id) }
        editorState.copyAnswers(selectedAnswers)
    }

    private func duplicateSelectedAnswers() {
        let selectedAnswers = question.answers.filter { selectedAnswerIDs.contains($0.id) }
        guard !selectedAnswers.isEmpty else { return }

        // Find the last selected answer's index
        guard let lastIndex = question.answers.lastIndex(where: { selectedAnswerIDs.contains($0.id) }) else {
            return
        }

        var insertIndex = lastIndex + 1
        for answer in selectedAnswers {
            let duplicated = answer.duplicate(preserveCanvasIdentifier: false)

            // For multiple choice, reset isCorrect to avoid multiple correct answers
            if question.type == .multipleChoice || question.type == .trueFalse {
                duplicated.isCorrect = false
            }

            question.answers.insert(duplicated, at: insertIndex)
            insertIndex += 1
        }

        // Clear selection after duplication
        clearSelection()
    }

    private func deleteSelectedAnswers() {
        // Delete selected answers directly (could add confirmation dialog later if desired)
        question.answers.removeAll { selectedAnswerIDs.contains($0.id) }
        clearSelection()
    }

    func pasteAnswers() {
        editorState.pasteAnswers(into: question)
    }

    func cutSelectedAnswers() {
        copySelectedAnswers()
        deleteSelectedAnswers()
    }

    private func canPasteAnswers() -> Bool {
        let pasteboard = NSPasteboard.general
        // Check if we have answers array on the clipboard
        return pasteboard.types?.contains(NSPasteboard.PasteboardType("com.qti-editor.answers-array")) ?? false
    }
}

#Preview {
    let question = QTIQuestion(
        type: .multipleChoice,
        questionText: "<p>What is the capital of France?</p>",
        points: 1.0,
        answers: [
            QTIAnswer(text: "<p>Paris</p>", isCorrect: true),
            QTIAnswer(text: "<p>London</p>", isCorrect: false),
            QTIAnswer(text: "<p>Berlin</p>", isCorrect: false),
            QTIAnswer(text: "<p>Madrid</p>", isCorrect: false)
        ]
    )

    return AnswerListEditorView(question: question)
        .environment(EditorState(document: QTIDocument.empty()))
        .frame(width: 700, height: 600)
}
