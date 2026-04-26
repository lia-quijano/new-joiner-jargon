import Foundation
import SwiftData
import SwiftUI

@Observable
final class GlossaryStore {
    let container: ModelContainer
    let context: ModelContext

    // Increment on every mutation to trigger SwiftUI re-renders
    private(set) var changeCount = 0

    init() {
        let schema = Schema([GlossaryTerm.self])
        let config = ModelConfiguration("NewJoinerJargon", isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
            context = ModelContext(container)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    func save(
        term: String,
        definition: String,
        context sourceContext: String = "",
        surroundingText: String = "",
        sourceApp: String = "",
        sourceURL: String = "",
        category: TermCategory = .uncategorized
    ) {
        let normalizedTerm = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let predicate = #Predicate<GlossaryTerm> { $0.term == normalizedTerm }
        let descriptor = FetchDescriptor(predicate: predicate)

        if let existing = try? context.fetch(descriptor).first {
            existing.displayTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.definition = definition
            existing.context = sourceContext
            existing.surroundingText = surroundingText
            existing.sourceApp = sourceApp
            existing.sourceURL = sourceURL
            existing.category = category
            existing.updatedAt = Date()
        } else {
            let entry = GlossaryTerm(
                term: normalizedTerm,
                displayTerm: term.trimmingCharacters(in: .whitespacesAndNewlines),
                definition: definition,
                context: sourceContext,
                surroundingText: surroundingText,
                sourceApp: sourceApp,
                sourceURL: sourceURL,
                category: category
            )
            context.insert(entry)
        }

        try? context.save()
        changeCount += 1
    }

    func lookup(_ term: String) -> GlossaryTerm? {
        let normalizedTerm = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let predicate = #Predicate<GlossaryTerm> { $0.term == normalizedTerm }
        let descriptor = FetchDescriptor(predicate: predicate)
        return try? context.fetch(descriptor).first
    }

    func allTerms() -> [GlossaryTerm] {
        // Access changeCount so SwiftUI tracks this dependency
        _ = changeCount
        let descriptor = FetchDescriptor<GlossaryTerm>(
            sortBy: [SortDescriptor(\.term)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func delete(_ term: GlossaryTerm) {
        context.delete(term)
        try? context.save()
        changeCount += 1
    }

    func search(_ query: String) -> [GlossaryTerm] {
        _ = changeCount
        let lowered = query.lowercased()
        let predicate = #Predicate<GlossaryTerm> {
            $0.term.contains(lowered) || $0.definition.contains(lowered)
        }
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.term)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func seedIndustryPacks(_ packs: [IndustryPack]) {
        for pack in packs {
            for seedTerm in pack.terms {
                let normalized = seedTerm.term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let predicate = #Predicate<GlossaryTerm> { $0.term == normalized }
                let descriptor = FetchDescriptor(predicate: predicate)
                guard (try? context.fetch(descriptor).first) == nil else { continue }

                let entry = GlossaryTerm(
                    term: normalized,
                    displayTerm: seedTerm.term.trimmingCharacters(in: .whitespacesAndNewlines),
                    definition: seedTerm.definition,
                    category: seedTerm.category
                )
                context.insert(entry)
            }
        }
        try? context.save()
        changeCount += 1
    }

    /// One-time migration: populate displayTerm for existing terms
    func migrateDisplayTerms() {
        let migratedKey = "hasMigratedDisplayTerms"
        guard !UserDefaults.standard.bool(forKey: migratedKey) else { return }

        let terms = allTerms()
        for term in terms where term.displayTerm.isEmpty {
            // Capitalize existing lowercased terms as a sensible default
            term.displayTerm = term.term.capitalized
        }

        try? context.save()
        changeCount += 1
        UserDefaults.standard.set(true, forKey: migratedKey)
    }

}
