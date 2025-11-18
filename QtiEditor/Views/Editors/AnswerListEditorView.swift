//
//  AnswerListEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI

/// Container view for editing all answers of a question
struct AnswerListEditorView: View {
    let question: QTIQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Answers")
                    .font(.title2)
                    .bold()

                Spacer()

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
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(question.answers.enumerated()), id: \.element.id) { index, answer in
                            AnswerEditorView(
                                answer: answer,
                                index: index,
                                onDelete: {
                                    deleteAnswer(answer)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding()
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
