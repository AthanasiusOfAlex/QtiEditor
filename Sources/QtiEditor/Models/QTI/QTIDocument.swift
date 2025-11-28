//
//  QTIDocument.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//  Updated 2025-11-19 for DocumentGroup architecture
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
@Observable
@MainActor
final class QTIDocument: ReferenceFileDocument {
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

    // MARK: - ReferenceFileDocument Conformance

    static var readableContentTypes: [UTType] { [.imscc, .zip] }
    static var writableContentTypes: [UTType] { [.imscc, .zip] }

    typealias Snapshot = QTIDocumentSnapshot

    /// Designated initializer
    nonisolated init(
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
    nonisolated init(configuration: ReadConfiguration) throws {
        let fileWrapper = configuration.file

        let extractor = IMSCCExtractor()
        let parser = QTIParser()

        // Helper to perform parsing from a directory URL
        func parseFromDirectory(_ directoryURL: URL) throws -> QTIDocumentSnapshot {
             let assessmentURL = try extractor.locateAssessmentFile(in: directoryURL)
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

            let snapshot = try parseFromDirectory(extractedDir)

            self.id = UUID()
            self.title = snapshot.title
            self.description = snapshot.description
            self.questions = snapshot.questions
            self.metadata = snapshot.metadata
            return
        }

        // Handle Directory (unzipped)
        // If we opened a folder (unlikely for .imscc unless treated as bundle), we'd need to assume it has content.
        // For now, we only support single file (zip).

        throw QTIError.cannotExtractPackage("Unsupported file format: Directory opening not implemented")
    }

    /// Create a snapshot of the document state
    func snapshot(contentType: UTType) throws -> QTIDocumentSnapshot {
        QTIDocumentSnapshot(
            title: title,
            description: description,
            questions: questions,
            metadata: metadata
        )
    }

    /// Write the snapshot to a file wrapper
    nonisolated func fileWrapper(snapshot: QTIDocumentSnapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        // 1. Create temp directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Cleanup temp dir on exit (success or fail)
        // Note: we need to keep tempZipURL valid until FileWrapper reads it (options: .immediate reads it)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // 2. Serialize snapshot data to XML files in tempDir
        // Setup paths
        let quizID = snapshot.metadata["canvas_identifier"] ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let quizDir = tempDir.appendingPathComponent(quizID)
        try FileManager.default.createDirectory(at: quizDir, withIntermediateDirectories: true)

        // Serialize Assessment XML
        let serializer = QTISerializer()
        let assessmentURL = quizDir.appendingPathComponent("\(quizID).xml")
        try serializer.serialize(snapshot: snapshot, to: assessmentURL)

        // Manifest & Meta
        let metaURL = quizDir.appendingPathComponent("assessment_meta.xml")
        try IMSCCPackageGenerator.generateAssessmentMeta(for: snapshot, quizID: quizID, to: metaURL)

        let manifestURL = tempDir.appendingPathComponent("imsmanifest.xml")
        try IMSCCPackageGenerator.generateManifest(for: snapshot, quizID: quizID, to: manifestURL)

        // 3. Zip tempDir to temp zip file
        let tempZipURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".imscc")
        let extractor = IMSCCExtractor()
        try extractor.createPackage(from: tempDir, to: tempZipURL)

        defer { try? FileManager.default.removeItem(at: tempZipURL) }

        // 4. Create FileWrapper
        // .immediate ensures data is read into memory so we can delete the file
        let wrapper = try FileWrapper(url: tempZipURL, options: .immediate)

        return wrapper
    }
}

// MARK: - Identifiable Conformance
extension QTIDocument: Identifiable {}
