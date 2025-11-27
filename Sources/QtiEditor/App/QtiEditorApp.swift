//
//  QtiEditorApp.swift
//  QtiEditor
//
//  Created by Louis Melahn on 2025-11-16.
//

import SwiftUI
internal import UniformTypeIdentifiers

/// Manages pending file operations for new windows
@MainActor
@Observable
class PendingFileManager {
    static let shared = PendingFileManager()
    var pendingFileURL: URL?

    private init() {}

    func setPendingFile(_ url: URL) {
        pendingFileURL = url
    }

    func consumePendingFile() -> URL? {
        let url = pendingFileURL
        pendingFileURL = nil
        return url
    }
}

@main
struct QtiEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environment(PendingFileManager.shared)
        }
        .defaultSize(width: 1500, height: 950)
        .commands {
            FileCommands()
        }
    }
}

/// File menu commands for the app
struct FileCommands: Commands {
    @FocusedValue(\.editorState) private var editorState: EditorState?
    @FocusedValue(\.questionListFocused) private var questionListFocused: Bool?
    @FocusedValue(\.focusedActions) private var focusedActions: FocusedActions?
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // Pasteboard commands - native when text editors have focus,
        // custom when lists have focus
        CommandGroup(replacing: .pasteboard) {
            Button("Copy") {
                if let copy = focusedActions?.copy {
                    copy()
                } else {
                    // No focused actions - pass through to system
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Cut") {
                if let cut = focusedActions?.cut {
                    cut()
                } else {
                    // No focused actions - pass through to system
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("x", modifiers: .command)

            Button("Paste") {
                if let paste = focusedActions?.paste {
                    paste()
                } else {
                    // No focused actions - pass through to system
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("v", modifiers: .command)

            Divider()

            Button("Select All") {
                if let selectAll = focusedActions?.selectAll {
                    selectAll()
                } else {
                    // No focused actions - pass through to system
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut("a", modifiers: .command)

            Button("Delete") {
                if let delete = focusedActions?.delete {
                    delete()
                } else {
                    // No focused actions - pass through to system
                    NSApp.sendAction(#selector(NSText.delete(_:)), to: nil, from: nil)
                }
            }
            .keyboardShortcut(.delete)
        }
        CommandGroup(replacing: .newItem) {
            Button("New Quiz Window") {
                openWindow(id: "main")
            }
            .keyboardShortcut("n", modifiers: .command)

            Divider()

            Button("Open...") {
                Task { @MainActor in
                    openDocument()
                }
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                Task { @MainActor in
                    guard let editorState = editorState else { return }
                    if editorState.documentManager.fileURL != nil {
                        // Has file URL, save directly
                        await editorState.saveDocument()
                    } else {
                        // No file URL, show Save As dialog
                        saveDocumentAs()
                    }
                }
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(editorState?.document == nil)

            Button("Save As...") {
                Task { @MainActor in
                    saveDocumentAs()
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(editorState?.document == nil)
        }

        CommandGroup(replacing: .windowArrangement) {
            Button("Close Window") {
                // Close the current window
                if let window = NSApp.keyWindow {
                    window.performClose(nil)
                }
            }
            .keyboardShortcut("w", modifiers: .command)
        }

        CommandGroup(after: .newItem) {
            // Question-specific operations
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

    @MainActor
    private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .init(filenameExtension: "imscc")!,
            .init(filenameExtension: "zip")!
        ]
        panel.message = "Select a Canvas quiz export file (.imscc or .zip)"

        panel.begin { [openWindow] response in
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                // If we have an editor state, open in current window
                if let editorState = editorState {
                    await editorState.openDocument(from: url)
                } else {
                    // No window open - store URL and create window
                    PendingFileManager.shared.setPendingFile(url)
                    openWindow(id: "main")
                }
            }
        }
    }

    @MainActor
    private func saveDocumentAs() {
        guard let editorState = editorState else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "zip")!,
            .init(filenameExtension: "imscc")!
        ]
        panel.nameFieldStringValue = editorState.documentManager.displayName
        panel.message = "Export quiz as Canvas package (.zip recommended)"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            Task { @MainActor in
                await editorState.saveDocument(to: url)
            }
        }
    }
}

// MARK: - Import AppKit for file dialogs
import AppKit
