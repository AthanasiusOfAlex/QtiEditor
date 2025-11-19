//
//  CollapsiblePanel.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Collapsible side panel (controlled by toolbar buttons)
/// Used for both left (questions) and right (utilities) panels
struct CollapsiblePanel<Content: View>: View {
    let position: PanelPosition
    let title: String
    @Binding var isVisible: Bool
    @ViewBuilder let content: () -> Content

    enum PanelPosition {
        case leading  // Left side
        case trailing // Right side
    }

    var body: some View {
        if isVisible {
            content()
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)
                .background(Color(nsColor: .controlBackgroundColor))  // Gray background like Xcode sidebars
                .transition(.move(edge: position == .leading ? .leading : .trailing))
        }
    }
}

#Preview("Leading Panel") {
    @Previewable @State var isVisible = true

    CollapsiblePanel(position: .leading, title: "Questions", isVisible: $isVisible) {
        VStack {
            Text("Question List Content")
            List(1..<10) { i in
                Text("Question \(i)")
            }
        }
        .background(Color.gray.opacity(0.1))
    }
    .frame(height: 400)
}

#Preview("Trailing Panel") {
    @Previewable @State var isVisible = true

    CollapsiblePanel(position: .trailing, title: "Utilities", isVisible: $isVisible) {
        VStack {
            Text("Utilities Content")
            List(["Search", "Settings", "Export"], id: \.self) { item in
                Text(item)
            }
        }
        .background(Color.gray.opacity(0.1))
    }
    .frame(height: 400)
}

#Preview("Both Panels") {
    @Previewable @State var leftVisible = true
    @Previewable @State var rightVisible = true

    HStack(spacing: 0) {
        CollapsiblePanel(position: .leading, title: "Questions", isVisible: $leftVisible) {
            VStack {
                Text("Left Panel")
                Spacer()
            }
            .background(Color.blue.opacity(0.1))
        }

        VStack {
            Text("Main Content Area")
                .font(.title)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))

        CollapsiblePanel(position: .trailing, title: "Utilities", isVisible: $rightVisible) {
            VStack {
                Text("Right Panel")
                Spacer()
            }
            .background(Color.green.opacity(0.1))
        }
    }
    .frame(height: 400)
}
