//
//  ContentView.swift
//  QtiEditor
//
//  Created by Louis Melahn on 2025-11-16.
//

import SwiftUI

/// Main window container for the QTI Editor
/// Provides the three-pane layout: Question List (sidebar), Editor (main), Inspector (trailing)
struct ContentView: View {
    @Environment(EditorState.self) private var editorState

    var body: some View {
        @Bindable var editorState = editorState

        NavigationSplitView {
            // Sidebar - Question List
            QuestionListView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            // Main editor area
            VStack(spacing: 0) {
                // Search panel (collapsible)
                if editorState.isSearchVisible {
                    SearchReplaceView()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Divider()

                // Question editor
                if let question = editorState.selectedQuestion {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Question \(editorState.document?.questions.firstIndex(where: { $0.id == question.id }).map { $0 + 1 } ?? 0)")
                            .font(.title)

                        Text(question.type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        // Question text preview (stripped HTML with search highlighting)
                        VStack(alignment: .leading, spacing: 8) {
                            highlightedQuestionText(question: question, match: editorState.currentSearchMatch)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)

                            // Show answers with highlighting if matched
                            if editorState.currentSearchMatch?.field == .answerText {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Answers:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    ForEach(Array(question.answers.enumerated()), id: \.element.id) { index, answer in
                                        highlightedAnswerText(
                                            answer: answer,
                                            index: index,
                                            match: editorState.currentSearchMatch
                                        )
                                        .font(.caption)
                                        .padding(4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.secondary.opacity(0.05))
                                        .cornerRadius(4)
                                    }
                                }
                            }
                        }

                        Text("Answers: \(question.answers.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // TODO: Add HTMLEditorView / RichTextEditorView
                        Text("Editor view will go here")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    ContentUnavailableView(
                        "No Question Selected",
                        systemImage: "doc.text",
                        description: Text("Select a question from the sidebar to begin editing")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        withAnimation {
                            editorState.isSearchVisible.toggle()
                        }
                    }) {
                        Label("Search", systemImage: editorState.isSearchVisible ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    }
                    .keyboardShortcut("f", modifiers: .command)
                }
                ToolbarItem {
                    Button(action: {
                        editorState.addQuestion()
                    }) {
                        Label("Add Question", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle(editorState.document?.title ?? "QTI Quiz Editor")
        .overlay {
            if editorState.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .foregroundStyle(.white)
                    }
                    .padding(32)
                    .background(Color.secondary.opacity(0.8))
                    .cornerRadius(12)
                }
            }
        }
        .alert("Error", isPresented: $editorState.showAlert) {
            Button("OK") {
                editorState.showAlert = false
            }
        } message: {
            if let message = editorState.alertMessage {
                Text(message)
            }
        }
    }

    /// Strip HTML tags for preview display
    private func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Create highlighted text for question with search matches
    @ViewBuilder
    private func highlightedQuestionText(question: QTIQuestion, match: SearchMatch?) -> some View {
        let text = stripHTML(question.questionText)

        if let match = match,
           match.questionID == question.id,
           match.field == .questionText,
           let range = text.range(of: match.matchedText, options: [.caseInsensitive]) {

            let before = text[..<range.lowerBound]
            let matched = text[range]
            let after = text[range.upperBound...]

            (Text(before) +
             Text(matched).foregroundStyle(.orange).bold().background(Color.orange.opacity(0.3)) +
             Text(after))
        } else {
            Text(text)
        }
    }

    /// Create highlighted text for answer with search matches
    @ViewBuilder
    private func highlightedAnswerText(answer: QTIAnswer, index: Int, match: SearchMatch?) -> some View {
        let text = stripHTML(answer.text)

        if let match = match,
           match.answerID == answer.id,
           let range = text.range(of: match.matchedText, options: [.caseInsensitive]) {

            let before = text[..<range.lowerBound]
            let matched = text[range]
            let after = text[range.upperBound...]

            (Text("\(index + 1). ") +
             Text(before) +
             Text(matched).foregroundStyle(.orange).bold().background(Color.orange.opacity(0.3)) +
             Text(after))
        } else {
            Text("\(index + 1). \(text)")
        }
    }
}

#Preview {
    ContentView()
        .environment(EditorState(document: QTIDocument.empty()))
}
