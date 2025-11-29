import SwiftUI
import Observation

struct ContentView: View {
    @Binding var document: QTIDocument
    @State private var editorState: EditorState?

    var body: some View {
        Group {
            if let editorState {
                EditorView(state: editorState)
                    .onChange(of: editorState.document) { _, newValue in
                        document = newValue
                    }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if editorState == nil {
                editorState = EditorState(document: document)
            }
        }
        .onChange(of: document) { _, newValue in
            if let state = editorState, state.document != newValue {
                state.document = newValue
            }
        }
    }
}

private struct EditorView: View {
    @Bindable var state: EditorState

    var body: some View {
        TextEditor(text: $state.document.text)
            .font(.body.monospaced())
            .padding()
    }
}
