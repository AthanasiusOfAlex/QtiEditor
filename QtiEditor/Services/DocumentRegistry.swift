//
//  DocumentRegistry.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import Foundation

/// Tracks all open documents and their display names
/// Used to generate unique "Untitled", "Untitled 2", etc. names
actor DocumentRegistry {
    static let shared = DocumentRegistry()

    private var displayNames: Set<String> = []

    private init() {}

    /// Registers a display name as in use
    func register(displayName: String) {
        print("📝 DocumentRegistry - Registering: '\(displayName)'")
        displayNames.insert(displayName)
        print("📋 DocumentRegistry - All names: \(displayNames)")
    }

    /// Unregisters a display name when a document closes
    func unregister(displayName: String) {
        print("🗑️ DocumentRegistry - Unregistering: '\(displayName)'")
        displayNames.remove(displayName)
        print("📋 DocumentRegistry - All names: \(displayNames)")
    }

    /// Generates the next available "Untitled" name following Apple convention
    /// Returns "Untitled", "Untitled 2", "Untitled 3", etc.
    func nextUntitledName() -> String {
        print("🔍 DocumentRegistry - Current names: \(displayNames)")

        // Check if "Untitled" (without number) is available
        if !displayNames.contains("Untitled") {
            print("✅ DocumentRegistry - Returning 'Untitled'")
            return "Untitled"
        }

        // Find the next available number
        var number = 2
        while displayNames.contains("Untitled \(number)") {
            number += 1
        }

        print("✅ DocumentRegistry - Returning 'Untitled \(number)'")
        return "Untitled \(number)"
    }

    /// Updates a display name in the registry (when saving a document)
    func update(from oldName: String, to newName: String) {
        displayNames.remove(oldName)
        displayNames.insert(newName)
    }
}
