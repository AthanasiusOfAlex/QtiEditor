//
//  QtiEditorApp.swift
//  QtiEditor
//
//  Created by Louis Melahn on 2025-11-16.
//

import SwiftUI
internal import UniformTypeIdentifiers

@main
struct QtiEditorApp: App {
    @State private var editorState = EditorState(
        document: createSampleDocument()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(editorState)
        }
        .commands {
            FileCommands(editorState: editorState)
        }
    }
}

/// File menu commands for the app
struct FileCommands: Commands {
    let editorState: EditorState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Quiz") {
                editorState.createNewDocument()
            }
            .keyboardShortcut("n", modifiers: .command)

            Divider()

            Button("Open...") {
                openDocument()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                Task {
                    await editorState.saveDocument()
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(editorState.document == nil || editorState.documentManager.fileURL == nil)

            Button("Save As...") {
                saveDocumentAs()
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(editorState.document == nil)
        }
    }

    @MainActor
    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.init(filenameExtension: "imscc")!]
        panel.message = "Select a Canvas .imscc quiz export file"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                await editorState.openDocument(from: url)
            }
        }
    }

    @MainActor
    private func saveDocumentAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "imscc")!]
        panel.nameFieldStringValue = editorState.document?.title ?? "quiz"
        panel.message = "Export quiz as .imscc package"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                await editorState.saveDocument(to: url)
            }
        }
    }
}

// MARK: - Import AppKit for file dialogs
import AppKit

/// Creates a sample document for testing/demonstration
@MainActor
private func createSampleDocument() -> QTIDocument {
    let doc = QTIDocument(
        title: "Sample Quiz",
        description: "A sample quiz for demonstration purposes"
    )

    // Add sample questions
    let q1 = QTIQuestion(
        type: .multipleChoice,
        questionText: "<p>What is the capital of France?</p>",
        points: 1.0,
        answers: [
            QTIAnswer(text: "<p>Paris</p>", isCorrect: true),
            QTIAnswer(text: "<p>London</p>", isCorrect: false),
            QTIAnswer(text: "<p>Berlin</p>", isCorrect: false),
            QTIAnswer(text: "<p>Madrid</p>", isCorrect: false)
        ]
    )

    let q2 = QTIQuestion(
        type: .multipleChoice,
        questionText: "<p>Which programming language is this app written in?</p>",
        points: 1.0,
        answers: [
            QTIAnswer(text: "<p>Swift</p>", isCorrect: true),
            QTIAnswer(text: "<p>Python</p>", isCorrect: false),
            QTIAnswer(text: "<p>JavaScript</p>", isCorrect: false),
            QTIAnswer(text: "<p>Java</p>", isCorrect: false)
        ]
    )

    doc.questions = [q1, q2]

    return doc
}
