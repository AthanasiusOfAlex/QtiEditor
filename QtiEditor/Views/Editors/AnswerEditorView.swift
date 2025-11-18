//
//  AnswerEditorView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI

/// Editor view for a single answer choice
struct AnswerEditorView: View {
    @Environment(EditorState.self) private var editorState
    let answer: QTIAnswer
    let index: Int
    let onDelete: () -> Void

    var body: some View {
        @Bindable var answer = answer

        VStack(alignment: .leading, spacing: 8) {
            // Header row: Answer number, correct checkbox, delete button
            HStack {
                Text("Answer \(index + 1)")
                    .font(.headline)

                Toggle("Correct Answer", isOn: $answer.isCorrect)
                    .toggleStyle(.checkbox)

                Spacer()

                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Delete this answer")
            }

            // Answer text editor (HTML or Rich Text based on mode)
            Group {
                if editorState.editorMode == .html {
                    HTMLEditorView(text: $answer.text)
                        .frame(minHeight: 80, maxHeight: 120)
                } else {
                    RichTextEditorView(htmlText: $answer.text)
                        .frame(minHeight: 80, maxHeight: 120)
                }
            }
            .border(Color.secondary.opacity(0.3), width: 1)
            .cornerRadius(4)
        }
        .padding()
        .background(answer.isCorrect ? Color.green.opacity(0.05) : Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(answer.isCorrect ? Color.green.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    @Previewable @State var sampleAnswer = QTIAnswer(
        text: "<p>Sample answer text</p>",
        isCorrect: true
    )

    return AnswerEditorView(
        answer: sampleAnswer,
        index: 0,
        onDelete: { print("Delete tapped") }
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .padding()
    .frame(width: 600)
}
