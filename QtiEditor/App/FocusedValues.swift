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

    struct QuestionListFocusedKey: FocusedValueKey {
        typealias Value = Bool
    }
}
