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
        .commands {
            FileCommands()
        }
    }
}

/// File menu commands for the app
struct FileCommands: Commands {
    @FocusedValue(\.editorState) private var editorState: EditorState?
    @FocusedValue(\.questionListFocused) private var questionListFocused: Bool?
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
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
            // Question operations
            if let editorState = editorState {
                let selectionCount = editorState.selectedQuestionIDs.isEmpty
                    ? (editorState.selectedQuestion != nil ? 1 : 0)
                    : editorState.selectedQuestionIDs.count

                Button(selectionCount > 1 ? "Copy \(selectionCount) Questions" : "Copy Question") {
                    Task { @MainActor in
                        editorState.copySelectedQuestion()
                    }
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(selectionCount == 0)

                Button("Paste Question") {
                    Task { @MainActor in
                        editorState.pasteQuestion()
                    }
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
                .disabled(editorState.document == nil)

                Button(selectionCount > 1 ? "Duplicate \(selectionCount) Questions" : "Duplicate Question") {
                    Task { @MainActor in
                        editorState.duplicateSelectedQuestions()
                    }
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(selectionCount == 0)

                Divider()

                if questionListFocused == true {
                    Button("Select All Questions") {
                        Task { @MainActor in
                            if let document = editorState.document {
                                editorState.selectedQuestionIDs = Set(document.questions.map { $0.id })
                            }
                        }
                    }
                    .keyboardShortcut("a", modifiers: .command)
                    .disabled(editorState.document?.questions.isEmpty == true)
                }

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
        panel.nameFieldStringValue = editorState.document?.title ?? "quiz"
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
