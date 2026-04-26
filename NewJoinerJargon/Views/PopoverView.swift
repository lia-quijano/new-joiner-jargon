import SwiftUI

struct PopoverView: View {
    @Environment(GlossaryStore.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(CaptureState.self) private var capture
    @Environment(NavigationState.self) private var navigation
    @Environment(\.openWindow) private var openWindow

    @State private var inputText = ""
    @State private var definition = ""
    @State private var sourceApp = ""
    @State private var surroundingText = ""
    @State private var sourceURL = ""
    @State private var manualURL = ""
    @State private var selectedCategory: TermCategory = .uncategorized
    @State private var isLoading = false
    @State private var isSaved = false
    @State private var noDefinitionFound = false
    @State private var alternativeDefinitions: [DictionaryService.LookupResult] = []
    @State private var errorMessage = ""
    @State private var hasPermission = AccessibilityService.hasPermission
    @State private var permissionCheckTimer: Timer?

    @State private var recentlySaved: [RecentTerm] = []
    @State private var newlyAddedId: String?
    @State private var lastProcessedCaptureId = ""

    struct RecentTerm: Identifiable {
        let id: String
        let term: String
        let category: TermCategory
        let savedAt: Date

        init(term: String, category: TermCategory) {
            self.id = UUID().uuidString
            self.term = term
            self.category = category
            self.savedAt = Date()
        }
    }

    var body: some View {
        mainView
    }

    @ViewBuilder
    private var mainView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.blue)
                Text("New Joiner Jargon")
                    .font(.headline)
                Spacer()
                Button {
                    openWindow(id: "glossary")
                } label: {
                    Image(systemName: "list.bullet")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open full glossary")
            }

            Divider()

