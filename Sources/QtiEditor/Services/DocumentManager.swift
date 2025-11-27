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

    /// Display name for the file (separate from quiz title)
    /// Follows Apple convention: "Untitled", "Untitled 2", etc.
    private(set) var displayName: String = "Untitled"

    /// Whether the document has unsaved changes
    var isDirty: Bool = false

    // MARK: - Lifecycle

    deinit {
        // Best-effort cleanup: unregister display name when document manager is destroyed
        // Use detached task since deinit can't be async
        let name = displayName
        Task.detached {
            await DocumentRegistry.shared.unregister(displayName: name)
        }
    }

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

        // Store original URL and extract display name
        fileURL = url
        let newName = url.deletingPathExtension().lastPathComponent
        await updateDisplayName(to: newName)
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

        // Create package structure matching Canvas format
        let quizID = document.metadata["canvas_identifier"] ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let quizDir = tempDir.appendingPathComponent(quizID)
        try FileManager.default.createDirectory(at: quizDir, withIntermediateDirectories: true)

        // Generate assessment XML with Canvas naming: {quiz-id}/{quiz-id}.xml
        let assessmentURL = quizDir.appendingPathComponent("\(quizID).xml")
        try serializer.serialize(document: document, to: assessmentURL)

        // Generate assessment_meta.xml in quiz directory
        let metaURL = quizDir.appendingPathComponent("assessment_meta.xml")
        try generateAssessmentMeta(for: document, quizID: quizID, to: metaURL)

        // Generate manifest at root
        let manifestURL = tempDir.appendingPathComponent("imsmanifest.xml")
        try generateManifest(for: document, quizID: quizID, to: manifestURL)

        // Create package as .zip (Canvas uses .zip extension, not .imscc)
        var finalURL = url
        if url.pathExtension == "imscc" {
            finalURL = url.deletingPathExtension().appendingPathExtension("zip")
        }
        try await extractor.createPackage(from: tempDir, to: finalURL)

        // Update state
        fileURL = url
        let newName = url.deletingPathExtension().lastPathComponent
        await updateDisplayName(to: newName)
        isDirty = false
    }

    // MARK: - Creating New Documents

    /// Creates a new empty QTI document
    /// - Returns: New QTIDocument
    func createNewDocument() async -> QTIDocument {
        fileURL = nil
        isDirty = false

        // Generate display name following Apple convention
        // Uses registry to find next available "Untitled" number
        let newName = await DocumentRegistry.shared.nextUntitledName()
        await setDisplayName(to: newName)

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

    // MARK: - Display Name Management

    /// Sets the display name for a new document and registers it
    private func setDisplayName(to newName: String) async {
        displayName = newName
        await DocumentRegistry.shared.register(displayName: newName)
    }

    /// Updates the display name (e.g., when saving) and updates the registry
    private func updateDisplayName(to newName: String) async {
        let oldName = displayName
        displayName = newName
        await DocumentRegistry.shared.update(from: oldName, to: newName)
    }

    // MARK: - Manifest Generation

    private func generateManifest(for document: QTIDocument, quizID: String, to url: URL) throws {
        // Generate a unique manifest ID
        let manifestID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let metaResourceID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10) // YYYY-MM-DD

        let xml = """
        <?xml version="1.0"?>
        <manifest xmlns="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1" xmlns:lom="http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource" xmlns:imsmd="http://www.imsglobal.org/xsd/imsmd_v1p2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" identifier="\(manifestID)" xsi:schemaLocation="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1 http://www.imsglobal.org/xsd/imscp_v1p1.xsd http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lomresource_v1p0.xsd http://www.imsglobal.org/xsd/imsmd_v1p2 http://www.imsglobal.org/xsd/imsmd_v1p2p2.xsd">
          <metadata>
            <schema>IMS Content</schema>
            <schemaversion>1.1.3</schemaversion>
            <imsmd:lom>
              <imsmd:general>
                <imsmd:title>
                  <imsmd:string>QTI Quiz Export for \(xmlEscape(document.title))</imsmd:string>
                </imsmd:title>
              </imsmd:general>
              <imsmd:lifeCycle>
                <imsmd:contribute>
                  <imsmd:date>
                    <imsmd:dateTime>\(today)</imsmd:dateTime>
                  </imsmd:date>
                </imsmd:contribute>
              </imsmd:lifeCycle>
              <imsmd:rights>
                <imsmd:copyrightAndOtherRestrictions>
                  <imsmd:value>yes</imsmd:value>
                </imsmd:copyrightAndOtherRestrictions>
                <imsmd:description>
                  <imsmd:string>Private (Copyrighted) - http://en.wikipedia.org/wiki/Copyright</imsmd:string>
                </imsmd:description>
              </imsmd:rights>
            </imsmd:lom>
          </metadata>
          <organizations/>
          <resources>
            <resource identifier="\(quizID)" type="imsqti_xmlv1p2">
              <file href="\(quizID)/\(quizID).xml"/>
              <dependency identifierref="\(metaResourceID)"/>
            </resource>
            <resource identifier="\(metaResourceID)" type="associatedcontent/imscc_xmlv1p1/learning-application-resource" href="\(quizID)/assessment_meta.xml">
              <file href="\(quizID)/assessment_meta.xml"/>
            </resource>
          </resources>
        </manifest>
        """

        try xml.write(to: url, atomically: true, encoding: .utf8)
    }

    private func generateAssessmentMeta(for document: QTIDocument, quizID: String, to url: URL) throws {
        let assignmentID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let assignmentGroupID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let pointsPossible = document.questions.reduce(0.0) { $0 + $1.points }

        let xml = """
        <?xml version="1.0"?>
        <quiz xmlns="http://canvas.instructure.com/xsd/cccv1p0" xmlns:xsi="http://canvas.instructure.com/xsd/cccv1p0 https://canvas.instructure.com/xsd/cccv1p0.xsd" identifier="\(quizID)">
          <title>\(xmlEscape(document.title))</title>
          <description>\(xmlEscape(document.description))</description>
          <due_at/>
          <lock_at/>
          <unlock_at/>
          <shuffle_questions>false</shuffle_questions>
          <shuffle_answers>false</shuffle_answers>
          <calculator_type>none</calculator_type>
          <scoring_policy>keep_highest</scoring_policy>
          <hide_results/>
          <quiz_type>assignment</quiz_type>
          <points_possible>\(pointsPossible)</points_possible>
          <require_lockdown_browser>false</require_lockdown_browser>
          <require_lockdown_browser_for_results>false</require_lockdown_browser_for_results>
          <require_lockdown_browser_monitor>false</require_lockdown_browser_monitor>
          <lockdown_browser_monitor_data/>
          <show_correct_answers>false</show_correct_answers>
          <anonymous_submissions>false</anonymous_submissions>
          <could_be_locked>false</could_be_locked>
          <disable_timer_autosubmission>false</disable_timer_autosubmission>
          <allowed_attempts>1</allowed_attempts>
          <build_on_last_attempt>false</build_on_last_attempt>
          <one_question_at_a_time>false</one_question_at_a_time>
          <cant_go_back>false</cant_go_back>
          <available>false</available>
          <one_time_results>false</one_time_results>
          <show_correct_answers_last_attempt>false</show_correct_answers_last_attempt>
          <only_visible_to_overrides>false</only_visible_to_overrides>
          <module_locked>false</module_locked>
          <allow_clear_mc_selection/>
          <disable_document_access>false</disable_document_access>
          <result_view_restricted>false</result_view_restricted>
          <assignment identifier="\(assignmentID)">
            <title>\(xmlEscape(document.title))</title>
            <due_at/>
            <lock_at/>
            <unlock_at/>
            <module_locked>false</module_locked>
            <workflow_state>unpublished</workflow_state>
            <assignment_overrides/>
            <assignment_overrides/>
            <quiz_identifierref>\(quizID)</quiz_identifierref>
            <allowed_extensions/>
            <has_group_category>false</has_group_category>
            <points_possible>\(pointsPossible)</points_possible>
            <grading_type>points</grading_type>
            <all_day>false</all_day>
            <submission_types>online_quiz</submission_types>
            <position>1</position>
            <turnitin_enabled>false</turnitin_enabled>
            <vericite_enabled>false</vericite_enabled>
            <peer_review_count>0</peer_review_count>
            <peer_reviews>false</peer_reviews>
            <automatic_peer_reviews>false</automatic_peer_reviews>
            <anonymous_peer_reviews>false</anonymous_peer_reviews>
            <grade_group_students_individually>false</grade_group_students_individually>
            <freeze_on_copy>false</freeze_on_copy>
            <omit_from_final_grade>false</omit_from_final_grade>
            <intra_group_peer_reviews>false</intra_group_peer_reviews>
            <only_visible_to_overrides>false</only_visible_to_overrides>
            <post_to_sis>false</post_to_sis>
            <moderated_grading>false</moderated_grading>
            <grader_count>0</grader_count>
            <grader_comments_visible_to_graders>true</grader_comments_visible_to_graders>
            <anonymous_grading>false</anonymous_grading>
            <graders_anonymous_to_graders>false</graders_anonymous_to_graders>
            <grader_names_visible_to_final_grader>true</grader_names_visible_to_final_grader>
            <anonymous_instructor_annotations>false</anonymous_instructor_annotations>
            <post_policy>
              <post_manually>false</post_manually>
            </post_policy>
            <assignment_group_identifierref>\(assignmentGroupID)</assignment_group_identifierref>
            <assignment_overrides/>
          </assignment>
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
