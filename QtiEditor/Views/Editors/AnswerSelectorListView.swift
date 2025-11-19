//
//  AnswerSelectorListView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI
import AppKit

/// List view for selecting which answer to edit
/// Similar to QuestionListView but for answers
struct AnswerSelectorListView: View {
    @Environment(EditorState.self) private var editorState
    let question: QTIQuestion

    // Selection state (supports multi-select for bulk operations)
    @Binding var selectedAnswerIDs: Set<UUID>

    @State private var showDeleteConfirmation = false
    @FocusState private var isListFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header with add button and bulk actions
            HStack {
                Text("Answers (\(question.answers.count))")
                    .font(.headline)

                Spacer()

                // Add answer button
                Button(action: addAnswer) {
                    Label("Add", systemImage: "plus.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help("Add a new answer")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))

            Divider()

            // Answer list
            if question.answers.isEmpty {
                ContentUnavailableView(
                    "No Answers",
                    systemImage: "list.bullet",
                    description: Text("Click + to add an answer")
                )
                .frame(maxHeight: .infinity)
            } else {
                List(selection: $selectedAnswerIDs) {
                    ForEach(Array(question.answers.enumerated()), id: \.element.id) { index, answer in
                        AnswerRowView(
                            answer: answer,
                            index: index,
                            isSelected: selectedAnswerIDs.contains(answer.id)
                        )
                        .tag(answer.id)
                        .contextMenu {
                            buildContextMenu(for: answer)
                        }
                    }
                    .onMove { fromOffsets, toOffset in
                        question.answers.move(fromOffsets: fromOffsets, toOffset: toOffset)
                        editorState.markDocumentEdited()
                    }
                }
                .listStyle(.sidebar)
                .focused($isListFocused)
                .focusedSceneValue(\.focusContext, isListFocused ? .answerList : nil)
                .focusedSceneValue(\.focusedActions, isListFocused ? FocusedActions(
                    copy: { copySelectedAnswers() },
                    cut: {
                        copySelectedAnswers()
                        performDelete()
                    },
                    paste: { pasteAnswersAtEnd() },
                    selectAll: { selectAllAnswers() },
                    delete: { confirmDelete() }
                ) : nil)
            }
        }
        .frame(minWidth: 200, idealWidth: 250)
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

    // MARK: - Context Menu

    @ViewBuilder
    private func buildContextMenu(for answer: QTIAnswer) -> some View {
        Button("Copy Answer") {
            editorState.copyAnswers([answer])
        }

        // Unified paste button with dynamic label
        Button(pasteButtonLabel()) {
            pasteAnswersAfter(answer)
        }
        .disabled(!canPasteAnswers())

        Button("Duplicate Answer") {
            duplicateAnswer(answer)
        }

        Divider()

        Button("Delete Answer", role: .destructive) {
            deleteAnswer(answer)
        }
    }

    /// Generate label for paste button based on clipboard contents
    /// Reads clipboard directly to ensure fresh data
    private func pasteButtonLabel() -> String {
        let answerCount = editorState.clipboardAnswerCount()
        return answerCount == 1 ? "Paste Answer" : "Paste Answers"
    }

    /// Check if answers can be pasted
    /// Reads clipboard directly to ensure fresh data
    private func canPasteAnswers() -> Bool {
        return editorState.clipboardAnswerCount() > 0
    }

    // MARK: - Actions

    private func addAnswer() {
        let newAnswer = QTIAnswer(
            text: "<p>New answer choice</p>",
            isCorrect: false
        )
        question.answers.append(newAnswer)
        editorState.markDocumentEdited()

        // Auto-select the new answer
        selectedAnswerIDs = [newAnswer.id]
    }

    private func deleteAnswer(_ answer: QTIAnswer) {
        question.answers.removeAll { $0.id == answer.id }
        editorState.markDocumentEdited()
        selectedAnswerIDs.remove(answer.id)
    }

    private func duplicateAnswer(_ answer: QTIAnswer) {
        guard let index = question.answers.firstIndex(where: { $0.id == answer.id }) else { return }

        let duplicated = answer.duplicate(preserveCanvasIdentifier: false)

        // Reset isCorrect for single-answer question types
        if question.type == .multipleChoice || question.type == .trueFalse {
            duplicated.isCorrect = false
        }

        question.answers.insert(duplicated, at: index + 1)
        editorState.markDocumentEdited()
    }

    private func copySelectedAnswers() {
        let answers = question.answers.filter { selectedAnswerIDs.contains($0.id) }
        editorState.copyAnswers(answers)
    }

    private func duplicateSelectedAnswers() {
        let selectedAnswers = question.answers.filter { selectedAnswerIDs.contains($0.id) }
        guard !selectedAnswers.isEmpty else { return }

        guard let lastIndex = question.answers.lastIndex(where: { selectedAnswerIDs.contains($0.id) }) else {
            return
        }

        var insertIndex = lastIndex + 1
        for answer in selectedAnswers {
            let duplicated = answer.duplicate(preserveCanvasIdentifier: false)

            if question.type == .multipleChoice || question.type == .trueFalse {
                duplicated.isCorrect = false
            }

            question.answers.insert(duplicated, at: insertIndex)
            insertIndex += 1
        }

        editorState.markDocumentEdited()
        selectedAnswerIDs.removeAll()
    }

    private func confirmDelete() {
        if selectedAnswerIDs.count > 1 {
            showDeleteConfirmation = true
        } else {
            performDelete()
        }
    }

    private func performDelete() {
        question.answers.removeAll { selectedAnswerIDs.contains($0.id) }
        editorState.markDocumentEdited()
        selectedAnswerIDs.removeAll()
    }

    private func selectAllAnswers() {
        selectedAnswerIDs = Set(question.answers.map { $0.id })
    }

    private func pasteAnswersAtEnd() {
        editorState.pasteAnswers(into: question)
    }

    private func pasteAnswersAfter(_ answer: QTIAnswer) {
        guard let index = question.answers.firstIndex(where: { $0.id == answer.id }) else { return }
        editorState.pasteAnswers(into: question, afterIndex: index)
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
}

/// Individual answer row in the selector list
struct AnswerRowView: View {
    let answer: QTIAnswer
    let index: Int
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Correct/incorrect indicator
            Image(systemName: answer.isCorrect ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(answer.isCorrect ? .green : .secondary)

            // Answer content
            VStack(alignment: .leading, spacing: 2) {
                // Answer number
                Text("Answer \(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Preview text
                Text(stripHTML(answer.text))
                    .font(.body)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    private func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    @Previewable @State var selectedIDs: Set<UUID> = []

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

    AnswerSelectorListView(
        question: question,
        selectedAnswerIDs: $selectedIDs
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .frame(width: 250, height: 400)
}
