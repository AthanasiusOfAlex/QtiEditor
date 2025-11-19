//
//  ContentView.swift
//  QtiEditor
//
//  Created by Louis Melahn on 2025-11-16.
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

/// Main window container for the QTI Editor
/// Provides the three-panel layout with collapsible sides:
/// Left: Questions list, Main: Question + Answers (VSplitView), Right: Utilities (Search, Quiz Settings)
struct ContentView: View {
    @State private var editorState = EditorState()
    @Environment(PendingFileManager.self) private var pendingFileManager
    @FocusedValue(\.focusedActions) private var focusedActions: FocusedActions?

    var body: some View {
        @Bindable var editorState = editorState

        HSplitView {
            // LEFT PANEL: Questions list (collapsible, resizable)
            if editorState.isLeftPanelVisible {
                QuestionListView()
                    .environment(editorState)
                    .frame(minWidth: 150, idealWidth: 200, maxWidth: 350)
                    .background(Color(nsColor: .controlBackgroundColor))
            }

            // MAIN PANEL: Question + Answers
            VStack(spacing: 0) {
                // Main content area
                if editorState.selectedQuestionIDs.count > 1 {
                    // Multiple questions selected
                    multipleQuestionsSelectedView
                } else if let question = editorState.selectedQuestion,
                          let questionNumber = editorState.document?.questions.firstIndex(where: { $0.id == question.id }).map({ $0 + 1 }) {
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
                } else if editorState.document != nil {
                    // No question selected - show message
                    ContentUnavailableView(
                        "No Question Selected",
                        systemImage: "doc.text",
                        description: Text("Select a question from the sidebar to edit")
                    )
                } else {
                    // No document open
                    ContentUnavailableView(
                        "No Quiz Open",
                        systemImage: "doc.text",
                        description: Text("Open or create a quiz to begin editing")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(editorState)

            // RIGHT PANEL: Utilities (Search, Quiz Settings) - collapsible, resizable
            if editorState.isRightPanelVisible {
                RightPanelView(selectedTab: Binding(
                    get: { editorState.rightPanelTab },
                    set: { editorState.rightPanelTab = $0 }
                ))
                .environment(editorState)
                .frame(minWidth: 200, idealWidth: 300, maxWidth: 500)
            }
        }
        .navigationTitle(editorState.documentManager.displayName)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation {
                        editorState.isLeftPanelVisible.toggle()
                    }
                }) {
                    Label("Toggle Questions", systemImage: "sidebar.left")
                }
                .help("Toggle questions panel")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation {
                        editorState.isRightPanelVisible.toggle()
                    }
                }) {
                    Label("Toggle Utilities", systemImage: "sidebar.right")
                }
                .help("Toggle utilities panel")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    withAnimation {
                        editorState.isRightPanelVisible = true
                        editorState.rightPanelTab = .search
                    }
                }) {
                    Label("Search", systemImage: editorState.rightPanelTab == .search && editorState.isRightPanelVisible ? "magnifyingglass.circle.fill" : "magnifyingglass")
                }
                .keyboardShortcut("f", modifiers: .command)
                .help("Show search panel (Cmd+F)")
            }
        }
        .commands {
            // Replace default Edit menu commands with focus-aware versions
            CommandGroup(replacing: .pasteboard) {
                Button("Copy") {
                    focusedActions?.copy?()
                }
                .keyboardShortcut("c", modifiers: .command)
                .disabled(focusedActions?.copy == nil)

                Button("Cut") {
                    focusedActions?.cut?()
                }
                .keyboardShortcut("x", modifiers: .command)
                .disabled(focusedActions?.cut == nil)

                Button("Paste") {
                    focusedActions?.paste?()
                }
                .keyboardShortcut("v", modifiers: .command)
                .disabled(focusedActions?.paste == nil)

                Divider()

                Button("Select All") {
                    focusedActions?.selectAll?()
                }
                .keyboardShortcut("a", modifiers: .command)
                .disabled(focusedActions?.selectAll == nil)

                Button("Delete") {
                    focusedActions?.delete?()
                }
                .keyboardShortcut(.delete)
                .disabled(focusedActions?.delete == nil)
            }
        }
        .focusedSceneValue(\.editorState, editorState)
        .windowDocumentEdited(editorState.isDocumentEdited, editorState: editorState)
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
            // Check for pending file to open
            if let url = pendingFileManager.consumePendingFile() {
                Task { @MainActor in
                    await editorState.openDocument(from: url)
                }
            } else if editorState.document == nil {
                // No pending file and no document - create a new one
                Task { @MainActor in
                    await editorState.createNewDocument()
                }
            }
        }
    }

    // MARK: - Multi-Selection View

    /// View shown when multiple questions are selected
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
        .environment(PendingFileManager.shared)
}

// MARK: - Window Document Edited Modifier

/// View modifier to sync document edited state with NSWindow
struct WindowDocumentEditedModifier: ViewModifier {
    let isEdited: Bool
    let editorState: EditorState

    func body(content: Content) -> some View {
        content
            .background(WindowAccessor(isDocumentEdited: isEdited, editorState: editorState))
    }
}

/// Helper view to access and modify NSWindow properties
struct WindowAccessor: NSViewRepresentable {
    let isDocumentEdited: Bool
    let editorState: EditorState

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Update the coordinator's editor state
        context.coordinator.editorState = editorState

        // Find the window and update its document edited state
        guard let window = nsView.window else { return }
        window.isDocumentEdited = isDocumentEdited

        // Always set our delegate to ensure we handle close events
        // This may override SwiftUI's delegate, but that's needed for unsaved changes warnings
        if window.delegate !== context.coordinator {
            window.delegate = context.coordinator
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(editorState: editorState)
    }

    class Coordinator: NSObject, NSWindowDelegate {
        var editorState: EditorState

        init(editorState: EditorState) {
            self.editorState = editorState
            super.init()
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            // If document is not edited, allow close
            if !sender.isDocumentEdited {
                return true
            }

            // Show save dialog
            let alert = NSAlert()
            alert.messageText = "Do you want to save the changes?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()

            switch response {
            case .alertFirstButtonReturn:  // Save
                // Trigger save operation
                Task { @MainActor [editorState = self.editorState] in
                    if editorState.documentManager.fileURL != nil {
                        // Has a file URL, save directly
                        await editorState.saveDocument()
                        // Close the window after save completes
                        sender.close()
                    } else {
                        // No file URL, show Save As dialog
                        let panel = NSSavePanel()
                        panel.allowedContentTypes = [
                            .init(filenameExtension: "zip")!,
                            .init(filenameExtension: "imscc")!
                        ]
                        panel.nameFieldStringValue = editorState.documentManager.displayName
                        panel.message = "Export quiz as Canvas package (.zip recommended)"

                        panel.begin { saveResponse in
                            guard saveResponse == .OK, let url = panel.url else { return }

                            Task { @MainActor in
                                await editorState.saveDocument(to: url)
                                // Close the window after save completes
                                sender.close()
                            }
                        }
                    }
                }
                return false  // Don't close yet, will close after save
            case .alertSecondButtonReturn:  // Don't Save
                return true
            default:  // Cancel
                return false
            }
        }
    }
}

extension View {
    /// Mark the window as having unsaved changes (shows dot in close button)
    func windowDocumentEdited(_ isEdited: Bool, editorState: EditorState) -> some View {
        modifier(WindowDocumentEditedModifier(isEdited: isEdited, editorState: editorState))
    }
}
