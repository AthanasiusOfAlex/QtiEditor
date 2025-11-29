//
//  AppDelegate.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-28.
//  Disables autosave for document-based app
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Configure UserDefaults to disable autosave
        // This works in conjunction with NSAutosaveInPlace = false in Info.plist
        UserDefaults.standard.set(false, forKey: "NSAutosaveInPlace")
        UserDefaults.standard.set(false, forKey: "ApplePersistenceIgnoreState")

        // Disable automatic window restoration
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
    }

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the shared document controller to disable autosave
        // Set the delay to 0 to disable periodic autosaving
        NSDocumentController.shared.autosavingDelay = 0
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when last window closes - standard macOS behavior
        return false
    }
}


