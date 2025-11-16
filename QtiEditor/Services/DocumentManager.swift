//
//  DocumentManager.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Coordinates file operations for QTI documents
/// Manages opening, saving, and document state
@MainActor
final class DocumentManager: @unchecked Sendable {
    private let extractor = IMSCCExtractor()
    private let parser = QTIParser()
    private let serializer = QTISerializer()

    /// Currently extracted package directory (for cleanup)
    private var extractedDirectory: URL?

    /// Original file URL (for tracking save location)
    var fileURL: URL?

    /// Whether the document has unsaved changes
    var isDirty: Bool = false

    // MARK: - Opening Documents

    /// Opens an IMSCC package and parses it into a QTIDocument
    /// - Parameter url: URL to the .imscc file
    /// - Returns: Parsed QTIDocument
    /// - Throws: QTIError if opening fails
    func openDocument(from url: URL) async throws -> QTIDocument {
        // Extract the package
        let extractedURL = try await extractor.extract(packageURL: url)
        extractedDirectory = extractedURL

        // Locate assessment file
        let assessmentURL = try await extractor.locateAssessmentFile(in: extractedURL)

        // Parse the assessment
        let document = try await parser.parse(fileURL: assessmentURL)

        // Store original URL
        fileURL = url
        isDirty = false

        return document
    }

    // MARK: - Saving Documents

    /// Saves a document to its original location
    /// - Parameter document: The document to save
    /// - Throws: QTIError if saving fails
    func saveDocument(_ document: QTIDocument) async throws {
        guard let fileURL = fileURL else {
            throw QTIError.cannotWriteFile("No file URL set")
        }

        try await saveDocument(document, to: fileURL)
    }

    /// Saves a document to a specific location
    /// - Parameters:
    ///   - document: The document to save
    ///   - url: Destination URL for the .imscc file
    /// - Throws: QTIError if saving fails
    func saveDocument(_ document: QTIDocument, to url: URL) async throws {
        // Create temporary directory for package construction
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        defer {
            // Clean up temp directory
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Create package structure
        let quizID = document.metadata["canvas_identifier"] ?? UUID().uuidString
        let quizDir = tempDir.appendingPathComponent(quizID)
        try FileManager.default.createDirectory(at: quizDir, withIntermediateDirectories: true)

        // Generate assessment XML
        let assessmentURL = quizDir.appendingPathComponent("assessment.xml")
        try serializer.serialize(document: document, to: assessmentURL)

        // Generate manifest
        let manifestURL = tempDir.appendingPathComponent("imsmanifest.xml")
        try generateManifest(for: document, quizID: quizID, to: manifestURL)

        // Generate assessment_meta.xml (optional, but Canvas expects it)
        let metaURL = tempDir.appendingPathComponent("assessment_meta.xml")
        try generateAssessmentMeta(for: document, quizID: quizID, to: metaURL)

        // Create IMSCC package (ZIP)
        try await extractor.createPackage(from: tempDir, to: url)

        // Update state
        fileURL = url
        isDirty = false
    }

    // MARK: - Creating New Documents

    /// Creates a new empty QTI document
    /// - Returns: New QTIDocument
    func createNewDocument() -> QTIDocument {
        fileURL = nil
        isDirty = false
        return QTIDocument.empty()
    }

    // MARK: - Cleanup

    /// Cleans up any temporary extracted files
    func cleanup() async {
        if let extractedDirectory = extractedDirectory {
            await extractor.cleanup(extractedURL: extractedDirectory)
            self.extractedDirectory = nil
        }
    }

    // MARK: - Manifest Generation

    private func generateManifest(for document: QTIDocument, quizID: String, to url: URL) throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <manifest identifier="manifest_\(quizID)" xmlns="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1" xmlns:lom="http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource" xmlns:lomimscc="http://ltsc.ieee.org/xsd/imsccv1p1/LOM/manifest" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1 http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imscp_v1p2_v1p0.xsd http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lomresource_v1p0.xsd http://ltsc.ieee.org/xsd/imsccv1p1/LOM/manifest http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lommanifest_v1p0.xsd">
          <metadata>
            <schema>IMS Common Cartridge</schema>
            <schemaversion>1.1.0</schemaversion>
          </metadata>
          <organizations/>
          <resources>
            <resource identifier="resource_\(quizID)" type="imsqti_xmlv1p2">
              <file href="\(quizID)/assessment.xml"/>
            </resource>
          </resources>
        </manifest>
        """

        try xml.write(to: url, atomically: true, encoding: .utf8)
    }

    private func generateAssessmentMeta(for document: QTIDocument, quizID: String, to url: URL) throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <quiz identifier="quiz_\(quizID)">
          <title>\(xmlEscape(document.title))</title>
          <description>\(xmlEscape(document.description))</description>
          <quiz_type>assignment</quiz_type>
          <points_possible>\(document.questions.reduce(0.0) { $0 + $1.points })</points_possible>
          <assignment_group_identifierref>assignment_group_1</assignment_group_identifierref>
        </quiz>
        """

        try xml.write(to: url, atomically: true, encoding: .utf8)
    }

    private func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
