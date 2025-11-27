//
//  EditorModeToggle.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI

/// Segmented control for switching between HTML and Rich Text editing modes
struct EditorModeToggle: View {
    @Environment(EditorState.self) private var editorState

    var body: some View {
        @Bindable var editorState = editorState

        Picker("", selection: $editorState.editorMode) {
            ForEach(EditorMode.allCases, id: \.self) { mode in
                Text(mode.rawValue)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
        .labelsHidden()
    }
}

#Preview {
    EditorModeToggle()
        .environment(EditorState(document: QTIDocument.empty()))
        .padding()
}
