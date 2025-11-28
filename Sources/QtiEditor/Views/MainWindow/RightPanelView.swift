//
//  RightPanelView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-19.
//

import SwiftUI

/// Right utilities panel with tabs for Search, Quiz Settings, and future features
struct RightPanelView: View {
    @Environment(EditorState.self) private var editorState
    @Binding var selectedTab: RightPanelTab

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Utilities", selection: $selectedTab) {
                ForEach(RightPanelTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Tab content
            ScrollView {
                Group {
                    switch selectedTab {
                    case .search:
                        SearchReplaceView()
                            .padding()
                    case .quizSettings:
                        QuizSettingsView()
                            .padding()
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

/// Available tabs in the right panel
enum RightPanelTab: String, CaseIterable, Identifiable {
    case search = "search"
    case quizSettings = "quizSettings"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search: return "Search"
        case .quizSettings: return "Quiz"
        }
    }

    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .quizSettings: return "gearshape"
        }
    }
}

/// Quiz settings editor (extracted from QuestionInspectorView)
struct QuizSettingsView: View {
    @Environment(EditorState.self) private var editorState

    var body: some View {
        let document = editorState.document
        quizSettingsContent(for: document)
    }

    @ViewBuilder
    private func quizSettingsContent(for document: QTIDocument) -> some View {
        @Bindable var document = document
        @Bindable var editorState = editorState

        VStack(alignment: .leading, spacing: 16) {
            Text("Quiz Settings")
                .font(.headline)

            Divider()

            // Quiz title
            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Quiz Title", text: $document.title)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: document.title) { _, _ in
                        editorState.markDocumentEdited()
                    }
            }

            // Quiz description
            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $document.description)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .onChange(of: document.description) { _, _ in
                            editorState.markDocumentEdited()
                        }
                }
                .frame(height: 100)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }

            // Question count (read-only)
            VStack(alignment: .leading, spacing: 4) {
                Text("Questions")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(document.questions.count)")
                    .font(.body)
            }

            // Total points (read-only)
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Points")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                let totalPoints = document.questions.reduce(0) { $0 + $1.points }
                Text(String(format: "%.1f", totalPoints))
                    .font(.body)
            }

            Divider()

            // Global Points
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Global Points", isOn: $editorState.isGlobalPointsEnabled)
                    .toggleStyle(.switch)
                    .help("Set the same point value for all questions")

                if editorState.isGlobalPointsEnabled {
                    HStack {
                        Text("Points:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Value", value: $editorState.globalPointsValue, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
            }

            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var selectedTab: RightPanelTab = .quizSettings

    RightPanelView(selectedTab: $selectedTab)
        .environment(EditorState(document: QTIDocument.empty()))
        .frame(width: 300, height: 600)
}
