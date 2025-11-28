//
//  QuestionSectionView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Top section of the main panel containing question header and editor
struct QuestionSectionView: View {
    @Environment(EditorState.self) private var editorState
    @Binding var question: QTIQuestion
    let questionNumber: Int

    var body: some View {
        return VStack(spacing: 0) {
            // Compact header with metadata
            QuestionHeaderView(question: $question, questionNumber: questionNumber)
                .padding()

            Divider()

            // Question editor (expands to fill available space in VSplitView)
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
                        HTMLEditorView(text: Binding(
                            get: { question.questionText },
                            set: { newValue in
                                question.questionText = newValue
                            }
                        ))
                        .frame(maxHeight: .infinity)
                    }
                    .border(Color.secondary.opacity(0.3), width: 1)
                    .cornerRadius(4)
                } else {
                    RichTextEditorView(htmlText: Binding(
                        get: { question.questionText },
                        set: { newValue in
                            question.questionText = newValue
                        }
                    ))
                    .frame(maxHeight: .infinity)
                    .border(Color.secondary.opacity(0.3), width: 1)
                    .cornerRadius(4)
                }
            }
            .padding()
        }
        .frame(minHeight: 200)
    }

    // MARK: - Helper Functions

    /// Beautify HTML for the given question
    private func beautifyHTML() async {
        let beautifier = HTMLBeautifier()
        let beautified = await beautifier.beautify(question.questionText)
        await MainActor.run {
            question.questionText = beautified
        }
    }

    /// Validate HTML for the given question
    private func validateHTML() async {
        let beautifier = HTMLBeautifier()
        let result = await beautifier.validate(question.questionText)

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
    @Previewable @State var question = QTIDocument.empty().questions[0]
    
    QuestionSectionView(
        question: $question,
        questionNumber: 1
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .frame(width: 800, height: 400)
}
