//
//  FocusedValues.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-18.
//

import SwiftUI

/// Extension to define custom focused values for context-aware commands
extension FocusedValues {
    /// Tracks whether the question list has focus (for context-aware copy/paste)
    var questionListFocused: Bool? {
        get { self[QuestionListFocusedKey.self] }
        set { self[QuestionListFocusedKey.self] = newValue }
    }

    /// The current window's EditorState (for menu commands)
    var editorState: EditorState? {
        get { self[EditorStateKey.self] }
        set { self[EditorStateKey.self] = newValue }
    }

    struct QuestionListFocusedKey: FocusedValueKey {
        typealias Value = Bool
    }

    struct EditorStateKey: FocusedValueKey {
        typealias Value = EditorState
    }
}
