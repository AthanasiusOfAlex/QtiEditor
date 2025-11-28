//
//  SearchReplaceView.swift
//  QtiEditor
//
//  Created by Claude on 2025-11-16.
//

import SwiftUI
import AppKit

/// VSCode-style search and replace panel
struct SearchReplaceView: View {
    @Environment(EditorState.self) private var editorState
    @State private var searchResults: [SearchMatch] = []
    @State private var currentMatchIndex: Int = 0
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var resultsHeight: CGFloat = 200
    @FocusState private var isSearchFieldFocused: Bool

    private let searchEngine = SearchEngine()

    var body: some View {
        @Bindable var editorState = editorState

        VStack(spacing: 12) {
            // Search input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search", text: $editorState.searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        performSearch()
                    }

                if !editorState.searchText.isEmpty {
                    Button(action: {
                        editorState.searchText = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)

            // Replace input
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.secondary)

                TextField("Replace", text: $editorState.replacementText)
                    .textFieldStyle(.plain)

                if !editorState.replacementText.isEmpty {
                    Button(action: {
                        editorState.replacementText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(6)

            // Options row
            HStack(spacing: 12) {
                // Regex toggle
                Toggle(isOn: $editorState.isRegexEnabled) {
                    HStack(spacing: 4) {
                        Image(systemName: "textformat.abc")
                        Text("Regex")
                    }
                    .font(.caption)
                }
                .toggleStyle(.button)
                .controlSize(.small)

                // Case sensitive toggle
                Toggle(isOn: $editorState.isCaseSensitive) {
                    HStack(spacing: 4) {
                        Image(systemName: "textformat")
                        Text("Aa")
                    }
                    .font(.caption)
                }
                .toggleStyle(.button)
                .controlSize(.small)

                Spacer()

                // Match count
                if !searchResults.isEmpty {
                    Text("\(searchResults.count) matches")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Scope and field selectors
            HStack(spacing: 12) {
                Picker("Scope", selection: $editorState.searchScope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.displayName).tag(scope)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)

                Picker("Field", selection: $editorState.searchField) {
                    ForEach(SearchField.allCases, id: \.self) { field in
                        Text(field.displayName).tag(field)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)

                Spacer()
            }

            // Action buttons
            HStack(spacing: 8) {
                Button("Find All") {
                    performSearch()
                }
                .controlSize(.small)
                .disabled(editorState.searchText.isEmpty || isSearching)

                if !searchResults.isEmpty {
                    Button("Replace") {
                        replaceCurrentMatch()
                    }
                    .controlSize(.small)
                    .disabled(currentMatchIndex >= searchResults.count)

                    Button("Replace All") {
                        performReplaceAll()
                    }
                    .controlSize(.small)
                }

                Spacer()

                // Navigation buttons for results
                if !searchResults.isEmpty {
                    HStack(spacing: 4) {
                        Button(action: previousMatch) {
                            Image(systemName: "chevron.up")
                        }
                        .disabled(searchResults.isEmpty || currentMatchIndex <= 0)
                        .buttonStyle(.borderless)
                        .controlSize(.small)

                        Text("\(currentMatchIndex + 1)/\(searchResults.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 50)

                        Button(action: nextMatch) {
                            Image(systemName: "chevron.down")
                        }
                        .disabled(searchResults.isEmpty || currentMatchIndex >= searchResults.count - 1)
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                }

                Button(action: {
                    editorState.isSearchVisible = false
                    searchResults = []
                    editorState.currentSearchMatch = nil
                }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }

            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }

            // Search results
            if !searchResults.isEmpty {
                Divider()

                VStack(spacing: 0) {
                    // Results header with drag handle
                    HStack {
                        Text("Results:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)

                    // Resizable results list
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, match in
                                SearchResultRow(
                                    match: match,
                                    isSelected: index == currentMatchIndex,
                                    searchPattern: editorState.searchText,
                                    onSelect: {
                                        currentMatchIndex = index
                                        selectMatch(match)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(height: resultsHeight)

                    // Resize handle
                    Divider()
                        .overlay(
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 8)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let newHeight = resultsHeight + value.translation.height
                                            resultsHeight = min(max(newHeight, 100), 500)
                                        }
                                )
                                .cursor(.resizeUpDown)
                        )
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .onAppear {
            // Auto-focus the search field when the panel appears
            isSearchFieldFocused = true
        }
    }

    private func performSearch() {
        let document = editorState.document

        isSearching = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let results = try searchEngine.search(
                    pattern: editorState.searchText,
                    isRegex: editorState.isRegexEnabled,
                    isCaseSensitive: editorState.isCaseSensitive,
                    scope: editorState.searchScope,
                    field: editorState.searchField,
                    in: document,
                    currentQuestionID: editorState.selectedQuestionID
                )

                searchResults = results
                currentMatchIndex = 0

                if results.isEmpty {
                    errorMessage = "No matches found"
                } else {
                    // Navigate to first match
                    selectMatch(results[0])
                }
            } catch let error as SearchError {
                errorMessage = error.localizedDescription
                searchResults = []
            } catch {
                errorMessage = "Search failed: \(error.localizedDescription)"
                searchResults = []
            }

            isSearching = false
        }
    }

    private func performReplaceAll() {
        let document = editorState.document

        isSearching = true
        errorMessage = nil

        Task { @MainActor in
            do {
                try searchEngine.replaceAll(
                    matches: searchResults,
                    with: editorState.replacementText,
                    pattern: editorState.searchText,
                    isRegex: editorState.isRegexEnabled,
                    in: document
                )

                // Mark document as edited
                editorState.markDocumentEdited()

                // Clear results after replacement
                searchResults = []
                errorMessage = nil
            } catch {
                errorMessage = "Replace failed: \(error.localizedDescription)"
            }

            isSearching = false
        }
    }

    private func replaceCurrentMatch() {
        let document = editorState.document
        guard currentMatchIndex < searchResults.count else {
            return
        }

        let match = searchResults[currentMatchIndex]

        Task { @MainActor in
            do {
                // Replace just this one match
                try searchEngine.replaceAll(
                    matches: [match],
                    with: editorState.replacementText,
                    pattern: editorState.searchText,
                    isRegex: editorState.isRegexEnabled,
                    in: document
                )

                // Mark document as edited
                editorState.markDocumentEdited()

                // Remove this match from results
                searchResults.remove(at: currentMatchIndex)

                // Adjust current index if needed
                if currentMatchIndex >= searchResults.count && currentMatchIndex > 0 {
                    currentMatchIndex = searchResults.count - 1
                }

                // If no more matches, clear results
                if searchResults.isEmpty {
                    errorMessage = "No more matches"
                }
            } catch {
                errorMessage = "Replace failed: \(error.localizedDescription)"
            }
        }
    }

    private func previousMatch() {
        if currentMatchIndex > 0 {
            currentMatchIndex -= 1
            selectMatch(searchResults[currentMatchIndex])
        }
    }

    private func nextMatch() {
        if currentMatchIndex < searchResults.count - 1 {
            currentMatchIndex += 1
            selectMatch(searchResults[currentMatchIndex])
        }
    }

    private func selectMatch(_ match: SearchMatch) {
        // Navigate to the question containing this match
        editorState.selectedQuestionID = match.questionID
        // Store current match for highlighting in editor
        editorState.currentSearchMatch = match
    }
}

/// Individual search result row
struct SearchResultRow: View {
    let match: SearchMatch
    let isSelected: Bool
    let searchPattern: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: fieldIcon(for: match.field))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .font(.caption)

                    Text(match.field.displayName)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white : .secondary)

                    Spacer()
                }

                // Highlight matched text in context
                highlightedText(
                    context: match.context,
                    matched: match.matchedText,
                    isSelected: isSelected
                )
                .font(.system(.body, design: .monospaced))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.05))
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func highlightedText(context: String, matched: String, isSelected: Bool) -> some View {
        if let range = context.range(of: matched, options: [.caseInsensitive]) {
            let before = context[..<range.lowerBound]
            let match = context[range]
            let after = context[range.upperBound...]

            (Text(before).foregroundStyle(isSelected ? .white : .primary) +
             Text(match).foregroundStyle(isSelected ? .yellow : .orange).bold() +
             Text(after).foregroundStyle(isSelected ? .white : .primary))
        } else {
            Text(context).foregroundStyle(isSelected ? .white : .primary)
        }
    }

    private func fieldIcon(for field: SearchField) -> String {
        switch field {
        case .questionTitle:
            return "tag"
        case .questionText:
            return "questionmark.circle"
        case .answerText:
            return "checkmark.circle"
        case .feedback:
            return "bubble.left"
        case .all:
            return "doc.text"
        }
    }
}

// MARK: - View Extension for Cursor
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    SearchReplaceView()
        .environment(EditorState(document: QTIDocument.empty()))
        .frame(width: 400)
}
