//
//  DocumentRegistry.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import Foundation

/// Tracks all open documents and their display names
/// Used to generate unique "Untitled", "Untitled 2", etc. names
@MainActor
final class DocumentRegistry {
    static let shared = DocumentRegistry()

    private var displayNames: Set<String> = []

    private init() {}

    /// Registers a display name as in use
    func register(displayName: String) {
        displayNames.insert(displayName)
    }

    /// Unregisters a display name when a document closes
    func unregister(displayName: String) {
        displayNames.remove(displayName)
    }

    /// Generates the next available "Untitled" name following Apple convention
    /// Returns "Untitled", "Untitled 2", "Untitled 3", etc.
    func nextUntitledName() -> String {
        // Check if "Untitled" (without number) is available
        if !displayNames.contains("Untitled") {
            return "Untitled"
        }

        // Find the next available number
        var number = 2
        while displayNames.contains("Untitled \(number)") {
            number += 1
        }

        return "Untitled \(number)"
    }

    /// Updates a display name in the registry (when saving a document)
    func update(from oldName: String, to newName: String) {
        displayNames.remove(oldName)
        displayNames.insert(newName)
    }
}
