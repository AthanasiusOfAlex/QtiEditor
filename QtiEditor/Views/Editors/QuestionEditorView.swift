//
//  QuestionEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI

/// Resizable question editor box with HTML and Rich Text modes
/// Contains editor toolbar and appropriate editor view based on mode
struct QuestionEditorView: View {
    @Environment(EditorState.self) private var editorState
    let question: QTIQuestion
    let height: CGFloat

    var body: some View {
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
                            editorState.markDocumentEdited()
                        }
                    ))
                }
                .border(Color.secondary.opacity(0.3), width: 1)
                .cornerRadius(4)
            } else {
                RichTextEditorView(htmlText: Binding(
                    get: { question.questionText },
                    set: { newValue in
                        question.questionText = newValue
                        editorState.markDocumentEdited()
                    }
                ))
                .border(Color.secondary.opacity(0.3), width: 1)
                .cornerRadius(4)
            }
        }
        .frame(height: height)
    }

    // MARK: - Helper Functions

    /// Beautify HTML for the given question
    private func beautifyHTML(for question: QTIQuestion) async {
        let beautifier = HTMLBeautifier()
        let beautified = await beautifier.beautify(question.questionText)
        await MainActor.run {
            question.questionText = beautified
            editorState.markDocumentEdited()
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
}

#Preview {
    QuestionEditorView(
        question: QTIDocument.empty().questions[0],
        height: 300
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .padding()
}
