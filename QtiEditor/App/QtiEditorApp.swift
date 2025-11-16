//
//  QtiEditorApp.swift
//  QtiEditor
//
//  Created by Louis Melahn on 2025-11-16.
//

import SwiftUI

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
            // Add File menu commands
            CommandGroup(replacing: .newItem) {
                Button("New Quiz") {
                    editorState.document = QTIDocument.empty()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

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
