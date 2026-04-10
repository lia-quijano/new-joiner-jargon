import Foundation

actor ClaudeService {
    private let apiKey: String
    private let companyContext: String
    private let model = "claude-haiku-4-5-20251001"
    private let baseURL = "https://api.anthropic.com/v1/messages"

    private var systemPrompt: String {
        var prompt = """
        You are a glossary assistant for someone who just joined a fintech company. \
        When given a term, respond with EXACTLY this format (no markdown, no extra text):

        CATEGORY: <one of: Business, Payments, Regulatory, Engineering, Product, People & Culture, Finance, Uncategorized>
        DEFINITION: <clear, concise definition in 2-3 sentences. Focus on how this term is used in a fintech/payments workplace context. Explain in plain language.>
        """

        if !companyContext.isEmpty {
            prompt += "\n\nCompany context:\n\(companyContext)"
        }

        return prompt
    }

    init(apiKey: String, companyContext: String = "") {
        self.apiKey = apiKey
        self.companyContext = companyContext
    }

    struct LookupResult {
        let definition: String
        let category: TermCategory
    }

    func define(term: String, surroundingText: String = "") async throws -> LookupResult {
        var userMessage = "Define the term: \"\(term)\""
        if !surroundingText.isEmpty {
            userMessage += "\n\nIt appeared in this context: \"\(surroundingText)\""
        }

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 300,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ClaudeError.apiError(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            throw ClaudeError.invalidResponse
        }

        return parseResponse(text)
    }

    private func parseResponse(_ text: String) -> LookupResult {
        var definition = text
        var category = TermCategory.uncategorized

        // Parse CATEGORY: line
        if let categoryRange = text.range(of: "CATEGORY:") {
            let afterCategory = text[categoryRange.upperBound...]
            let categoryLine = afterCategory.prefix(while: { $0 != "\n" }).trimmingCharacters(in: .whitespaces)
            category = TermCategory(rawValue: categoryLine) ?? .uncategorized
        }

        // Parse DEFINITION: line
        if let defRange = text.range(of: "DEFINITION:") {
            definition = String(text[defRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return LookupResult(definition: definition, category: category)
    }

    enum ClaudeError: LocalizedError {
        case invalidResponse
        case apiError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from API"
            case .apiError(let code):
                return "API error (status \(code))"
            }
        }
    }
}
