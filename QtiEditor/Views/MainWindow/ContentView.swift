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
    @AppStorage("questionEditorHeight") private var storedQuestionEditorHeight: Double = 300
    @State private var questionEditorHeight: CGFloat = 300

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
                    VStack(spacing: 0) {
                        // Fixed metadata section
                        QuestionMetadataView(
                            question: question,
                            questionNumber: editorState.document?.questions.firstIndex(where: { $0.id == question.id }).map { $0 + 1 } ?? 0
                        )
                        .padding()

                        // Resizable question editor box
                        QuestionEditorView(question: question, height: questionEditorHeight)
                            .padding(.horizontal)

                        // Resize handle between editor and answer list
                        QuestionEditorResizeHandle(height: $questionEditorHeight)

                        // Answer list - fills remaining space
                        AnswerListEditorView(question: question)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            questionEditorHeight = CGFloat(storedQuestionEditorHeight)
        }
        .onChange(of: questionEditorHeight) { _, newValue in
            storedQuestionEditorHeight = Double(newValue)
        }
    }
}

/// Resize handle for draggable dividers (question editor)
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

/// Resize handle for question editor divider
/// Drag down = grow question editor, drag up = shrink question editor
/// Answer list automatically fills remaining space
struct QuestionEditorResizeHandle: View {
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
                                let newHeight = height + value.translation.height  // Drag down = grow question editor
                                height = min(max(newHeight, 150), 1000)
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
