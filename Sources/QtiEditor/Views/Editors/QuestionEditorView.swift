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
    @Binding var question: QTIQuestion
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            if editorState.editorMode == .html {
                VStack(spacing: 0) {
                    // HTML editor toolbar
                    HStack {
                        Button(action: {
                            Task {
                                await beautifyHTML()
                            }
                        }) {
                            Label("Beautify", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(.bordered)
                        .disabled(true)

                        Button(action: {
                            Task {
                                await validateHTML()
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
                    HTMLEditorView(text: $question.questionText)
                }
                .border(Color.secondary.opacity(0.3), width: 1)
                .cornerRadius(4)
            } else {
                RichTextEditorView(htmlText: $question.questionText)
                .border(Color.secondary.opacity(0.3), width: 1)
                .cornerRadius(4)
            }
        }
        .frame(height: height)
    }

    // MARK: - Helper Functions

    /// Beautify HTML for the given question
    private func beautifyHTML() async {
        let text = question.questionText
        let beautifier = HTMLBeautifier()
        let beautified = await beautifier.beautify(text)
        await MainActor.run {
            question.questionText = beautified
        }
    }

    /// Validate HTML for the given question
    private func validateHTML() async {
        let text = question.questionText
        let beautifier = HTMLBeautifier()
        let result = await beautifier.validate(text)

        await MainActor.run {
            if result.isValid {
                editorState.alertTitle = "Success"
                editorState.alertMessage = "✓ HTML is valid!"
            } else {
                editorState.alertTitle = "Validation Error"
                let errors = result.errors.joined(separator: "\n")
                editorState.alertMessage = "HTML Validation Errors:\n\n\(errors)"
            }
            editorState.showAlert = true
        }
    }
}

#Preview {
    QuestionEditorView(
        question: .constant(QTIQuestion()),
        height: 300
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .padding()
}
