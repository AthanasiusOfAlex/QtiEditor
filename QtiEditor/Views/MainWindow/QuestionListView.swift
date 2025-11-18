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
    @State private var showDeleteConfirmation = false
    @State private var questionToDelete: QTIQuestion?

    var body: some View {
        @Bindable var editorState = editorState

        List(selection: $editorState.selectedQuestionID) {
            if let document = editorState.document {
                // Quiz settings button
                Section {
                    Button(action: {
                        editorState.selectedQuestionID = nil
                    }) {
                        HStack {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.blue)
                            Text("Quiz Settings")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Questions (\(document.questions.count))") {
                    ForEach(Array(document.questions.enumerated()), id: \.element.id) { index, question in
                        QuestionRowView(question: question, index: index + 1)
                            .tag(question.id)
                            .contextMenu {
                                Button(action: {
                                    editorState.duplicateQuestion(question)
                                }) {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }

                                Divider()

                                Button(action: {
                                    confirmDelete(question)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onMove { fromOffsets, toOffset in
                        document.questions.move(fromOffsets: fromOffsets, toOffset: toOffset)
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
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    editorState.addQuestion()
                }) {
                    Label("Add Question", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .help("Add a new question (Cmd+Shift+N)")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    editorState.duplicateSelectedQuestion()
                }) {
                    Label("Duplicate Question", systemImage: "plus.square.on.square")
                }
                .disabled(editorState.selectedQuestion == nil)
                .help("Duplicate selected question (Cmd+D)")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    if let selected = editorState.selectedQuestion {
                        confirmDelete(selected)
                    }
                }) {
                    Label("Delete Question", systemImage: "trash")
                }
                .disabled(editorState.selectedQuestion == nil)
                .help("Delete selected question (Delete key)")
            }
        }
        .onDeleteCommand {
            if let selected = editorState.selectedQuestion {
                confirmDelete(selected)
            }
        }
        .confirmationDialog(
            "Delete Question?",
            isPresented: $showDeleteConfirmation,
            presenting: questionToDelete
        ) { question in
            Button("Delete", role: .destructive) {
                editorState.deleteQuestion(question)
            }
            Button("Cancel", role: .cancel) {}
        } message: { question in
            Text("Are you sure you want to delete this question? This action cannot be undone.")
        }
    }

    private func confirmDelete(_ question: QTIQuestion) {
        questionToDelete = question
        showDeleteConfirmation = true
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
