//
//  QuestionListView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import SwiftUI
import AppKit

/// Sidebar view displaying the list of questions in the current quiz
struct QuestionListView: View {
    @Environment(EditorState.self) private var editorState
    @State private var showDeleteConfirmation = false
    @FocusState private var isListFocused: Bool
    @State private var clipboardHasAnswers = false

    /// Check and update clipboard state
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general

        // ========== DEBUG START ==========
        print("🔍 [DEBUG] checkClipboard() called")
        print("🔍 [DEBUG] Available pasteboard types: \(pasteboard.types?.map { $0.rawValue } ?? [])")
        // ========== DEBUG END ==========

        clipboardHasAnswers = pasteboard.types?.contains(NSPasteboard.PasteboardType("com.qti-editor.answers-array")) ?? false

        // ========== DEBUG START ==========
        print("🔍 [DEBUG] clipboardHasAnswers set to: \(clipboardHasAnswers)")
        // ========== DEBUG END ==========
    }

    var body: some View {
        @Bindable var editorState = editorState

        return buildQuestionList(editorState: editorState)
    }

    @ViewBuilder
    private func buildQuestionList(editorState: EditorState) -> some View {
        let selectionCount = computeSelectionCount()

        List(selection: Binding(
            get: { editorState.selectedQuestionIDs },
            set: { editorState.selectedQuestionIDs = $0 }
        )) {
            buildListContent(editorState: editorState)
        }
        .navigationTitle("Questions")
        .focused($isListFocused)
        .focusedSceneValue(\.questionListFocused, isListFocused)
        .onAppear {
            isListFocused = true
            checkClipboard()
        }
        .onChange(of: isListFocused) { _, focused in
            if focused {
                checkClipboard()
            }
        }
        .onChange(of: editorState.selectedQuestionIDs) { _, newSelection in
            handleSelectionChange(newSelection: newSelection)
        }
        .toolbar {
            buildToolbarContent(selectionCount: selectionCount)
        }
        .onDeleteCommand {
            confirmDelete()
        }
        .confirmationDialog(
            deleteDialogTitle(count: selectionCount),
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                editorState.deleteSelectedQuestions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteDialogMessage(count: selectionCount))
        }
    }

    @ViewBuilder
    private func buildListContent(editorState: EditorState) -> some View {
        if let document = editorState.document {
            Section {
                Button(action: {
                    editorState.selectedQuestionID = nil
                    editorState.selectedQuestionIDs.removeAll()
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
                            // ========== DEBUG START ==========
                            let _ = print("🔍 [DEBUG] Context menu opened for question: \(question.id)")
                            let _ = print("🔍 [DEBUG] About to check clipboard before showing menu")
                            // ========== DEBUG END ==========
                            checkClipboard()
                            buildContextMenu(question: question)
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

    @ViewBuilder
    private func buildContextMenu(question: QTIQuestion) -> some View {
        // ========== DEBUG START ==========
        let _ = print("🔍 [DEBUG] buildContextMenu called")
        let _ = print("🔍 [DEBUG] clipboardHasAnswers in buildContextMenu: \(clipboardHasAnswers)")
        let _ = print("🔍 [DEBUG] Paste Answer button will be disabled: \(!clipboardHasAnswers)")
        // ========== DEBUG END ==========

        Button("Copy Question") {
            editorState.copyQuestion(question)
        }

        Button("Paste Question After") {
            editorState.pasteQuestionAfter(question)
        }
        .disabled(editorState.document == nil || !editorState.canPasteQuestion())

        Button("Paste Answer") {
            editorState.pasteAnswersIntoQuestion(question)
        }
        .disabled(!clipboardHasAnswers)

        Divider()

        Button(action: {
            editorState.duplicateQuestion(question)
        }) {
            Label("Duplicate Question", systemImage: "plus.square.on.square")
        }

        Divider()

        Button(action: {
            confirmDelete()
        }) {
            Label("Delete Question", systemImage: "trash")
        }
    }

    @ToolbarContentBuilder
    private func buildToolbarContent(selectionCount: Int) -> some ToolbarContent {
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
                editorState.duplicateSelectedQuestions()
            }) {
                Label("Duplicate Question", systemImage: "plus.square.on.square")
            }
            .disabled(editorState.selectedQuestionIDs.isEmpty && editorState.selectedQuestion == nil)
            .help(duplicateHelpText(count: selectionCount))
        }

        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                confirmDelete()
            }) {
                Label("Delete Question", systemImage: "trash")
            }
            .disabled(editorState.selectedQuestionIDs.isEmpty && editorState.selectedQuestion == nil)
            .help(deleteHelpText(count: selectionCount))
        }
    }

    private func handleSelectionChange(newSelection: Set<UUID>) {
        if newSelection.isEmpty {
            editorState.selectedQuestionID = nil
        } else if let current = editorState.selectedQuestionID, newSelection.contains(current) {
            // Keep current selection if it's still in the set
        } else {
            // Use the first selected question
            editorState.selectedQuestionID = editorState.document?.questions.first { newSelection.contains($0.id) }?.id
        }
    }

    private func confirmDelete() {
        showDeleteConfirmation = true
    }

    private func computeSelectionCount() -> Int {
        if !editorState.selectedQuestionIDs.isEmpty {
            return editorState.selectedQuestionIDs.count
        }
        return editorState.selectedQuestion != nil ? 1 : 0
    }

    private func duplicateHelpText(count: Int) -> String {
        if count > 1 {
            return "Duplicate \(count) questions (Cmd+D)"
        }
        return "Duplicate selected question (Cmd+D)"
    }

    private func deleteHelpText(count: Int) -> String {
        if count > 1 {
            return "Delete \(count) questions (Delete key)"
        }
        return "Delete selected question (Delete key)"
    }

    private func deleteDialogTitle(count: Int) -> String {
        if count > 1 {
            return "Delete \(count) Questions?"
        }
        return "Delete Question?"
    }

    private func deleteDialogMessage(count: Int) -> String {
        if count > 1 {
            return "Are you sure you want to delete \(count) questions? This action cannot be undone."
        }
        return "Are you sure you want to delete this question? This action cannot be undone."
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
