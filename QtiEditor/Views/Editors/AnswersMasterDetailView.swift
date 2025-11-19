//
//  AnswersMasterDetailView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Master-detail view for editing answers
/// Left: List of answers for selection
/// Right: Editor for selected answer(s)
struct AnswersMasterDetailView: View {
    @Environment(EditorState.self) private var editorState
    let question: QTIQuestion
    @State private var selectedAnswerIDs: Set<UUID> = []

    var body: some View {
        HSplitView {
            // Left: Answer selector list (narrow like a sidebar)
            AnswerSelectorListView(
                question: question,
                selectedAnswerIDs: $selectedAnswerIDs
            )
            .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)

            // Right: Single answer editor (takes most of the space)
            SingleAnswerEditorView(
                question: question,
                selectedAnswerIDs: selectedAnswerIDs,
                onCopySelected: copySelectedAnswers,
                onDuplicateSelected: duplicateSelectedAnswers,
                onDeleteSelected: deleteSelectedAnswers
            )
            .frame(minWidth: 400)
        }
    }

    // MARK: - Bulk Operations

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

    private func deleteSelectedAnswers() {
        question.answers.removeAll { selectedAnswerIDs.contains($0.id) }
        editorState.markDocumentEdited()
        selectedAnswerIDs.removeAll()
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

    AnswersMasterDetailView(question: question)
        .environment(EditorState(document: QTIDocument.empty()))
        .frame(width: 800, height: 400)
}
