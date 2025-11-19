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
/// Provides the three-pane layout: Question List (sidebar), Editor (main), Inspector (trailing)
struct ContentView: View {
    @State private var editorState = EditorState()
    @AppStorage("questionEditorHeight") private var storedQuestionEditorHeight: Double = 300
    @State private var questionEditorHeight: CGFloat = 300
    @Environment(PendingFileManager.self) private var pendingFileManager

    var body: some View {
        @Bindable var editorState = editorState

        NavigationSplitView {
            // Sidebar - Question List
            QuestionListView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
                .environment(editorState)
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
            .environment(editorState)
        } detail: {
            // Inspector panel
            QuestionInspectorView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
                .environment(editorState)
        }
        .navigationTitle(editorState.documentManager.displayName)
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
            questionEditorHeight = CGFloat(storedQuestionEditorHeight)

            print("🪟 ContentView - onAppear, document exists: \(editorState.document != nil)")

            // Check for pending file to open
            if let url = pendingFileManager.consumePendingFile() {
                print("📂 ContentView - Opening pending file: \(url)")
                Task { @MainActor in
                    await editorState.openDocument(from: url)
                }
            } else if editorState.document == nil {
                // No pending file and no document - create a new one
                print("➕ ContentView - Creating new document")
                Task { @MainActor in
                    await editorState.createNewDocument()
                }
            } else {
                print("⏭️ ContentView - Document already exists, skipping creation")
            }
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
