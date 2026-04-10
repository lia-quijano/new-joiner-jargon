import Foundation
import SwiftData

@Model
final class GlossaryTerm {
    var term: String              // lowercased key for lookups
    var displayTerm: String = ""   // original casing (e.g. "ARPU")
    var definition: String
    var context: String           // user's personal notes
    var surroundingText: String   // the sentence it appeared in
    var sourceApp: String         // auto-detected app name
    var sourceURL: String         // browser URL if captured from a browser
    var categoryRaw: String
    var createdAt: Date
    var updatedAt: Date

    var category: TermCategory {
        get { TermCategory(rawValue: categoryRaw) ?? .uncategorized }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        term: String,
        displayTerm: String? = nil,
        definition: String,
        context: String = "",
        surroundingText: String = "",
        sourceApp: String = "",
        sourceURL: String = "",
        category: TermCategory = .uncategorized
    ) {
        self.term = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.displayTerm = displayTerm ?? term
        self.definition = definition
        self.context = context
        self.surroundingText = surroundingText
        self.sourceApp = sourceApp
        self.sourceURL = sourceURL
        self.categoryRaw = category.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
