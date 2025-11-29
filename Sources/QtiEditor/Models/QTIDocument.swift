import SwiftUI
import UniformTypeIdentifiers

struct QTIDocument: FileDocument, Sendable, Equatable {
    var text: String
    var originalZipData: Data
    var contentPath: String

    init(text: String = "", originalZipData: Data = Data(), contentPath: String = "") {
        self.text = text
        self.originalZipData = originalZipData
        self.contentPath = contentPath
    }

    static var readableContentTypes: [UTType] { [.zip] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.originalZipData = data

        // Unzip and read
        let unzipDir = try ZipHelper.unzip(data: data)
        // Clean up temp dir after we are done
        defer { try? FileManager.default.removeItem(at: unzipDir) }

        let path = try ZipHelper.findContentPath(in: unzipDir)
        self.contentPath = path

        let fileURL = unzipDir.appendingPathComponent(path)
        self.text = try String(contentsOf: fileURL, encoding: .utf8)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Handle case where we don't have a base zip (e.g. new document)
        if originalZipData.isEmpty {
             // For now, return plain text if no template exists,
             // though this app is intended for editing existing QTI.
            let data = self.text.data(using: .utf8) ?? Data()
            return FileWrapper(regularFileWithContents: data)
        }

        let unzipDir = try ZipHelper.unzip(data: originalZipData)
        defer { try? FileManager.default.removeItem(at: unzipDir) }

        // Overwrite the content file
        let fileURL = unzipDir.appendingPathComponent(contentPath)
        try self.text.write(to: fileURL, atomically: true, encoding: .utf8)

        // Re-zip
        let newData = try ZipHelper.zip(directory: unzipDir)
        return FileWrapper(regularFileWithContents: newData)
    }
}
