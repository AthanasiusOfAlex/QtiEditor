//
//  QuestionMetadataView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI

/// Fixed metadata section for question editing
/// Displays question header, title field, search preview, and editor mode toggle
struct QuestionMetadataView: View {
    @Environment(EditorState.self) private var editorState
    let question: QTIQuestion
    let questionNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Question \(questionNumber)")
                    .font(.title)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(question.type.displayName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Question title/label
            VStack(alignment: .leading, spacing: 4) {
                Text("Title / Label (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Question title or label", text: Binding(
                    get: { question.metadata["canvas_title"] ?? "" },
                    set: { question.metadata["canvas_title"] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
            }

            Divider()

            // Only show preview when there's an active search match
            if editorState.currentSearchMatch != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Results Preview")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    highlightedQuestionText(question: question, match: editorState.currentSearchMatch)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)

                    // Show answers with highlighting if matched
                    if editorState.currentSearchMatch?.field == .answerText {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Answers:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(Array(question.answers.enumerated()), id: \.element.id) { index, answer in
                                highlightedAnswerText(
                                    answer: answer,
                                    index: index,
                                    match: editorState.currentSearchMatch
                                )
                                .font(.caption)
                                .padding(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.05))
                                .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)

                Divider()
            }

            // Editor mode toggle
            HStack {
                Text("Edit Question:")
                    .font(.headline)
                Spacer()
                EditorModeToggle()
            }
        }
    }

    // MARK: - Helper Functions

    /// Strip HTML tags for preview display
    private func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Create highlighted text for question with search matches
    @ViewBuilder
    private func highlightedQuestionText(question: QTIQuestion, match: SearchMatch?) -> some View {
        let text = stripHTML(question.questionText)

        if let match = match,
           match.questionID == question.id,
           match.field == .questionText,
           let range = text.range(of: match.matchedText, options: [.caseInsensitive]) {

            let before = text[..<range.lowerBound]
            let matched = text[range]
            let after = text[range.upperBound...]

            HStack(spacing: 0) {
                Text(before)
                Text(matched)
                    .foregroundStyle(.orange)
                    .bold()
                    .padding(.horizontal, 2)
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(3)
                Text(after)
            }
        } else {
            Text(text)
        }
    }

    /// Create highlighted text for answer with search matches
    @ViewBuilder
    private func highlightedAnswerText(answer: QTIAnswer, index: Int, match: SearchMatch?) -> some View {
        let text = stripHTML(answer.text)

        if let match = match,
           match.answerID == answer.id,
           let range = text.range(of: match.matchedText, options: [.caseInsensitive]) {

            let before = text[..<range.lowerBound]
            let matched = text[range]
            let after = text[range.upperBound...]

            HStack(spacing: 0) {
                Text("\(index + 1). ")
                Text(before)
                Text(matched)
                    .foregroundStyle(.orange)
                    .bold()
                    .padding(.horizontal, 2)
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(3)
                Text(after)
            }
        } else {
            Text("\(index + 1). \(text)")
        }
    }
}

#Preview {
    QuestionMetadataView(
        question: QTIDocument.empty().questions[0],
        questionNumber: 1
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .padding()
}
