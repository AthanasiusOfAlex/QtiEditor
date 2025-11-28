//
//  QtiEditorApp.swift
//  QtiEditor
//
//  Created by Louis Melahn on 2025-11-16.
//  Updated 2025-11-19 for DocumentGroup architecture
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

@main
struct QtiEditorApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: QTIDocument.empty()) { configuration in
            ContentView(document: configuration.$document)
        }
        .defaultSize(width: 1500, height: 950)
        .commands {
            EditorCommands()
        }
    }
}

/// Additional commands (Duplicate, etc.)
struct EditorCommands: Commands {
    @FocusedValue(\.editorState) private var editorState: EditorState?
    @FocusedValue(\.focusedActions) private var focusedActions: FocusedActions?

    var body: some Commands {
        // Pasteboard commands
        CommandGroup(replacing: .pasteboard) {
            Button("Copy") {
                if let copy = focusedActions?.copy {
                    copy()
                } else {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Cut") {
                if let cut = focusedActions?.cut {
                    cut()
                } else {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("x", modifiers: .command)

            Button("Paste") {
                if let paste = focusedActions?.paste {
                    paste()
                } else {
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("v", modifiers: .command)

            Divider()

            Button("Select All") {
                if let selectAll = focusedActions?.selectAll {
                    selectAll()
                } else {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("a", modifiers: .command)

            Button("Delete") {
                if let delete = focusedActions?.delete {
                    delete()
                } else {
                    NSApp.sendAction(#selector(NSText.delete(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut(.delete)
        }

        // Custom Question Commands
        CommandGroup(after: .newItem) {
            if let editorState = editorState {
                let selectionCount = editorState.selectedQuestionIDs.isEmpty
                    ? (editorState.selectedQuestion != nil ? 1 : 0)
                    : editorState.selectedQuestionIDs.count

                Button(selectionCount > 1 ? "Duplicate \(selectionCount) Questions" : "Duplicate Question") {
                    Task { @MainActor in
                        editorState.duplicateSelectedQuestions()
                    }
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(selectionCount == 0)

                Divider()
            }
        }
    }
}
