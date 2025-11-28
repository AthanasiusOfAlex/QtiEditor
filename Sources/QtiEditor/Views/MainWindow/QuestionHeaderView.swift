//
//  QuestionHeaderView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Compact header showing question metadata in a single row
/// Displays: Question #, Type, Points, Validation status
struct QuestionHeaderView: View {
    @Environment(EditorState.self) private var editorState
    @Binding var question: QTIQuestion
    let questionNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compact metadata row
            HStack(spacing: 12) {
                // Question number
                Text("Question \(questionNumber)")
                    .font(.title3)
                    .fontWeight(.semibold)

                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 4, height: 4)

                // Question type
                HStack(spacing: 4) {
                    Image(systemName: iconForQuestionType(question.type))
                        .font(.caption)
                    Text(question.type.displayName)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)

                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 4, height: 4)

                // Points (editable inline)
                HStack(spacing: 4) {
                    TextField("Points", value: Binding(
                        get: { question.points },
                        set: { newValue in
                            question.points = newValue
                            editorState.markDocumentEdited()
                        }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)

                    Text("pts")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)

                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 4, height: 4)

                // Status indicator
                HStack(spacing: 4) {
                    Image(systemName: question.hasCorrectAnswer ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(question.hasCorrectAnswer ? .green : .orange)
                    Text(question.hasCorrectAnswer ? "Valid" : "No correct answer")
                        .font(.subheadline)
                        .foregroundStyle(question.hasCorrectAnswer ? .green : .orange)
                }

                Spacer()

                // Editor mode toggle
                EditorModeToggle()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)

            // Title field
            VStack(alignment: .leading, spacing: 4) {
                Text("Title / Label (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Question title or label", text: Binding(
                    get: { question.metadata["canvas_title"] ?? "" },
                    set: { newValue in
                        question.metadata["canvas_title"] = newValue
                        editorState.markDocumentEdited()
                    }
                ))
                .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
        }
    }

    private func iconForQuestionType(_ type: QTIQuestionType) -> String {
        switch type {
        case .multipleChoice: return "circle.grid.2x2"
        case .trueFalse: return "checkmark.circle"
        case .essay: return "doc.text"
        case .fillInBlank: return "rectangle.and.pencil.and.ellipsis"
        case .matching: return "arrow.left.arrow.right"
        case .multipleAnswers: return "checklist"
        case .numerical: return "number"
        case .other: return "questionmark.circle"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        QuestionHeaderView(
            question: QTIDocument.empty().questions[0],
            questionNumber: 1
        )

        QuestionHeaderView(
            question: QTIQuestion(
                type: .essay,
                questionText: "<p>Test question</p>",
                points: 5.0,
                answers: []
            ),
            questionNumber: 2
        )
    }
    .environment(EditorState(document: QTIDocument.empty()))
    .padding()
}
