//
//  QuestionListView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import SwiftUI

/// Sidebar view displaying the list of questions in the current quiz
struct QuestionListView: View {
    @Environment(EditorState.self) private var editorState

    var body: some View {
        @Bindable var editorState = editorState

        List(selection: $editorState.selectedQuestionID) {
            if let document = editorState.document {
                Section("Questions (\(document.questions.count))") {
                    ForEach(Array(document.questions.enumerated()), id: \.element.id) { index, question in
                        QuestionRowView(question: question, index: index + 1)
                            .tag(question.id)
                            .contextMenu {
                                Button(action: {
                                    editorState.deleteQuestion(question)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }

                if document.questions.isEmpty {
                    ContentUnavailableView(
                        "No Questions",
                        systemImage: "questionmark.circle",
                        description: Text("Add a question to get started")
                    )
                }
            }
        }
        .navigationTitle("Questions")
        .toolbar {
            ToolbarItem {
                Button(action: {
                    editorState.addQuestion()
                }) {
                    Label("Add Question", systemImage: "plus")
                }
            }
        }
    }
}

/// Individual question row in the sidebar
struct QuestionRowView: View {
    let question: QTIQuestion
    let index: Int

    var body: some View {
        HStack {
            Image(systemName: iconForQuestionType(question.type))
                .foregroundStyle(question.hasCorrectAnswer ? .green : .orange)
            VStack(alignment: .leading) {
                Text("Question \(index)")
                    .font(.headline)
                Text(question.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(question.points))pt")
                .font(.caption)
                .foregroundStyle(.secondary)
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
    QuestionListView()
        .environment(EditorState(document: QTIDocument.empty()))
}
