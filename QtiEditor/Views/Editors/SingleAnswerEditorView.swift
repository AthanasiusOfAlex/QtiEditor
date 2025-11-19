//
//  SingleAnswerEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Editor for a single selected answer
/// Shows different states: no selection, single selection, multi-selection
struct SingleAnswerEditorView: View {
    @Environment(EditorState.self) private var editorState
    let question: QTIQuestion
    let selectedAnswerIDs: Set<UUID>
    let onCopySelected: () -> Void
    let onDuplicateSelected: () -> Void
    let onDeleteSelected: () -> Void

    var body: some View {
        Group {
            if selectedAnswerIDs.isEmpty {
                // No selection
                noSelectionView
            } else if selectedAnswerIDs.count == 1, let answerID = selectedAnswerIDs.first,
                      let answer = question.answers.first(where: { $0.id == answerID }),
                      let index = question.answers.firstIndex(where: { $0.id == answerID }) {
                // Single selection - show editor
                singleAnswerEditor(answer: answer, index: index)
            } else {
                // Multiple selection
                multipleSelectionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Selection View

    private var noSelectionView: some View {
        ContentUnavailableView(
            "No Answer Selected",
            systemImage: "square.and.pencil",
            description: Text("Select an answer from the list to edit")
        )
    }

    // MARK: - Multiple Selection View

    private var multipleSelectionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("\(selectedAnswerIDs.count) Answers Selected")
                .font(.title2)
                .fontWeight(.medium)

            // Bulk action buttons
            HStack(spacing: 16) {
                Button(action: onCopySelected) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .help("Copy selected answers (Cmd+C)")

                Button(action: onDuplicateSelected) {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                .buttonStyle(.bordered)
                .help("Duplicate selected answers (Cmd+D)")

                Button(action: onDeleteSelected) {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .help("Delete selected answers (Delete)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Single Answer Editor

    @ViewBuilder
    private func singleAnswerEditor(answer: QTIAnswer, index: Int) -> some View {
        @Bindable var answer = answer

        VStack(spacing: 0) {
            // Header
            HStack {
                Toggle("Correct Answer", isOn: Binding(
                    get: { answer.isCorrect },
                    set: { newValue in
                        answer.isCorrect = newValue
                        editorState.markDocumentEdited()
                        handleCorrectChanged(for: answer, isCorrect: newValue)
                    }
                ))
                .toggleStyle(.checkbox)

                Spacer()

                EditorModeToggle()
            }
            .padding()
            .background(Color.secondary.opacity(0.05))

            Divider()

            // Editor
            if editorState.editorMode == .html {
                VStack(spacing: 0) {
                    // HTML toolbar
                    HStack {
                        Button(action: {
                            Task {
                                await beautifyHTML(for: answer)
                            }
                        }) {
                            Label("Beautify", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            Task {
                                await validateHTML(for: answer)
                            }
                        }) {
                            Label("Validate", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))

                    // HTML editor
                    HTMLEditorView(text: Binding(
                        get: { answer.text },
                        set: { newValue in
                            answer.text = newValue
                            editorState.markDocumentEdited()
                        }
                    ))
                    .frame(maxHeight: .infinity)
                }
            } else {
                RichTextEditorView(htmlText: Binding(
                    get: { answer.text },
                    set: { newValue in
                        answer.text = newValue
                        editorState.markDocumentEdited()
                    }
                ))
                .frame(maxHeight: .infinity)
            }
        }
    }

    // MARK: - Helper Functions

    /// Handle correct answer toggle (ensure only one correct for MC/TF)
    private func handleCorrectChanged(for answer: QTIAnswer, isCorrect: Bool) {
        if isCorrect && (question.type == .multipleChoice || question.type == .trueFalse) {
            // Uncheck all other answers
            for otherAnswer in question.answers where otherAnswer.id != answer.id {
                otherAnswer.isCorrect = false
            }
        }
    }

    /// Beautify HTML for the given answer
    private func beautifyHTML(for answer: QTIAnswer) async {
        let beautifier = HTMLBeautifier()
        let beautified = await beautifier.beautify(answer.text)
        await MainActor.run {
            answer.text = beautified
            editorState.markDocumentEdited()
        }
    }

    /// Validate HTML for the given answer
    private func validateHTML(for answer: QTIAnswer) async {
        let beautifier = HTMLBeautifier()
        let result = await beautifier.validate(answer.text)

        await MainActor.run {
            if result.isValid {
                editorState.alertMessage = "✓ HTML is valid!"
            } else {
                let errors = result.errors.joined(separator: "\n")
                editorState.alertMessage = "HTML Validation Errors:\n\n\(errors)"
            }
            editorState.showAlert = true
        }
    }
}

#Preview("No Selection") {
    SingleAnswerEditorView(
        question: QTIDocument.empty().questions[0],
        selectedAnswerIDs: [],
        onCopySelected: {},
        onDuplicateSelected: {},
        onDeleteSelected: {}
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .frame(width: 400, height: 300)
}

#Preview("Single Selection") {
    let question = QTIQuestion(
        type: .multipleChoice,
        questionText: "<p>Test</p>",
        points: 1.0,
        answers: [
            QTIAnswer(text: "<p>Answer 1</p>", isCorrect: true),
            QTIAnswer(text: "<p>Answer 2</p>", isCorrect: false)
        ]
    )

    SingleAnswerEditorView(
        question: question,
        selectedAnswerIDs: [question.answers[0].id],
        onCopySelected: {},
        onDuplicateSelected: {},
        onDeleteSelected: {}
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .frame(width: 400, height: 300)
}

#Preview("Multiple Selection") {
    let question = QTIQuestion(
        type: .multipleChoice,
        questionText: "<p>Test</p>",
        points: 1.0,
        answers: [
            QTIAnswer(text: "<p>Answer 1</p>", isCorrect: true),
            QTIAnswer(text: "<p>Answer 2</p>", isCorrect: false),
            QTIAnswer(text: "<p>Answer 3</p>", isCorrect: false)
        ]
    )

    SingleAnswerEditorView(
        question: question,
        selectedAnswerIDs: Set(question.answers.map { $0.id }.prefix(3)),
        onCopySelected: {},
        onDuplicateSelected: {},
        onDeleteSelected: {}
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .frame(width: 400, height: 300)
}
