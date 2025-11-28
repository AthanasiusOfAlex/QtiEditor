//
//  ContentView.swift
//  QtiEditor
//
//  Created by Louis Melahn on 2025-11-16.
//  Updated 2025-11-19 for DocumentGroup architecture
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Main window container for the QTI Editor
struct ContentView: View {
    var document: QTIDocument
    @State private var editorState: EditorState
    @Environment(\.undoManager) var undoManager

    init(document: QTIDocument) {
        self.document = document
        _editorState = State(initialValue: EditorState(document: document))
    }

    var body: some View {
        @Bindable var editorState = editorState

        HSplitView {
            // LEFT PANEL: Questions list (collapsible, resizable)
            QuestionListView()
                .environment(editorState)
                .frame(
                    minWidth: editorState.isLeftPanelVisible ? 150 : 0,
                    idealWidth: editorState.isLeftPanelVisible ? editorState.leftPanelWidth : 0,
                    maxWidth: editorState.isLeftPanelVisible ? 350 : 0
                )
                .animation(nil, value: editorState.isLeftPanelVisible)  // Disable frame animation
                .background(Color(nsColor: .controlBackgroundColor))
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: LeftPanelWidthPreferenceKey.self,
                            value: geometry.size.width
                        )
                    }
                )
                .onPreferenceChange(LeftPanelWidthPreferenceKey.self) { width in
                    if editorState.isLeftPanelVisible && width > 0 {
                        editorState.leftPanelWidth = width
                    }
                }
                .opacity(editorState.isLeftPanelVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: editorState.isLeftPanelVisible)  // Animate opacity only

            // MAIN PANEL: Question + Answers
            VStack(spacing: 0) {
                // Main content area
                if editorState.selectedQuestionIDs.count > 1 {
                    // Multiple questions selected
                    multipleQuestionsSelectedView
                } else if let question = editorState.selectedQuestion,
                          let questionNumber = editorState.document.questions.firstIndex(where: { $0.id == question.id }).map({ $0 + 1 }) {
                    // Single question selected - show question + answers in VSplitView
                    VSplitView {
                        // Top: Question section
                        QuestionSectionView(
                            question: question,
                            questionNumber: questionNumber
                        )
                        .frame(minHeight: 200)

                        // Bottom: Answers master-detail
                        AnswersMasterDetailView(question: question)
                            .frame(minHeight: 150)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(question.id)  // Force view recreation when question changes
                } else {
                    // No question selected - show message
                    if editorState.document.questions.isEmpty {
                         ContentUnavailableView(
                            "Empty Quiz",
                            systemImage: "doc.text",
                            description: Text("Add a question to begin")
                        )
                    } else {
                        ContentUnavailableView(
                            "No Question Selected",
                            systemImage: "doc.text",
                            description: Text("Select a question from the sidebar to edit")
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(editorState)

            // RIGHT PANEL: Utilities (Search, Quiz Settings) - collapsible, resizable
            RightPanelView(selectedTab: Binding(
                get: { editorState.rightPanelTab },
                set: { editorState.rightPanelTab = $0 }
            ))
            .environment(editorState)
            .frame(
                minWidth: editorState.isRightPanelVisible ? 200 : 0,
                idealWidth: editorState.isRightPanelVisible ? editorState.rightPanelWidth : 0,
                maxWidth: editorState.isRightPanelVisible ? 500 : 0
            )
            .animation(nil, value: editorState.isRightPanelVisible)  // Disable frame animation
            .background(Color(nsColor: .controlBackgroundColor))
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: RightPanelWidthPreferenceKey.self,
                        value: geometry.size.width
                    )
                }
            )
            .onPreferenceChange(RightPanelWidthPreferenceKey.self) { width in
                if editorState.isRightPanelVisible && width > 0 {
                    editorState.rightPanelWidth = width
                }
            }
            .opacity(editorState.isRightPanelVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.15), value: editorState.isRightPanelVisible)  // Animate opacity only
        }
        .background(
            // Hidden button for Search shortcut (Cmd+F)
            Button("Search Shortcut") {
                editorState.isRightPanelVisible = true
                editorState.rightPanelTab = .search
            }
            .keyboardShortcut("f", modifiers: .command)
            .opacity(0)
        )
        .navigationTitle(editorState.document.title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    editorState.isLeftPanelVisible.toggle()
                }) {
                    Label("Toggle Questions", systemImage: "sidebar.left")
                }
                .help("Toggle questions panel")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    editorState.isRightPanelVisible.toggle()
                }) {
                    Label("Toggle Utilities", systemImage: "sidebar.right")
                }
                .help("Toggle utilities panel")
            }
        }
        .focusedSceneValue(\.editorState, editorState)
        .overlay {
            // Loading overlay removed as file loading is handled by system
        }
        .alert(editorState.alertTitle, isPresented: $editorState.showAlert) {
            Button("OK") {
                editorState.showAlert = false
            }
        } message: {
            if let message = editorState.alertMessage {
                Text(message)
            }
        }
        .onAppear {
            editorState.undoManager = undoManager
        }
    }

    // MARK: - Multi-Selection View
    private var multipleQuestionsSelectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("\(editorState.selectedQuestionIDs.count) Questions Selected")
                .font(.title2)
                .fontWeight(.medium)

            Text("Use the toolbar buttons to copy, duplicate, or delete multiple questions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Preference Keys
struct LeftPanelWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct RightPanelWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ContentView(document: QTIDocument.empty())
}
