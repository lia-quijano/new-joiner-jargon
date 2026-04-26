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

    var hasCompletedOnboarding: Bool {
        didSet { save() }
    }

    private let apiKeyKey = "claude_api_key"
    private let companyContextKey = "company_context"
    private let onboardingKey = "hasCompletedOnboarding"

    init() {
        apiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
        companyContext = UserDefaults.standard.string(forKey: companyContextKey) ?? ""
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
    }

    var hasApiKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
        UserDefaults.standard.set(companyContext, forKey: companyContextKey)
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: onboardingKey)
    }
}
