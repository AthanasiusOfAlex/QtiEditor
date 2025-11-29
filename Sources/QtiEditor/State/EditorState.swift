import Foundation
import Observation

@MainActor
@Observable
class EditorState {
    var document: QTIDocument

    init(document: QTIDocument) {
        self.document = document
    }
}
