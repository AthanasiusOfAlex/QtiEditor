//
//  CollapsiblePanel.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Collapsible side panel with show/hide toggle button
/// Used for both left (questions) and right (utilities) panels
struct CollapsiblePanel<Content: View>: View {
    let position: PanelPosition
    let title: String
    @Binding var isVisible: Bool
    @ViewBuilder let content: () -> Content

    enum PanelPosition {
        case leading  // Left side
        case trailing // Right side

        var toggleIcon: String {
            switch self {
            case .leading: return "sidebar.left"
            case .trailing: return "sidebar.right"
            }
        }

        var collapseIcon: String {
            switch self {
            case .leading: return "chevron.left"
            case .trailing: return "chevron.right"
            }
        }

        var expandIcon: String {
            switch self {
            case .leading: return "chevron.right"
            case .trailing: return "chevron.left"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Leading collapse button (for trailing panels)
            if position == .trailing {
                collapseButton
            }

            // Panel content (when visible)
            if isVisible {
                content()
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)
                    .transition(.move(edge: position == .leading ? .leading : .trailing))
            }

            // Trailing collapse button (for leading panels)
            if position == .leading {
                collapseButton
            }
        }
    }

    private var collapseButton: some View {
        VStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isVisible.toggle()
                }
            }) {
                Image(systemName: isVisible ? position.collapseIcon : position.expandIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isVisible ? "Hide \(title)" : "Show \(title)")

            Spacer()
        }
        .frame(width: 20)
        .background(Color.secondary.opacity(0.05))
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
            List(["Search", "Settings", "Export"]) { item in
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
