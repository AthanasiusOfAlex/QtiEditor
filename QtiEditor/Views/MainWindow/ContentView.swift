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
    @AppStorage("questionEditorHeight") private var storedQuestionHeight: Double = 100
    @State private var questionEditorHeight: CGFloat = 100

    var body: some View {
        @Bindable var editorState = editorState

        NavigationSplitView {
            // Sidebar - Question List
            QuestionListView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } content: {
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
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Question \(editorState.document?.questions.firstIndex(where: { $0.id == question.id }).map { $0 + 1 } ?? 0)")
                                    .font(.title)
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text(question.type.displayName)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }

                            // Question title/label
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Title / Label (optional)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                TextField("Question title or label", text: Binding(
                                    get: { question.metadata["canvas_title"] ?? "" },
                                    set: { question.metadata["canvas_title"] = $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }

                            Divider()

                            // Only show preview when there's an active search match
                            if editorState.currentSearchMatch != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Search Results Preview")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)

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
                                .padding()
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(8)

                                Divider()
                            }

                            // Editor mode toggle
                            HStack {
                                Text("Edit Question:")
                                    .font(.headline)
                                Spacer()
                                EditorModeToggle()
                            }

                            // Editor view based on mode
                            VStack(spacing: 0) {
                                if editorState.editorMode == .html {
                                    VStack(spacing: 0) {
                                        // HTML editor toolbar
                                        HStack {
                                            Button(action: {
                                                Task {
                                                    await beautifyHTML(for: question)
                                                }
                                            }) {
                                                Label("Beautify", systemImage: "wand.and.stars")
                                            }
                                            .buttonStyle(.bordered)

                                            Button(action: {
                                                Task {
                                                    await validateHTML(for: question)
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
                                            get: { question.questionText },
                                            set: { newValue in
                                                question.questionText = newValue
                                            }
                                        ))
                                    }
                                    .frame(height: questionEditorHeight)
                                    .border(Color.secondary.opacity(0.3), width: 1)
                                    .cornerRadius(4)
                                } else {
                                    RichTextEditorView(htmlText: Binding(
                                        get: { question.questionText },
                                        set: { newValue in
                                            question.questionText = newValue
                                        }
                                    ))
                                    .frame(height: questionEditorHeight)
                                    .border(Color.secondary.opacity(0.3), width: 1)
                                    .cornerRadius(4)
                                }

                                // Resize handle
                                ResizeHandle(height: $questionEditorHeight)
                            }

                            Divider()

                            // Answer editor
                            AnswerListEditorView(question: question)
                                .frame(minHeight: 300)
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else if editorState.document != nil {
                    // No question selected - show message
                    ContentUnavailableView(
                        "No Question Selected",
                        systemImage: "doc.text",
                        description: Text("Select a question from the sidebar to edit, or click \"Quiz Settings\" to configure the quiz")
                    )
                } else {
                    ContentUnavailableView(
                        "No Quiz Open",
                        systemImage: "doc.text",
                        description: Text("Open or create a quiz to begin editing")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        withAnimation {
                            editorState.isSearchVisible.toggle()
                        }
                    }) {
                        Label("Search", systemImage: editorState.isSearchVisible ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    }
                    .keyboardShortcut("f", modifiers: .command)
                    .help("Toggle search panel (Cmd+F)")
                }
            }
        } detail: {
            // Inspector panel
            QuestionInspectorView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
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
        .onAppear {
            questionEditorHeight = CGFloat(storedQuestionHeight)
        }
        .onChange(of: questionEditorHeight) { _, newValue in
            storedQuestionHeight = Double(newValue)
        }
    }

    /// Strip HTML tags for preview display
    private func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Beautify HTML for the given question
    private func beautifyHTML(for question: QTIQuestion) async {
        let beautifier = HTMLBeautifier()
        let beautified = await beautifier.beautify(question.questionText)
        await MainActor.run {
            question.questionText = beautified
        }
    }

    /// Validate HTML for the given question
    private func validateHTML(for question: QTIQuestion) async {
        let beautifier = HTMLBeautifier()
        let result = await beautifier.validate(question.questionText)

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

            HStack(spacing: 0) {
                Text(before)
                Text(matched)
                    .foregroundStyle(.orange)
                    .bold()
                    .padding(.horizontal, 2)
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(3)
                Text(after)
            }
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

            HStack(spacing: 0) {
                Text("\(index + 1). ")
                Text(before)
                Text(matched)
                    .foregroundStyle(.orange)
                    .bold()
                    .padding(.horizontal, 2)
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(3)
                Text(after)
            }
        } else {
            Text("\(index + 1). \(text)")
        }
    }
}

/// Resize handle for draggable dividers
struct ResizeHandle: View {
    @Binding var height: CGFloat
    @State private var isDragging = false
    @State private var isHovering = false

    var body: some View {
        Divider()
            .overlay(
                Rectangle()
                    .fill(isDragging ? Color.blue.opacity(0.3) : (isHovering ? Color.gray.opacity(0.2) : Color.clear))
                    .frame(height: 20)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isHovering = hovering
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let newHeight = height + value.translation.height
                                height = min(max(newHeight, 100), 800)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                    .cursor(.resizeUpDown)
            )
    }
}

#Preview {
    ContentView()
        .environment(EditorState(document: QTIDocument.empty()))
}
