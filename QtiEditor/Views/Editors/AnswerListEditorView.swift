//
//  AnswerListEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI
import AppKit  // For NSPasteboard

/// Container view for editing all answers of a question
struct AnswerListEditorView: View {
    @Environment(EditorState.self) private var editorState
    let question: QTIQuestion

    // Selection state
    @State private var selectedAnswerIDs: Set<UUID> = []
    @State private var lastSelectedID: UUID? = nil

    // Confirmation dialog
    @State private var showDeleteConfirmation = false

    // Track if clipboard has answers (for immediate paste button visibility)
    @State private var clipboardHasAnswers = false

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
                    .help("Copy selected answer(s)")
                }

                // Paste button (visible when clipboard has answers)
                if clipboardHasAnswers {
                    Button(action: pasteAnswersAtEnd) {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.bordered)
                    .help("Paste answer(s) at end")
                }

                if !selectedAnswerIDs.isEmpty {
                    Button(action: duplicateSelectedAnswers) {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    .buttonStyle(.bordered)
                    .help("Duplicate selected answer(s)")

                    Button(action: confirmDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .help("Delete selected answer(s)")
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
                            hasMultipleSelected: selectedAnswerIDs.count > 1,
                            canPaste: clipboardHasAnswers,
                            onDelete: {
                                deleteAnswer(answer)
                            },
                            onDuplicate: {
                                duplicateAnswer(answer)
                            },
                            onCopy: {
                                // Single answer copy from context menu
                                editorState.copyAnswer(answer)
                                clipboardHasAnswers = true
                            },
                            onPasteAfter: {
                                pasteAnswersAfter(answer)
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
        .onAppear {
            checkClipboard()
        }
        .confirmationDialog(
            deleteDialogTitle(),
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                performDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteDialogMessage())
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

    // MARK: - Multi-Answer Operations

    private func copySelectedAnswers() {
        let selectedAnswers = question.answers.filter { selectedAnswerIDs.contains($0.id) }
        editorState.copyAnswers(selectedAnswers)
        // Update clipboard state immediately so Paste button appears
        clipboardHasAnswers = true
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
        selectedAnswerIDs.removeAll()
        lastSelectedID = nil
    }

    private func confirmDelete() {
        // Show confirmation dialog for multiple deletes
        if selectedAnswerIDs.count > 1 {
            showDeleteConfirmation = true
        } else {
            performDelete()
        }
    }

    private func performDelete() {
        question.answers.removeAll { selectedAnswerIDs.contains($0.id) }
        selectedAnswerIDs.removeAll()
        lastSelectedID = nil
    }

    private func deleteDialogTitle() -> String {
        let count = selectedAnswerIDs.count
        return count > 1 ? "Delete \(count) Answers?" : "Delete Answer?"
    }

    private func deleteDialogMessage() -> String {
        let count = selectedAnswerIDs.count
        return count > 1
            ? "Are you sure you want to delete \(count) answers? This action cannot be undone."
            : "Are you sure you want to delete this answer? This action cannot be undone."
    }

    private func pasteAnswersAtEnd() {
        editorState.pasteAnswers(into: question)
    }

    private func pasteAnswersAfter(_ answer: QTIAnswer) {
        guard let index = question.answers.firstIndex(where: { $0.id == answer.id }) else { return }
        editorState.pasteAnswers(into: question, afterIndex: index)
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        clipboardHasAnswers = pasteboard.types?.contains(NSPasteboard.PasteboardType("com.qti-editor.answers-array")) ?? false
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
