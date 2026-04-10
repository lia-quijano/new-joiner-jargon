import Foundation
import SwiftUI

@Observable
final class SettingsManager {
    var apiKey: String {
        didSet { save() }
    }

    var companyContext: String {
        didSet { save() }
    }

    private let apiKeyKey = "claude_api_key"
    private let companyContextKey = "company_context"

    init() {
        apiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
        companyContext = UserDefaults.standard.string(forKey: companyContextKey) ?? ""
    }

    var hasApiKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
        UserDefaults.standard.set(companyContext, forKey: companyContextKey)
    }
}
