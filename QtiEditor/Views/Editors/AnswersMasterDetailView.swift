//
//  AnswersMasterDetailView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Master-detail view for editing answers
/// Left: List of answers for selection
/// Right: Editor for selected answer(s)
struct AnswersMasterDetailView: View {
    let question: QTIQuestion
    @State private var selectedAnswerIDs: Set<UUID> = []

    var body: some View {
        HSplitView {
            // Left: Answer selector list (narrow like a sidebar)
            AnswerSelectorListView(
                question: question,
                selectedAnswerIDs: $selectedAnswerIDs
            )
            .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)

            // Right: Single answer editor (takes most of the space)
            SingleAnswerEditorView(
                question: question,
                selectedAnswerIDs: selectedAnswerIDs
            )
            .frame(minWidth: 400)
        }
    }
}

#Preview {
    let question = QTIQuestion(
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

    AnswersMasterDetailView(question: question)
        .environment(EditorState(document: QTIDocument.empty()))
        .frame(width: 800, height: 400)
}
