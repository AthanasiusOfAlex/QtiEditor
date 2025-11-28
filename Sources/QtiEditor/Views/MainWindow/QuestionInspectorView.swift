//
//  QuestionInspectorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI

/// Inspector panel showing question metadata and settings
struct QuestionInspectorView: View {
    @Environment(EditorState.self) private var editorState

    var body: some View {
        @Bindable var editorState = editorState

        VStack(alignment: .leading, spacing: 16) {
            if let selectedID = editorState.selectedQuestionID,
               let index = editorState.document.questions.firstIndex(where: { $0.id == selectedID }) {
                // Question is selected - show question inspector
                questionInspector(for: $editorState.document.questions[index])
            } else {
                // No question selected - show quiz metadata
                quizInspector(for: $editorState.document)
            }
        }
        .padding()
        .frame(minWidth: 200, idealWidth: 250)
        .background(Color(nsColor: .controlBackgroundColor))
        .navigationTitle("Inspector")
    }

    @ViewBuilder
    private func questionInspector(for question: Binding<QTIQuestion>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Question Settings")
                .font(.headline)

            Divider()

            // Question type (read-only for now)
            VStack(alignment: .leading, spacing: 4) {
                Text("Type")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(question.type.wrappedValue.displayName)
                    .font(.body)
            }

            // Points
            VStack(alignment: .leading, spacing: 4) {
                Text("Points")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Points", value: question.points, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .help("Point value for this question")
            }

            // Answer count
            VStack(alignment: .leading, spacing: 4) {
                Text("Answers")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(question.answers.count)")
                    .font(.body)
            }

            // Has correct answer indicator
            VStack(alignment: .leading, spacing: 4) {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: question.wrappedValue.hasCorrectAnswer ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(question.wrappedValue.hasCorrectAnswer ? .green : .orange)

                    Text(question.wrappedValue.hasCorrectAnswer ? "Has correct answer" : "No correct answer")
                        .font(.caption)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func quizInspector(for document: Binding<QTIDocument>) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiz Settings")
                .font(.headline)

            Divider()

            // Quiz title
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Quiz Title", text: document.title)
                    .textFieldStyle(.roundedBorder)
            }

            // Quiz description
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: document.description)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                }
                .frame(height: 100)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }

            // Question count
            VStack(alignment: .leading, spacing: 4) {
                Text("Questions")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(document.questions.count)")
                    .font(.body)
            }

            // Total points
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Points")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let totalPoints = document.wrappedValue.questions.reduce(0) { $0 + $1.points }
                Text(String(format: "%.1f", totalPoints))
                    .font(.body)
            }

            Spacer()
        }
    }
}

#Preview {
    QuestionInspectorView()
        .environment(EditorState(document: QTIDocument.empty()))
        .frame(width: 250, height: 600)
}
