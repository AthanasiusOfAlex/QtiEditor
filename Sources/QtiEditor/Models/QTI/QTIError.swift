//
//  QTIError.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import Foundation

/// Errors that can occur during QTI operations
enum QTIError: LocalizedError {
    // File I/O Errors
    case fileNotFound(String)
    case invalidFileFormat(String)
    case cannotReadFile(String)
    case cannotWriteFile(String)

    // ZIP/IMSCC Errors
    case invalidIMSCCPackage(String)
    case cannotExtractPackage(String)
    case cannotCreatePackage(String)
    case manifestNotFound
    case assessmentNotFound

    // XML Parsing Errors
    case xmlParseError(String)
    case invalidQTIStructure(String)
    case missingRequiredElement(String)
    case unsupportedQTIVersion(String)

    // Serialization Errors
    case serializationFailed(String)

    // General Errors
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidFileFormat(let details):
            return "Invalid file format: \(details)"
        case .cannotReadFile(let path):
            return "Cannot read file: \(path)"
        case .cannotWriteFile(let path):
            return "Cannot write file: \(path)"

        case .invalidIMSCCPackage(let reason):
            return "Invalid IMSCC package: \(reason)"
        case .cannotExtractPackage(let reason):
            return "Cannot extract package: \(reason)"
        case .cannotCreatePackage(let reason):
            return "Cannot create package: \(reason)"
        case .manifestNotFound:
            return "Manifest file (imsmanifest.xml) not found in package"
        case .assessmentNotFound:
            return "Assessment file not found in package"

        case .xmlParseError(let details):
            return "XML parse error: \(details)"
        case .invalidQTIStructure(let details):
            return "Invalid QTI structure: \(details)"
        case .missingRequiredElement(let element):
            return "Missing required QTI element: \(element)"
        case .unsupportedQTIVersion(let version):
            return "Unsupported QTI version: \(version)"

        case .serializationFailed(let reason):
            return "Serialization failed: \(reason)"

        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Ensure the file exists at the specified location."
        case .invalidFileFormat:
            return "Ensure you're opening a valid Canvas .imscc quiz export file."
        case .invalidIMSCCPackage:
            return "The file may be corrupted or not a valid Canvas quiz export."
        case .manifestNotFound, .assessmentNotFound:
            return "This doesn't appear to be a valid Canvas quiz export package."
        case .xmlParseError, .invalidQTIStructure:
            return "The QTI XML may be malformed. Try exporting the quiz again from Canvas."
        case .unsupportedQTIVersion:
            return "This app currently supports QTI 1.2 format only."
        default:
            return nil
        }
    }
}
