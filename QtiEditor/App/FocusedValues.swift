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

    /// Tracks the currently focused answer list for answer operations
    var answerListActions: AnswerListActions? {
        get { self[AnswerListActionsKey.self] }
        set { self[AnswerListActionsKey.self] = newValue }
    }

    struct QuestionListFocusedKey: FocusedValueKey {
        typealias Value = Bool
    }

    struct EditorStateKey: FocusedValueKey {
        typealias Value = EditorState
    }

    struct AnswerListActionsKey: FocusedValueKey {
        typealias Value = AnswerListActions
    }
}

/// Protocol for answer list operations (used for keyboard shortcuts)
protocol AnswerListActions {
    var hasSelection: Bool { get }
    var selectionCount: Int { get }
    func copySelectedAnswers()
    func pasteAnswers()
    func cutSelectedAnswers()
    func clearSelection()
}
