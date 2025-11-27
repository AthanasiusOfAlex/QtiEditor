//
//  FocusContext.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Represents what part of the UI currently has focus
/// Used for context-aware copy/paste/cut/select-all operations
enum FocusContext: Equatable {
    case questionList
    case answerList
    case questionTextEditor
    case answerTextEditor
    case none
}

/// Actions that can be performed based on focus
struct FocusedActions {
    var copy: (() -> Void)?
    var cut: (() -> Void)?
    var paste: (() -> Void)?
    var selectAll: (() -> Void)?
    var delete: (() -> Void)?
}

// MARK: - FocusedValues Extension

struct FocusContextKey: FocusedValueKey {
    typealias Value = FocusContext
}

struct FocusedActionsKey: FocusedValueKey {
    typealias Value = FocusedActions
}

extension FocusedValues {
    var focusContext: FocusContext? {
        get { self[FocusContextKey.self] }
        set { self[FocusContextKey.self] = newValue }
    }

    var focusedActions: FocusedActions? {
        get { self[FocusedActionsKey.self] }
        set { self[FocusedActionsKey.self] = newValue }
    }
}
