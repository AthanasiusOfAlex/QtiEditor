import Foundation

enum ZipError: Error {
    case unzipFailed
    case zipFailed
    case manifestNotFound
    case resourceNotFound
    case fileAttributeMissing
}

struct ZipHelper {
    /// Unzips the provided data to a temporary directory and returns the URL of that directory.
    static func unzip(data: Data) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let zipFile = tempDir.appendingPathComponent("\(uniqueID).zip")
        let unzipDir = tempDir.appendingPathComponent(uniqueID)

        try data.write(to: zipFile)

        // Create directory
        try FileManager.default.createDirectory(at: unzipDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        // -o: overwrite existing files
        // -d: extract to directory
        process.arguments = ["-o", zipFile.path, "-d", unzipDir.path]

        // Redirect output to suppress console spam
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        // Clean up zip file
        try? FileManager.default.removeItem(at: zipFile)

        guard process.terminationStatus == 0 else {
            throw ZipError.unzipFailed
        }

        return unzipDir
    }

    /// Zips the contents of the specified directory and returns the zip data.
    static func zip(directory: URL) throws -> Data {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueID = UUID().uuidString
        let zipFile = tempDir.appendingPathComponent("\(uniqueID).zip")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.currentDirectoryURL = directory
        // -r: recursive
        // -q: quiet
        process.arguments = ["-r", "-q", zipFile.path, "."]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ZipError.zipFailed
        }

        let data = try Data(contentsOf: zipFile)

        // Cleanup
        try? FileManager.default.removeItem(at: zipFile)

        return data
    }

    /// Parses imsmanifest.xml in the given directory to find the main QTI XML file path.
    static func findContentPath(in directory: URL) throws -> String {
        let manifestURL = directory.appendingPathComponent("imsmanifest.xml")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw ZipError.manifestNotFound
        }

        let xmlString = try String(contentsOf: manifestURL, encoding: .utf8)

        // Regex to find the resource with type="imsqti_xmlv1p2"
        // We look for the resource tag block.
        // Note: Regex literals need to be careful with escaping.
        // Swift 5.7+ regex literal syntax: /.../

        let resourcePattern = /<resource[^>]*?type=["']imsqti_xmlv1p2["'][^>]*?>([\s\S]*?)<\/resource>/

        guard let match = try? resourcePattern.firstMatch(in: xmlString) else {
            throw ZipError.resourceNotFound
        }

        let resourceBody = match.1

        // Look for <file href="..."> inside the resource body
        let hrefPattern = /<file[^>]*?href=["']([^"']+)["']/

        if let fileMatch = try? hrefPattern.firstMatch(in: resourceBody) {
            return String(fileMatch.1)
        } else {
            // Fallback: Check if href is on the resource tag itself (if the regex captured it? No, capture group 1 is body)
            // If the href was on the resource tag, we need to inspect the whole match or parsing strategy.
            // But based on QTI 1.2 spec and sample, <file> child is standard.
            throw ZipError.fileAttributeMissing
        }
    }
}
