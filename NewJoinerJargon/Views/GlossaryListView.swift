import SwiftUI

enum SortOption: String, CaseIterable, Identifiable {
    case alphabetical = "A → Z"
    case alphabeticalReverse = "Z → A"
    case newestFirst = "Newest first"
    case oldestFirst = "Oldest first"
    case recentlyUpdated = "Recently updated"
    case bySource = "By source"

    var id: String { rawValue }
}

struct GlossaryListView: View {
    @Environment(GlossaryStore.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(NavigationState.self) private var navigation
    @State private var searchText = ""
    @State private var selectedTerms: Set<GlossaryTerm> = []
    @State private var selectedCategories: Set<TermCategory> = []
    @State private var sortOption: SortOption = .alphabetical
    @State private var showBulkDeleteConfirmation = false
    @State private var termToDelete: GlossaryTerm?

    // Undo delete
    @State private var undoableTerms: [DeletedTermSnapshot] = []
    @State private var undoTimer: Timer?
    @State private var scrollProxy: ScrollViewProxy?

    struct DeletedTermSnapshot {
        let term: String
        let definition: String
        let context: String
        let surroundingText: String
        let sourceApp: String
        let sourceURL: String
        let category: TermCategory
        let createdAt: Date

        init(from term: GlossaryTerm) {
            self.term = term.term
            self.definition = term.definition
            self.context = term.context
            self.surroundingText = term.surroundingText
            self.sourceApp = term.sourceApp
            self.sourceURL = term.sourceURL
            self.category = term.category
            self.createdAt = term.createdAt
        }
    }

    private var allTerms: [GlossaryTerm] { store.allTerms() }

    private var filteredTerms: [GlossaryTerm] {
        var terms = searchText.isEmpty ? allTerms : store.search(searchText)
        if !selectedCategories.isEmpty {
            terms = terms.filter { selectedCategories.contains($0.category) }
        }
        return sortTerms(terms)
    }

    /// The "active" term for the detail view (first of the selection)
    private var activeTerm: GlossaryTerm? {
        guard let first = selectedTerms.first else { return nil }
        // If multiple selected, show the most recently clicked
        return first
    }

    private func sortTerms(_ terms: [GlossaryTerm]) -> [GlossaryTerm] {
        switch sortOption {
        case .alphabetical:
            return terms.sorted { $0.term < $1.term }
        case .alphabeticalReverse:
            return terms.sorted { $0.term > $1.term }
        case .newestFirst:
            return terms.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return terms.sorted { $0.createdAt < $1.createdAt }
        case .recentlyUpdated:
            return terms.sorted { $0.updatedAt > $1.updatedAt }
        case .bySource:
            return terms.sorted {
                ($0.sourceApp.isEmpty ? "zzz" : $0.sourceApp) < ($1.sourceApp.isEmpty ? "zzz" : $1.sourceApp)
            }
        }
    }

    var body: some View {
        Group {
            if !settings.hasCompletedOnboarding {
                WelcomeView()
                    .environment(store)
                    .environment(settings)
            } else if allTerms.isEmpty {
                emptyState
            } else {
                NavigationSplitView {
                    ScrollViewReader { proxy in
                    List(filteredTerms, selection: $selectedTerms) { term in
                        TermRowView(term: term, isSelected: selectedTerms.contains(term))
                            .tag(term)
                            .id(term)
                            .help(term.definition)
                            .contextMenu {
                                // If this term is part of a multi-selection, show bulk actions
                                let isMulti = selectedTerms.count > 1 && selectedTerms.contains(term)

                                if isMulti {
                                    Button(role: .destructive) {
                                        showBulkDeleteConfirmation = true
                                    } label: {
                                        Label("Delete \(selectedTerms.count) terms", systemImage: "trash")
                                    }

                                    Menu("Change category for \(selectedTerms.count) terms") {
                                        ForEach(TermCategory.allCases) { cat in
                                            Button(cat.rawValue) {
                                                for t in selectedTerms {
                                                    t.category = cat
                                                    t.updatedAt = Date()
                                                }
                                                try? store.context.save()
                                            }
                                        }
                                    }
                                } else {
                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(term.definition, forType: .string)
                                    } label: {
                                        Label("Copy definition", systemImage: "doc.on.doc")
                                    }

                                    Button {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(term.term, forType: .string)
                                    } label: {
                                        Label("Copy term", systemImage: "textformat")
                                    }

                                    if !term.sourceURL.isEmpty {
                                        Button {
                                            if let url = URL(string: term.sourceURL) {
                                                NSWorkspace.shared.open(url)
                                            }
                                        } label: {
                                            Label("Open source link", systemImage: "arrow.up.right.square")
                                        }
                                    }

                                    Divider()

                                    Menu("Change category") {
                                        ForEach(TermCategory.allCases) { cat in
                                            Button {
                                                term.category = cat
                                                term.updatedAt = Date()
                                                try? store.context.save()
                                            } label: {
                                                if term.category == cat {
                                                    Label(cat.rawValue, systemImage: "checkmark")
                                                } else {
                                                    Text(cat.rawValue)
                                                }
                                            }
                                        }
                                    }

                                    Button {
                                        relookup(term)
                                    } label: {
                                        Label("Look up again", systemImage: "arrow.clockwise")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        termToDelete = term
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                    .searchable(text: $searchText, prompt: "Search your jargon...")
                    .navigationTitle("My Glossary")
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            sortAndFilterMenu
                        }
                    }
                    .overlay {
                        if filteredTerms.isEmpty && !searchText.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else if filteredTerms.isEmpty, !selectedCategories.isEmpty {
                            ContentUnavailableView(
                                "No terms in selected categories",
                                systemImage: "tag",
                                description: Text("Try different categories or add new terms.")
                            )
                        }
                    }
                    // Bulk delete bar at bottom of sidebar
                    .safeAreaInset(edge: .bottom) {
                        if selectedTerms.count > 1 {
                            HStack {
                                Text("\(selectedTerms.count) selected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(role: .destructive) {
                                    showBulkDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.bar)
                        }
                    }
                    .onChange(of: selectedTerms) { _, newSelection in
                        if let term = newSelection.first, newSelection.count == 1 {
                            // Delay to let the list update before scrolling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(term, anchor: .center)
                                }
                            }
                        }
                    }
                    .onAppear { scrollProxy = proxy }
                    } // ScrollViewReader
                } detail: {
                    if selectedTerms.count > 1 {
                        // Multi-selection state
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("\(selectedTerms.count) terms selected")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text("Use ⌘+Click or ⇧+Click to select multiple terms")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } else if let term = activeTerm {
                        TermDetailView(term: term, onDelete: {
                            let terms = filteredTerms
                            if let idx = terms.firstIndex(of: term) {
                                if idx + 1 < terms.count {
                                    selectedTerms = [terms[idx + 1]]
                                } else if idx > 0 {
                                    selectedTerms = [terms[idx - 1]]
                                } else {
                                    selectedTerms = []
                                }
                            } else {
                                selectedTerms = []
                            }
                            deleteWithUndo(term)
                        })
                        .environment(store)
                    } else {
                        ContentUnavailableView(
                            "Select a term",
                            systemImage: "text.cursor",
                            description: Text("Choose a term from the sidebar to view its definition.")
                        )
                    }
                }
                .toolbar(removing: .sidebarToggle)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            addNewTerm()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .help("Add a new term")
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTerms)
        .onChange(of: navigation.selectedTermName) { _, termName in
            guard let termName else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if let term = store.lookup(termName) {
                    // Ensure the term's category is visible in the filter
                    if !selectedCategories.isEmpty && !selectedCategories.contains(term.category) {
                        selectedCategories.insert(term.category)
                    }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTerms = [term]
                    }
                    // Scroll after selection has settled
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        scrollProxy?.scrollTo(term, anchor: .center)
                    }
                }
                navigation.clear()
            }
        }
        .onChange(of: selectedTerms) { oldTerms, _ in
            // Clean up drafts when navigating away
            for old in oldTerms {
                if !selectedTerms.contains(old) && isDraft(old) {
                    store.delete(old)
                }
            }
        }
        .alert("Delete \(selectedTerms.count) terms?", isPresented: $showBulkDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                let termsToDelete = Array(selectedTerms)
                selectedTerms = []
                deleteWithUndo(termsToDelete)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete \(selectedTerms.count) terms from your glossary.")
        }
        .alert("Delete Term", isPresented: Binding(
            get: { termToDelete != nil },
            set: { if !$0 { termToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let term = termToDelete {
                    deleteWithUndo(term)
                    termToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { termToDelete = nil }
        } message: {
            Text("Are you sure you want to delete \"\(termToDelete?.term ?? "")\"?")
        }
        // Undo delete toast — bottom right
        .overlay(alignment: .bottomTrailing) {
            if !undoableTerms.isEmpty {
                HStack(spacing: 10) {
                    Text(undoableTerms.count == 1
                         ? "Deleted \"\(undoableTerms[0].term)\""
                         : "\(undoableTerms.count) terms deleted")
                        .font(.caption)
                    Button("Undo") {
                        undoDelete()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                .padding(16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func isDraft(_ term: GlossaryTerm) -> Bool {
        term.term == "new term"
    }

    private func deleteWithUndo(_ term: GlossaryTerm) {
        deleteWithUndo([term])
    }

    private func deleteWithUndo(_ terms: [GlossaryTerm]) {
        let snapshots = terms.map { DeletedTermSnapshot(from: $0) }
        for term in terms {
            selectedTerms.remove(term)
            store.delete(term)
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            undoableTerms = snapshots
        }

        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation { undoableTerms = [] }
            }
        }
    }

    private func undoDelete() {
        guard !undoableTerms.isEmpty else { return }
        for snapshot in undoableTerms {
            let restored = GlossaryTerm(
                term: snapshot.term,
                definition: snapshot.definition,
                context: snapshot.context,
                surroundingText: snapshot.surroundingText,
                sourceApp: snapshot.sourceApp,
                sourceURL: snapshot.sourceURL,
                category: snapshot.category
            )
            store.context.insert(restored)
        }
        try? store.context.save()

        withAnimation {
            undoableTerms = []
        }
        undoTimer?.invalidate()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Your glossary is empty")
                .font(.title2.bold())
            Text("Select a word in any app and press **⌃⌥J** to start building your personal jargon dictionary.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Divider()
                .frame(width: 200)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 12) {
                Label("Highlight a word anywhere", systemImage: "text.cursor")
                Label("Press ⌃⌥J to capture it", systemImage: "keyboard")
                Label("Add a definition & category", systemImage: "tag")
                Label("Build your knowledge base", systemImage: "book.closed.fill")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sortAndFilterMenu: some View {
        Menu {
            Section("Sort by") {
                ForEach(SortOption.allCases) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sortOption = option
                        }
                    } label: {
                        if sortOption == option {
                            Label(option.rawValue, systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            }

            Divider()

            Section("Filter by category") {
                Button {
                    selectedCategories.removeAll()
                } label: {
                    if selectedCategories.isEmpty {
                        Label("All (\(allTerms.count))", systemImage: "checkmark")
                    } else {
                        Text("All (\(allTerms.count))")
                    }
                }

                ForEach(TermCategory.allCases) { cat in
                    let count = allTerms.filter { $0.category == cat }.count
                    if count > 0 {
                        Button {
                            if selectedCategories.contains(cat) {
                                selectedCategories.remove(cat)
                            } else {
                                selectedCategories.insert(cat)
                            }
                        } label: {
                            if selectedCategories.contains(cat) {
                                Label("\(cat.rawValue) (\(count))", systemImage: "checkmark")
                            } else {
                                Text("\(cat.rawValue) (\(count))")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                if !selectedCategories.isEmpty {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .help("Sort and filter")
    }

    private func relookup(_ term: GlossaryTerm) {
        Task {
            let results = await DictionaryService.defineAll(term: term.term, context: term.surroundingText)
            if let best = results.first {
                await MainActor.run {
                    term.definition = best.definition
                    term.category = best.category
                    term.updatedAt = Date()
                    try? store.context.save()
                }
            }
        }
    }

    private func addNewTerm() {
        let newTerm = GlossaryTerm(
            term: "new term",
            definition: ""
        )
        store.context.insert(newTerm)
        try? store.context.save()
        selectedTerms = [newTerm]
    }
}


struct TermRowView: View {
    let term: GlossaryTerm
    var isSelected: Bool = false
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(term.displayTerm.isEmpty ? term.term.capitalized : term.displayTerm)
                .font(.headline)
                .foregroundStyle(isHovered && !isSelected ? Color.accentColor : .primary)

            Text(term.definition)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                if !term.sourceApp.isEmpty {
                    Text(term.sourceApp)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(term.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(term.category.rawValue)
                .font(.caption2)
                .foregroundStyle(isSelected ? .secondary : term.category.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isSelected ? Color.secondary.opacity(0.12) : term.category.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

struct HighlightedContextText: View {
    let text: String
    let term: String

    var body: some View {
        highlightedText
            .font(.callout)
            .italic()
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var highlightedText: Text {
        // Case-insensitive search on the original text to keep indices valid
        guard let range = text.range(of: term, options: .caseInsensitive) else {
            return Text("\"...\(text)...\"")
                .foregroundColor(.secondary)
        }

        let before = String(text[text.startIndex..<range.lowerBound])
        let match = String(text[range])
        let after = String(text[range.upperBound...])

        return Text("\"...")
            .foregroundColor(.secondary)
        + Text(before)
            .foregroundColor(.secondary)
        + Text(match)
            .bold()
            .foregroundColor(.accentColor)
        + Text(after)
            .foregroundColor(.secondary)
        + Text("...\"")
            .foregroundColor(.secondary)
    }
}

/// Editable link that switches between clickable and edit mode
struct EditableLink: View {
    @Binding var url: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "link")
                .font(.caption)
                .foregroundStyle(url.isEmpty ? Color.secondary : Color.blue)

            if isEditing || url.isEmpty {
                TextField("Add a source link (optional)", text: $url)
                    .font(.caption)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        isEditing = false
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused { isEditing = false }
                    }
            } else {
                Text(url)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .onTapGesture {
                        if let link = URL(string: url) {
                            NSWorkspace.shared.open(link)
                        }
                    }
                    .contextMenu {
                        Button("Edit link") { isEditing = true; isFocused = true }
                        Button("Copy link") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url, forType: .string)
                        }
                        Button("Open in browser") {
                            if let link = URL(string: url) {
                                NSWorkspace.shared.open(link)
                            }
                        }
                        Divider()
                        Button("Remove link", role: .destructive) { url = "" }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A small copy button that shows a checkmark briefly after copying
struct CopyButton: View {
    let text: String
    let label: String
    @State private var copied = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 13))
                .foregroundStyle(copied ? .green : .secondary)
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
        .help(label)
        .animation(.easeInOut(duration: 0.2), value: copied)
    }
}

struct TermDetailView: View {
    @Environment(GlossaryStore.self) private var store
    @Bindable var term: GlossaryTerm
    var onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var initialDefinition = ""
    @State private var initialTerm = ""
    @State private var initialContext = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("Term", text: $term.displayTerm)
                        .font(.largeTitle.bold())
                        .textFieldStyle(.plain)

                    CopyButton(text: term.displayTerm, label: "Copy term")
                        .fixedSize()

                    Spacer()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                    .help("Delete this term")
                    .fixedSize()
                }

                // Metadata
                HStack(spacing: 12) {
                    Picker("", selection: Binding(
                        get: { term.category },
                        set: { newValue in
                            term.category = newValue
                            term.updatedAt = Date()
                            try? store.context.save()
                        }
                    )) {
                        ForEach(TermCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .fixedSize()

                    if !term.sourceApp.isEmpty {
                        Text(term.sourceApp)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Label(
                        "Added on \(term.createdAt.formatted(date: .abbreviated, time: .shortened))",
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                // Original context
                if !term.surroundingText.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Original context")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        HighlightedContextText(text: term.surroundingText, term: term.term)
                    }
                }

                // Source link — below original context
                EditableLink(url: $term.sourceURL)
                    .onChange(of: term.sourceURL) { _, _ in
                        term.updatedAt = Date()
                        try? store.context.save()
                    }

                Divider()
                    .padding(.vertical, 4)

                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Definition")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        CopyButton(text: term.definition, label: "Copy definition")
                    }

                    TextEditor(text: $term.definition)
                        .font(.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Add notes about where you encountered this or how it's used at the company.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    TextEditor(text: $term.context)
                        .font(.body)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(24)
        }
        .onAppear { captureInitialValues() }
        .onChange(of: term.id) { _, _ in captureInitialValues() }
        .onDisappear { saveIfChanged() }
        .alert("Delete Term", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(term.term)\"? This can't be undone.")
        }
    }

    private func captureInitialValues() {
        initialDefinition = term.definition
        initialTerm = term.displayTerm
        initialContext = term.context
    }

    private func saveIfChanged() {
        let changed = term.definition != initialDefinition
            || term.displayTerm != initialTerm
            || term.context != initialContext
        if changed {
            // Keep lookup key in sync with display term
            term.term = term.displayTerm.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            term.updatedAt = Date()
            try? store.context.save()
        }
    }
}
