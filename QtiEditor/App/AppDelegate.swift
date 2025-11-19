//
//  AppDelegate.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import AppKit

/// Application delegate to handle app-level events
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Check all windows for unsaved changes
        var hasUnsavedChanges = false

        for window in sender.windows {
            if window.isDocumentEdited {
                hasUnsavedChanges = true
                break
            }
        }

        // If no unsaved changes, allow immediate termination
        if !hasUnsavedChanges {
            return .terminateNow
        }

        // Show save dialog
        let alert = NSAlert()
        alert.messageText = "Do you want to save all changes before quitting?"
        alert.informativeText = "You have unsaved changes in one or more windows. Your changes will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Review Changes...")
        alert.addButton(withTitle: "Quit Without Saving")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:  // Review Changes
            // Cancel termination - let user save manually
            return .terminateCancel
        case .alertSecondButtonReturn:  // Quit Without Saving
            return .terminateNow
        default:  // Cancel
            return .terminateCancel
        }
    }
}
