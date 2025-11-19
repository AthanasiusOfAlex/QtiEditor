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
    let onDuplicate: () -> Void
    let onCorrectChanged: (Bool) -> Void
    @AppStorage("answerEditorHeight") private var storedAnswerHeight: Double = 50
    @State private var editorHeight: CGFloat = 50

    var body: some View {
        @Bindable var answer = answer

        answerContent
            .onAppear {
                editorHeight = CGFloat(storedAnswerHeight)
            }
            .onChange(of: editorHeight) { _, newValue in
                storedAnswerHeight = Double(newValue)
            }
    }

    private var answerContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            editorView
        }
        .padding()
        .background(answer.isCorrect ? Color.green.opacity(0.05) : Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(answer.isCorrect ? Color.green.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .contextMenu {
            Button("Copy Answer") {
                editorState.copyAnswer(answer)
            }

            Button("Duplicate Answer") {
                onDuplicate()
            }

            Divider()

            Button("Delete Answer", role: .destructive) {
                onDelete()
            }
        }
    }

    private var headerRow: some View {
        @Bindable var answer = answer

        return HStack {
            Text("Answer \(index + 1)")
                .font(.headline)

            Toggle("Correct Answer", isOn: Binding(
                get: { answer.isCorrect },
                set: { newValue in
                    answer.isCorrect = newValue
                    onCorrectChanged(newValue)
                }
            ))
            .toggleStyle(.checkbox)

            Spacer()

            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "plus.square.on.square")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .help("Duplicate this answer")

            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Delete this answer")
        }
    }

    private var editorView: some View {
        @Bindable var answer = answer

        return VStack(spacing: 0) {
            if editorState.editorMode == .html {
                HTMLEditorView(text: $answer.text)
                    .frame(height: editorHeight)
            } else {
                RichTextEditorView(htmlText: $answer.text)
                    .frame(height: editorHeight)
            }

            AnswerResizeHandle(height: $editorHeight)
        }
        .border(Color.secondary.opacity(0.3), width: 1)
        .cornerRadius(4)
    }
}

/// Resize handle for answer editors (smaller version)
struct AnswerResizeHandle: View {
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
                                height = min(max(newHeight, 50), 500)
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
    @Previewable @State var sampleAnswer = QTIAnswer(
        text: "<p>Sample answer text</p>",
        isCorrect: true
    )

    return AnswerEditorView(
        answer: sampleAnswer,
        index: 0,
        onDelete: { print("Delete tapped") },
        onDuplicate: { print("Duplicate tapped") },
        onCorrectChanged: { isCorrect in print("Correct changed to: \(isCorrect)") }
    )
    .environment(EditorState(document: QTIDocument.empty()))
    .padding()
    .frame(width: 600)
}
