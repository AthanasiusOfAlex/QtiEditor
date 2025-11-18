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
    @FocusState private var isListFocused: Bool

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
                                Button("Copy") {
                                    editorState.copyQuestion(question)
                                }

                                Button("Paste") {
                                    editorState.pasteQuestion()
                                }
                                .disabled(editorState.document == nil)

                                Divider()

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
        .focused($isListFocused)
        .focusedSceneValue(\.questionListFocused, isListFocused)
        .onAppear {
            // Give focus to the list when it appears
            isListFocused = true
        }
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
        HStack(alignment: .top, spacing: 10) {
            // Question type icon with status indicator
            Image(systemName: iconForQuestionType(question.type))
                .font(.title3)
                .foregroundStyle(question.hasCorrectAnswer ? .green : .orange)
                .help(question.hasCorrectAnswer ? "Has correct answer" : "No correct answer set")

            // Question content
            VStack(alignment: .leading, spacing: 4) {
                // Question preview text
                Text(question.previewText(maxLength: 80))
                    .font(.body)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Metadata row: type, answer count, points
                HStack(spacing: 8) {
                    // Question type
                    Text(question.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Answer count
                    if !question.answers.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 2) {
                            Image(systemName: "list.bullet")
                                .font(.caption2)
                            Text("\(question.answers.count)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    // Points
                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(formatPoints(question.points))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatPoints(_ points: Double) -> String {
        if points.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(points))pt"
        }
        return String(format: "%.1fpt", points)
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
