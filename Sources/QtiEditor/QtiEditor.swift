import SwiftUI

@main
struct QtiEditor: App {
    var body: some Scene {
        DocumentGroup(newDocument: QTIDocument()) { file in
            ContentView(document: file.$document)
        }
        .defaultSize(width: 1500, height: 950)
    }
}
