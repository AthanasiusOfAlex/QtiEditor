//
//  IMSCCExtractor.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation
import System

/// Service for extracting and creating Canvas IMSCC packages (.imscc ZIP files)
struct IMSCCExtractor {
    /// Extracts an IMSCC package to a temporary directory
    /// - Parameter packageURL: URL to the .imscc file
    /// - Returns: URL to the extracted directory
    /// - Throws: QTIError if extraction fails
    func extract(packageURL: URL) throws -> URL {
        guard FileManager.default.fileExists(atPath: packageURL.path) else {
            throw QTIError.fileNotFound(packageURL.path)
        }

        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        // Extract ZIP file
        do {
            try FileManager.default.unzipItem(at: packageURL, to: tempDir)
        } catch {
            // Clean up temp directory on failure
            try? FileManager.default.removeItem(at: tempDir)
            throw QTIError.cannotExtractPackage(error.localizedDescription)
        }

        return tempDir
    }

    /// Locates the assessment XML file within an extracted IMSCC package
    /// - Parameter extractedURL: URL to the extracted directory
    /// - Returns: URL to the assessment.xml file
    /// - Throws: QTIError if assessment file not found
    func locateAssessmentFile(in extractedURL: URL) throws -> URL {
        let manifestURL = extractedURL.appendingPathComponent("imsmanifest.xml")

        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw QTIError.manifestNotFound
        }

        // Parse manifest to find assessment file
        // For Canvas exports, the structure can be:
        // [quiz-id]/[quiz-id].xml (current Canvas format)
        // [quiz-id]/assessment.xml (legacy format)

        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: extractedURL,
            includingPropertiesForKeys: nil
        )

        // Look for directories containing assessment XML
        for item in contents {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }

            // Try Canvas format first: {quiz-id}/{quiz-id}.xml
            let quizID = item.lastPathComponent
            let canvasAssessmentURL = item.appendingPathComponent("\(quizID).xml")
            if fileManager.fileExists(atPath: canvasAssessmentURL.path) {
                return canvasAssessmentURL
            }

            // Fall back to legacy format: {quiz-id}/assessment.xml
            let legacyAssessmentURL = item.appendingPathComponent("assessment.xml")
            if fileManager.fileExists(atPath: legacyAssessmentURL.path) {
                return legacyAssessmentURL
            }
        }

        throw QTIError.assessmentNotFound
    }

    /// Creates an IMSCC package from a directory
    /// - Parameters:
    ///   - sourceURL: URL to the directory to package
    ///   - destinationURL: URL where the .imscc file should be created
    /// - Throws: QTIError if package creation fails
    func createPackage(from sourceURL: URL, to destinationURL: URL) throws {
        do {
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.zipItem(
                at: sourceURL,
                to: destinationURL,
                shouldKeepParent: false
            )
        } catch {
            throw QTIError.cannotCreatePackage(error.localizedDescription)
        }
    }

    /// Cleans up a temporary extraction directory
    /// - Parameter url: URL to the temporary directory
    func cleanup(extractedURL url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - FileManager ZIP Extension
// Note: This extension provides basic ZIP support using Apple's native compression
extension FileManager {
    /// Unzips a file to a destination
    /// - Note: This method is nonisolated and can be called from any actor context
    nonisolated func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
        // Use Process to call the system's unzip command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = [
            "-q", // Quiet mode
            sourceURL.path,
            "-d",
            destinationURL.path
        ]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw QTIError.cannotExtractPackage("unzip failed with status \(process.terminationStatus)")
        }
    }

    /// Zips a directory to a destination
    /// - Note: This method is nonisolated and can be called from any actor context
    nonisolated func zipItem(at sourceURL: URL, to destinationURL: URL, shouldKeepParent: Bool) throws {
        // Create zip in temp directory first to avoid permission issues
        let tempZip = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("zip")

        // Use Process to call the system's zip command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = shouldKeepParent ? sourceURL.deletingLastPathComponent() : sourceURL

        // Set TMPDIR to system temp directory to avoid permission issues
        var environment = ProcessInfo.processInfo.environment
        environment["TMPDIR"] = FileManager.default.temporaryDirectory.path
        process.environment = environment

        process.arguments = [
            "-r", // Recursive
            "-q", // Quiet mode
            tempZip.path, // Create in temp directory first
            shouldKeepParent ? sourceURL.lastPathComponent : "."
        ]

        // Capture stderr for better error messages
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            // Read error message
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"

            // Clean up temp zip if it exists
            try? FileManager.default.removeItem(at: tempZip)

            throw QTIError.cannotCreatePackage("zip failed with status \(process.terminationStatus): \(errorMessage)")
        }

        // Copy the zip file from temp to final destination
        // Use copyItem instead of moveItem to avoid sandbox permission issues
        do {
            // Remove destination if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Copy temp zip to final location (copyItem works better with sandbox)
            try FileManager.default.copyItem(at: tempZip, to: destinationURL)

            // Clean up temp zip after successful copy
            try? FileManager.default.removeItem(at: tempZip)
        } catch {
            // Clean up temp zip on failure
            try? FileManager.default.removeItem(at: tempZip)
            throw QTIError.cannotCreatePackage("Failed to copy zip file: \(error.localizedDescription)")
        }
    }
}
