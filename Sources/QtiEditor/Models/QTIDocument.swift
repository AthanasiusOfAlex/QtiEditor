import SwiftUI
import UniformTypeIdentifiers

struct QTIDocument: FileDocument, Sendable, Equatable {
    var text: String

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [.plainText] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = self.text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