            // Accessibility permission banner
            if !hasPermission {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility access needed")
                            .font(.caption.bold())
                        Text("Grant in System Settings to use ⌃⌥J")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Grant") {
                        AccessibilityService.requestPermission()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Input
            HStack {
                TextField("Type a term or press ⌃⌥J to capture...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { lookUp() }

                Button(action: lookUp) {
                    Image(systemName: "magnifyingglass")
                }
                .disabled(inputText.isEmpty || isLoading)
            }

            // Source context bar
            if !sourceApp.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: sourceAppIcon)
                        .font(.caption)
                    Text("from **\(sourceApp)**")
                        .font(.caption)
                    Text("· \(capture.timestamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.secondary)
            }

            // Surrounding sentence preview
            if !surroundingText.isEmpty {
                Text("\"...\(surroundingText)...\"")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Definition area
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Looking up...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
            } else if !definition.isEmpty || noDefinitionFound {
                VStack(alignment: .leading, spacing: 12) {
                    // Term title
                    Text(inputText)
                        .font(.system(.title3, weight: .semibold))

                    // Source link — above definition
                    TextField("Source link", text: effectiveURLBinding)
                        .font(.caption)
                        .textFieldStyle(.roundedBorder)

                    // Category picker + Search with Google
                    HStack {
                        Picker("", selection: $selectedCategory) {
                            ForEach(TermCategory.allCases) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .controlSize(.small)
                        .fixedSize()

                        Spacer()

                        Button {
                            let query = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inputText
                            if let url = URL(string: "https://www.google.com/search?q=\(query)+meaning+definition") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Label("Search with Google", systemImage: "magnifyingglass")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    // No definition found
                    if noDefinitionFound && definition.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(.orange)
                            Text("No definition found — write your own below")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Editable definition
                    TextEditor(text: $definition)
                        .font(.body)
                        .frame(height: 80)
                        .padding(4)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Alternative definitions
                    if alternativeDefinitions.count > 1 {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Other definitions")
                                .font(.caption)
                                .foregroundStyle(.tertiary)

                            ForEach(alternativeDefinitions.dropFirst().prefix(4)) { alt in
                                Button {
                                    definition = alt.definition
                                    selectedCategory = alt.category
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(alt.definition)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Text(alt.source)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.secondary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    // Actions
                    HStack {
                        Button {
                            saveToGlossary()
                        } label: {
                            Label(
                                isSaved ? "Saved!" : "Save to Glossary",
                                systemImage: isSaved ? "checkmark.circle.fill" : "plus.circle"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isSaved ? .green : .blue)
                        .disabled(definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Spacer()

                        Button("Clear definition") {
                            definition = ""
                            noDefinitionFound = true
                        }
                        .buttonStyle(.bordered)

                        Button("Reset") {
                            reset()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                // Empty state or recently saved
                if recentlySaved.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Select any word in any app and press **⌃⌥J**\nto capture and look it up")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }

            // Recently saved section
            if !recentlySaved.isEmpty && definition.isEmpty && !isLoading {
                recentlySavedSection
            }

            Divider()

            // Footer
            HStack {
                Button {
                    openWindow(id: "glossary")
                } label: {
                    HStack(spacing: 4) {
                        Text("\(store.allTerms().count) terms saved")
                            .font(.caption)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open glossary")
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 360)
        .onChange(of: capture.term) { _, newValue in
            handleCapture(newValue)
        }
        .onAppear {
            if !settings.hasCompletedOnboarding {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "glossary")
            }
            hasPermission = AccessibilityService.hasPermission
            if !capture.term.isEmpty {
                handleCapture(capture.term)
            }
            // Poll for permission changes every 2 seconds until granted
            if !hasPermission {
                permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    let granted = AccessibilityService.hasPermission
                    if granted {
                        DispatchQueue.main.async {
                            withAnimation {
                                hasPermission = true
                            }
                            permissionCheckTimer?.invalidate()
                            permissionCheckTimer = nil
                        }
                    }
                }
            }
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
        }
    }

    private func handleCapture(_ term: String) {
        guard !term.isEmpty else { return }
        let captureId = "\(term)-\(capture.timestamp.timeIntervalSince1970)"
        guard captureId != lastProcessedCaptureId else { return }
        lastProcessedCaptureId = captureId

        inputText = term
        sourceApp = capture.sourceApp
        surroundingText = capture.surroundingText
        sourceURL = capture.sourceURL
        manualURL = ""
        lookUp()
    }

    // MARK: - Recently Saved

    private var recentlySavedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recently saved")
                .font(.caption)
                .foregroundStyle(.tertiary)

            ForEach(recentlySaved) { recent in
                RecentTermRow(
                    recent: recent,
                    isHighlighted: newlyAddedId == recent.id
                ) {
                    navigation.navigateTo(term: recent.term)
                    openWindow(id: "glossary")
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Helpers

    private var effectiveURLBinding: Binding<String> {
        Binding(
            get: { sourceURL.isEmpty ? manualURL : sourceURL },
            set: { newValue in
                if sourceURL.isEmpty {
                    manualURL = newValue
                } else {
                    sourceURL = newValue
                }
            }
        )
    }

    private var resolvedURL: String {
        sourceURL.isEmpty ? manualURL : sourceURL
    }

    private var sourceAppIcon: String {
        let name = sourceApp.lowercased()
        if name.contains("slack") { return "number.square" }
        if name.contains("chrome") || name.contains("safari") || name.contains("firefox") || name.contains("arc") { return "globe" }
        if name.contains("notion") { return "doc.text" }
        if name.contains("figma") { return "paintbrush" }
        if name.contains("mail") { return "envelope" }
        if name.contains("terminal") { return "terminal" }
        if name.contains("zoom") || name.contains("meet") { return "video" }
        return "app.badge"
    }

    // MARK: - Actions

    private func lookUp() {
        guard !inputText.isEmpty else { return }
        isSaved = false
        errorMessage = ""

        if let existing = store.lookup(inputText) {
            definition = existing.definition
            sourceApp = existing.sourceApp
            selectedCategory = existing.category
            surroundingText = existing.surroundingText
            sourceURL = existing.sourceURL
            return
        }

        isLoading = true
        let term = inputText
        let context = surroundingText

        Task {
            // Get all definitions with context-based ranking
            let allResults = await DictionaryService.defineAll(term: term, context: context)

            if !allResults.isEmpty {
                await MainActor.run {
                    let best = allResults[0]
                    definition = best.definition
                    selectedCategory = best.category
                    alternativeDefinitions = allResults
                    isLoading = false
                }
                return
            }

            // Fallback to Claude API if available
            if settings.hasApiKey {
                do {
                    let claude = ClaudeService(apiKey: settings.apiKey, companyContext: settings.companyContext)
                    let result = try await claude.define(term: term, surroundingText: context)
                    await MainActor.run {
                        definition = result.definition
                        selectedCategory = result.category
                        alternativeDefinitions = []
                        isLoading = false
                    }
                    return
                } catch {
                    await MainActor.run {
                        errorMessage = "API lookup failed, using manual mode"
                    }
                }
            }

            await MainActor.run {
                definition = ""
                noDefinitionFound = true
                alternativeDefinitions = []
                isLoading = false
            }
        }
    }

    private func saveToGlossary() {
        let savedTerm = inputText
        let savedCategory = selectedCategory

        store.save(
            term: savedTerm,
            definition: definition,
            surroundingText: surroundingText,
            sourceApp: sourceApp,
            sourceURL: resolvedURL,
            category: savedCategory
        )

        // Navigate to saved term in glossary (if glossary window is already open)
        navigation.navigateTo(term: savedTerm)

        let recent = RecentTerm(term: savedTerm, category: savedCategory)

        withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
            recentlySaved.insert(recent, at: 0)
            if recentlySaved.count > 3 {
                recentlySaved.removeLast()
            }
            newlyAddedId = recent.id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                newlyAddedId = nil
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.3)) {
                clearForm()
            }
        }
    }

    private func clearForm() {
        inputText = ""
        definition = ""
        sourceApp = ""
        surroundingText = ""
        sourceURL = ""
        manualURL = ""
        selectedCategory = .uncategorized
        isSaved = false
        noDefinitionFound = false
        alternativeDefinitions = []
        errorMessage = ""
        capture.clear()
    }

    private func reset() {
        clearForm()
    }
}

struct RecentTermRow: View {
    let recent: PopoverView.RecentTerm
    let isHighlighted: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Text(recent.term)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                Text(recent.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(recent.savedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            isHighlighted
                ? Color.green.opacity(0.08)
                : isHovered ? Color.primary.opacity(0.06) : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
