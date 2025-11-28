//
//  QTIDocument.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//  Updated 2025-11-20 for Phase 1 Refactor
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Define the UTType for IMSCC packages
extension UTType {
    static var imscc: UTType { UTType(exportedAs: "org.imsglobal.imscc", conformingTo: .zip) }
}

/// Represents a complete QTI quiz document
/// This is the root model that contains all quiz data
struct QTIDocument: FileDocument, Identifiable, Equatable, Codable, Sendable {
    /// Unique identifier for this quiz
    let id: UUID

    /// Quiz title
    var title: String

    /// Quiz description (optional)
    var description: String

    /// Collection of questions in this quiz
    var questions: [QTIQuestion]

    /// Quiz-level settings and metadata
    var metadata: [String: String]

    // MARK: - FileDocument Conformance

    static var readableContentTypes: [UTType] { [.imscc, .zip] }
    static var writableContentTypes: [UTType] { [.imscc, .zip] }

    /// Designated initializer
    init(
        id: UUID = UUID(),
        title: String = "Untitled Quiz",
        description: String = "",
        questions: [QTIQuestion] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
        self.metadata = metadata
    }

    /// Create a new empty quiz
    static func empty() -> QTIDocument {
        QTIDocument()
    }

    /// Initialize from a file
    init(configuration: ReadConfiguration) throws {
        let fileWrapper = configuration.file

        let extractor = IMSCCExtractor()
        let parser = QTIParser()

        // Helper to perform parsing from a directory URL
        func parseFromDirectory(_ directoryURL: URL) throws -> QTIDocument {
             let assessmentURL = try extractor.locateAssessmentFile(in: directoryURL)
             // Parser will be updated to return QTIDocument
             return try parser.parse(fileURL: assessmentURL)
        }

        // Handle Zip File (IMSCC)
        if fileWrapper.isRegularFile, let data = fileWrapper.regularFileContents {
            // Write to temp file
            let tempZipURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".imscc")
            try data.write(to: tempZipURL)

            defer { try? FileManager.default.removeItem(at: tempZipURL) }

            let extractedDir = try extractor.extract(packageURL: tempZipURL)
            defer { extractor.cleanup(extractedURL: extractedDir) }

            let document = try parseFromDirectory(extractedDir)

            self.id = UUID() // Generate new ID for session
            self.title = document.title
            self.description = document.description
            self.questions = document.questions
            self.metadata = document.metadata
            return
        }

        throw QTIError.cannotExtractPackage("Unsupported file format: Directory opening not implemented")
    }

    /// Write the document to a file wrapper
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // 1. Create temp directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Cleanup temp dir on exit (success or fail)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // 2. Serialize data to XML files in tempDir
        // Setup paths
        let quizID = metadata["canvas_identifier"] ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let quizDir = tempDir.appendingPathComponent(quizID)
        try FileManager.default.createDirectory(at: quizDir, withIntermediateDirectories: true)

        // Serialize Assessment XML
        let serializer = QTISerializer()
        let assessmentURL = quizDir.appendingPathComponent("\(quizID).xml")
        // Serializer will be updated to take QTIDocument
        try serializer.serialize(snapshot: self, to: assessmentURL)

        // Manifest & Meta
        let metaURL = quizDir.appendingPathComponent("assessment_meta.xml")
        try IMSCCPackageGenerator.generateAssessmentMeta(for: self, quizID: quizID, to: metaURL)

        let manifestURL = tempDir.appendingPathComponent("imsmanifest.xml")
        try IMSCCPackageGenerator.generateManifest(for: self, quizID: quizID, to: manifestURL)

        // 3. Zip tempDir to temp zip file
        let tempZipURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".imscc")
        let extractor = IMSCCExtractor()
        try extractor.createPackage(from: tempDir, to: tempZipURL)

        defer { try? FileManager.default.removeItem(at: tempZipURL) }

        // 4. Create FileWrapper
        let wrapper = try FileWrapper(url: tempZipURL, options: .immediate)

        return wrapper
    }
}
