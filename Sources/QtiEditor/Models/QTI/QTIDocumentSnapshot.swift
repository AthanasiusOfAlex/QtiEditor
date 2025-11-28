//
//  QTIDocumentSnapshot.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import Foundation

/// A thread-safe snapshot of the QTI document state for serialization
struct QTIDocumentSnapshot: Codable, Sendable {
    let title: String
    let description: String
    let questions: [QTIQuestion]
    let metadata: [String: String]
}
