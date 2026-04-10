import Foundation

/// Free dictionary lookups — no API key needed.
/// Built-in glossary → Wikipedia summary → Free Dictionary API
enum DictionaryService {

    struct LookupResult: Identifiable {
        let id = UUID()
        let definition: String
        let category: TermCategory
        var source: String = "Built-in glossary"
    }

    /// Returns a single best definition (for backward compatibility)
    static func define(term: String) async -> LookupResult? {
        let results = await defineAll(term: term)
        return results.first
    }

    /// Returns ALL available definitions from all sources, best match first.
    /// Use the surrounding context to rank which definition is most relevant.
    static func defineAll(term: String, context: String = "") async -> [LookupResult] {
        let normalized = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var results: [LookupResult] = []

        // 1. Built-in glossary (may have multiple meanings)
        if let builtins = builtInGlossary[normalized] {
            for builtin in builtins {
                results.append(LookupResult(
                    definition: builtin.definition,
                    category: builtin.category,
                    source: "Built-in glossary"
                ))
            }
        }

        // 2. Wikipedia — try context-specific search first (e.g., "branch (version control)")
        let contextHints = guessContextHint(term: normalized, context: context)
        for hint in contextHints {
            if let wiki = await lookupWikipedia(hint) {
                if !results.contains(where: { $0.definition == wiki.definition }) {
                    results.append(LookupResult(
                        definition: wiki.definition,
                        category: wiki.category,
                        source: "Wikipedia"
                    ))
                    break // found a good contextual result
                }
            }
        }
        // Also try the plain term if no contextual result
        if !results.contains(where: { $0.source == "Wikipedia" }) {
            if let wiki = await lookupWikipedia(term) {
                if !results.contains(where: { $0.definition == wiki.definition }) {
                    results.append(LookupResult(
                        definition: wiki.definition,
                        category: wiki.category,
                        source: "Wikipedia"
                    ))
                }
            }
        }

        // 3. Wikipedia search (fuzzy) — finds related articles when exact match fails
        if !results.contains(where: { $0.source == "Wikipedia" }) {
            if let searchResult = await searchWikipedia(term) {
                results.append(LookupResult(
                    definition: searchResult.definition,
                    category: searchResult.category,
                    source: "Wikipedia"
                ))
            }
        }

        // 4. Free dictionary API — get ALL meanings
        let dictResults = await lookupFreeDictionaryAll(normalized)
        for dr in dictResults {
            if !results.contains(where: { $0.definition == dr.definition }) {
                results.append(dr)
            }
        }

        // If we have context, try to rank the most relevant definition first
        if !context.isEmpty && results.count > 1 {
            results = rankByContext(results: results, context: context)
        }

        return results
    }

    // MARK: - Wikipedia API (free, no key)

    private static func lookupWikipedia(_ term: String) async -> LookupResult? {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else {
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("NewJoinerJargon/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let extract = json["extract"] as? String,
                  !extract.isEmpty else {
                return nil
            }

            // Filter out useless disambiguation pages
            let lower = extract.lowercased()
            if lower.contains("may refer to")
                || lower.contains("can refer to")
                || lower.contains("may stand for")
                || lower.contains("can stand for")
                || lower.contains("most commonly refers to")
                || lower.contains("is a disambiguation")
                || (lower.hasSuffix("may refer to:.") || lower.hasSuffix("may stand for:.")) {
                return nil
            }

            // Cap at 2-3 sentences
            let sentences = extract.components(separatedBy: ". ")
            let summary = sentences.prefix(3).joined(separator: ". ")
            let trimmed = summary.hasSuffix(".") ? summary : summary + "."

            let category = guessCategory(from: lower)

            return LookupResult(definition: trimmed, category: category, source: "Wikipedia")
        } catch {
            return nil
        }
    }

    /// Search Wikipedia (fuzzy) — finds the best matching article
    private static func searchWikipedia(_ term: String) async -> LookupResult? {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=\(encoded)&srwhat=text&srlimit=1&format=json") else {
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.setValue("NewJoinerJargon/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let query = json["query"] as? [String: Any],
                  let searchResults = query["search"] as? [[String: Any]],
                  let first = searchResults.first,
                  let title = first["title"] as? String else {
                return nil
            }

            // Now fetch the summary for the found article
            return await lookupWikipedia(title)
        } catch {
            return nil
        }
    }

    /// Guess a category based on keywords in the definition
    private static func guessCategory(from text: String) -> TermCategory {
        let lower = text.lowercased()
        if lower.contains("payment") || lower.contains("transaction") || lower.contains("fintech") || lower.contains("banking") {
            return .payments
        }
        if lower.contains("regulation") || lower.contains("compliance") || lower.contains("license") || lower.contains("law") {
            return .regulatory
        }
        if lower.contains("software") || lower.contains("programming") || lower.contains("protocol") || lower.contains("network") || lower.contains("computing") || lower.contains("security") {
            return .engineering
        }
        if lower.contains("revenue") || lower.contains("financial") || lower.contains("accounting") || lower.contains("investment") {
            return .finance
        }
        if lower.contains("product") || lower.contains("agile") || lower.contains("scrum") || lower.contains("management") {
            return .product
        }
        if lower.contains("employee") || lower.contains("human resources") || lower.contains("hiring") {
            return .people
        }
        if lower.contains("business") || lower.contains("company") || lower.contains("market") || lower.contains("strategy") {
            return .business
        }
        return .uncategorized
    }

    /// Generate context-specific Wikipedia search terms
    /// e.g., "branch" in a coding context → try "branch (version control)" first
    private static func guessContextHint(term: String, context: String) -> [String] {
        let ctx = context.lowercased()
        var hints: [String] = []

        let techKeywords = ["code", "git", "github", "deploy", "api", "server", "database", "software", "app", "dev", "engineering", "tech", "programming", "build", "release", "merge", "commit", "pull request", "repo"]
        let financeKeywords = ["bank", "payment", "money", "finance", "invest", "fund", "capital", "revenue", "profit", "stock"]
        let businessKeywords = ["market", "sales", "customer", "business", "company", "strategy", "product", "growth"]

        if techKeywords.contains(where: { ctx.contains($0) }) {
            hints.append("\(term) (software)")
            hints.append("\(term) (computing)")
            hints.append("\(term) (version control)")
        }
        if financeKeywords.contains(where: { ctx.contains($0) }) {
            hints.append("\(term) (finance)")
            hints.append("\(term) (banking)")
        }
        if businessKeywords.contains(where: { ctx.contains($0) }) {
            hints.append("\(term) (business)")
            hints.append("\(term) (marketing)")
        }

        return hints
    }

    // MARK: - Free Dictionary API

    private static func lookupFreeDictionary(_ term: String) async -> LookupResult? {
        let results = await lookupFreeDictionaryAll(term)
        return results.first
    }

    /// Returns ALL meanings from the free dictionary API
    private static func lookupFreeDictionaryAll(_ term: String) async -> [LookupResult] {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encoded)") else {
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return []
            }

            guard let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let firstEntry = entries.first,
                  let meanings = firstEntry["meanings"] as? [[String: Any]] else {
                return []
            }

            var results: [LookupResult] = []
            for meaning in meanings {
                let partOfSpeech = meaning["partOfSpeech"] as? String ?? ""
                guard let definitions = meaning["definitions"] as? [[String: Any]] else { continue }

                for def in definitions.prefix(2) { // max 2 per part of speech
                    guard let text = def["definition"] as? String else { continue }
                    let label = partOfSpeech.isEmpty ? "Dictionary" : "Dictionary (\(partOfSpeech))"
                    results.append(LookupResult(
                        definition: text,
                        category: .uncategorized,
                        source: label
                    ))
                }
            }

            return results
        } catch {
            return []
        }
    }

    /// Rank definitions by relevance to the surrounding context
    private static func rankByContext(results: [LookupResult], context: String) -> [LookupResult] {
        let contextWords = Set(context.lowercased().split(separator: " ").map(String.init))

        let scored = results.map { result -> (LookupResult, Int) in
            let defWords = Set(result.definition.lowercased().split(separator: " ").map(String.init))
            let overlap = contextWords.intersection(defWords).count
            // Boost built-in glossary results
            let sourceBoost = result.source == "Built-in glossary" ? 5 : 0
            return (result, overlap + sourceBoost)
        }

        return scored.sorted { $0.1 > $1.1 }.map(\.0)
    }

    // MARK: - Built-in Glossary

    static let builtInGlossary: [String: [LookupResult]] = [
        // Payments & Fintech
        "svf": [LookupResult(definition: "Stored Value Facility — a license issued by a central bank allowing a company to hold and manage electronic money on behalf of customers.", category: .regulatory)],
        "kyc": [LookupResult(definition: "Know Your Customer — the process of verifying the identity of customers before or during the time they start doing business with a financial institution.", category: .regulatory)],
        "aml": [LookupResult(definition: "Anti-Money Laundering — a set of laws, regulations, and procedures designed to prevent criminals from disguising illegally obtained funds as legitimate income.", category: .regulatory)],
        "pci dss": [LookupResult(definition: "Payment Card Industry Data Security Standard — a set of security standards designed to ensure that all companies that process, store, or transmit credit card information maintain a secure environment.", category: .regulatory)],
        "pci": [LookupResult(definition: "Payment Card Industry — refers to the industry standards and compliance requirements for handling payment card data securely.", category: .regulatory)],
        "p2p": [LookupResult(definition: "Peer-to-Peer — a payment method that allows individuals to send money directly to each other without going through a traditional bank transfer.", category: .payments)],
        "nfc": [LookupResult(definition: "Near Field Communication — a short-range wireless technology that enables contactless payments when you tap your phone or card on a terminal.", category: .payments)],
        "qr code": [LookupResult(definition: "Quick Response code — a two-dimensional barcode that can be scanned to initiate a payment, share a link, or transfer information.", category: .payments)],
        "payment gateway": [LookupResult(definition: "A service that authorizes and processes credit card or direct payment transactions between a customer and a merchant's website or app.", category: .payments)],
        "settlement": [LookupResult(definition: "The process of transferring funds from the customer's bank to the merchant's account after a transaction has been authorized and captured.", category: .payments)],
        "chargeback": [LookupResult(definition: "A reversal of a credit card payment that comes directly from the bank. It occurs when a customer disputes a charge on their statement.", category: .payments)],
        "interchange fee": [LookupResult(definition: "A fee paid between banks for the acceptance of card-based transactions, typically paid by the merchant's bank to the cardholder's bank.", category: .payments)],
        "acquiring bank": [LookupResult(definition: "The bank or financial institution that processes credit or debit card payments on behalf of a merchant. Also called the acquirer.", category: .payments)],
        "issuing bank": [LookupResult(definition: "The bank that issues a credit or debit card to a consumer on behalf of the card network (Visa, Mastercard, etc.).", category: .payments)],
        "mdr": [LookupResult(definition: "Merchant Discount Rate — the fee charged to a merchant for processing each debit and credit card transaction.", category: .payments)],
        "iban": [LookupResult(definition: "International Bank Account Number — a standard international numbering system used to identify bank accounts across borders.", category: .finance)],
        "swift": [LookupResult(definition: "Society for Worldwide Interbank Financial Telecommunication — a network that enables financial institutions to send and receive information about financial transactions.", category: .finance)],
        "open banking": [LookupResult(definition: "A system where banks provide third-party access to customer financial data through APIs, enabling new financial products and services.", category: .payments)],
        "open finance": [LookupResult(definition: "An extension of open banking that goes beyond bank accounts to include insurance, pensions, investments, and other financial products.", category: .payments)],
        "embedded finance": [LookupResult(definition: "The integration of financial services (payments, lending, insurance) into non-financial platforms and apps.", category: .payments)],
        "bnpl": [LookupResult(definition: "Buy Now Pay Later — a short-term financing option that allows customers to split purchases into installments, often interest-free.", category: .payments)],
        "spv": [LookupResult(definition: "Special Purpose Vehicle — a subsidiary entity created for a specific business purpose, often used to isolate financial risk.", category: .finance)],
        "arpu": [LookupResult(definition: "Average Revenue Per User — a metric that measures the revenue generated per user or account, commonly used to track business growth.", category: .finance)],
        "arr": [LookupResult(definition: "Annual Recurring Revenue — the predictable revenue a company expects to receive annually from subscriptions or contracts.", category: .finance)],
        "mrr": [LookupResult(definition: "Monthly Recurring Revenue — the predictable revenue a company expects to receive each month from subscriptions.", category: .finance)],
        "gmv": [LookupResult(definition: "Gross Merchandise Value — the total value of merchandise or transactions processed through a platform before deducting fees and returns.", category: .finance)],
        "tpv": [LookupResult(definition: "Total Payment Volume — the total dollar amount of payments processed through a payment platform over a given period.", category: .payments)],
        "cac": [LookupResult(definition: "Customer Acquisition Cost — the total cost of acquiring a new customer, including marketing, sales, and onboarding expenses.", category: .business)],
        "ltv": [LookupResult(definition: "Lifetime Value — the total revenue a business expects from a single customer account throughout their entire relationship.", category: .business)],
        "tam": [LookupResult(definition: "Total Addressable Market — the overall revenue opportunity available if a product achieves 100% market share.", category: .business)],
        "sam": [LookupResult(definition: "Serviceable Addressable Market — the portion of the TAM that your product or service can actually reach and serve.", category: .business)],

        // Engineering / Tech — common acronyms
        "vpn": [LookupResult(definition: "Virtual Private Network — a service that encrypts your internet connection and routes it through a server in another location, protecting your privacy and allowing secure access to company resources.", category: .engineering)],
        "csp": [LookupResult(definition: "Content Security Policy — a security standard that helps prevent cross-site scripting (XSS), clickjacking, and other code injection attacks by specifying which sources of content are allowed.", category: .engineering)],
        "api": [LookupResult(definition: "Application Programming Interface — a set of rules and protocols that allows different software applications to communicate with each other.", category: .engineering)],
        "sdk": [LookupResult(definition: "Software Development Kit — a collection of tools, libraries, and documentation that developers use to build applications for a specific platform.", category: .engineering)],
        "ci/cd": [LookupResult(definition: "Continuous Integration / Continuous Deployment — automated processes for building, testing, and deploying code changes to production.", category: .engineering)],
        "ci": [LookupResult(definition: "Continuous Integration — the practice of automatically building and testing code every time a developer commits changes, catching issues early.", category: .engineering)],
        "cd": [LookupResult(definition: "Continuous Deployment — the practice of automatically deploying code to production after it passes all tests, reducing manual release steps.", category: .engineering)],
        "pr": [LookupResult(definition: "Pull Request — a method of submitting code changes for review before merging into the main codebase.", category: .engineering)],
        "cors": [LookupResult(definition: "Cross-Origin Resource Sharing — a security mechanism that allows or restricts web applications from making requests to a different domain than the one serving the page.", category: .engineering)],
        "crud": [LookupResult(definition: "Create, Read, Update, Delete — the four basic operations for persistent storage, commonly used to describe API endpoints.", category: .engineering)],
        "oauth": [LookupResult(definition: "Open Authorization — a standard protocol that allows third-party applications to access user data without exposing passwords.", category: .engineering)],
        "jwt": [LookupResult(definition: "JSON Web Token — a compact, URL-safe token format used to securely transmit information between parties, commonly used for authentication.", category: .engineering)],
        "ssl": [LookupResult(definition: "Secure Sockets Layer — a security protocol that encrypts data transmitted between a web server and browser. Now succeeded by TLS.", category: .engineering)],
        "tls": [LookupResult(definition: "Transport Layer Security — the modern encryption protocol that secures communication over the internet, successor to SSL.", category: .engineering)],
        "dns": [LookupResult(definition: "Domain Name System — the system that translates human-readable domain names (like google.com) into IP addresses that computers use.", category: .engineering)],
        "ssh": [LookupResult(definition: "Secure Shell — a protocol for securely connecting to remote computers over an unsecured network, commonly used by developers.", category: .engineering)],
        "cdn": [LookupResult(definition: "Content Delivery Network — a distributed network of servers that delivers web content to users based on their geographic location, improving speed.", category: .engineering)],
        "aws": [LookupResult(definition: "Amazon Web Services — Amazon's cloud computing platform offering services like hosting, databases, storage, and machine learning.", category: .engineering)],
        "gcp": [LookupResult(definition: "Google Cloud Platform — Google's suite of cloud computing services for hosting, storage, data analytics, and machine learning.", category: .engineering)],
        "ide": [LookupResult(definition: "Integrated Development Environment — a software application that provides tools for coding, debugging, and testing in one place (e.g., VS Code, Xcode).", category: .engineering)],
        "ui": [LookupResult(definition: "User Interface — the visual elements (buttons, menus, screens) that a user interacts with in an application.", category: .engineering)],
        "ux": [LookupResult(definition: "User Experience — the overall experience a person has when using a product, including ease of use, satisfaction, and efficiency.", category: .product)],
        "sso": [LookupResult(definition: "Single Sign-On — an authentication method that allows users to log in once and access multiple applications without re-entering credentials.", category: .engineering)],
        "mfa": [LookupResult(definition: "Multi-Factor Authentication — a security method that requires two or more verification steps (password + phone code, etc.) to access an account.", category: .engineering)],
        "2fa": [LookupResult(definition: "Two-Factor Authentication — a security process requiring two different forms of identification to access an account, typically a password and a code.", category: .engineering)],
        "sql": [LookupResult(definition: "Structured Query Language — the standard programming language used to manage and query relational databases.", category: .engineering)],
        "html": [LookupResult(definition: "HyperText Markup Language — the standard markup language used to create and structure content on web pages.", category: .engineering)],
        "css": [LookupResult(definition: "Cascading Style Sheets — the language used to describe the visual presentation and styling of HTML web pages.", category: .engineering)],
        "json": [LookupResult(definition: "JavaScript Object Notation — a lightweight data format used to transmit data between a server and a web application, easy for humans and machines to read.", category: .engineering)],
        "webhook": [LookupResult(definition: "An automated HTTP callback triggered by an event in a source system, used to send real-time notifications to another system.", category: .engineering)],
        "microservices": [LookupResult(definition: "An architectural approach where an application is built as a collection of small, independent services that communicate over APIs.", category: .engineering)],
        "saas": [LookupResult(definition: "Software as a Service — a software distribution model where applications are hosted in the cloud and accessed via the internet on a subscription basis.", category: .engineering)],
        "devops": [LookupResult(definition: "A set of practices combining software development and IT operations to shorten the development lifecycle and deliver features more frequently.", category: .engineering)],
        "qa": [LookupResult(definition: "Quality Assurance — the process of ensuring software meets specified requirements and quality standards through testing and review.", category: .engineering)],
        "uat": [LookupResult(definition: "User Acceptance Testing — the final phase of testing where real users validate that the software meets their needs before it goes live.", category: .engineering)],
        "eta": [LookupResult(definition: "Estimated Time of Arrival — used broadly to mean the expected completion time for a task, feature, or delivery.", category: .business)],
        "eod": [LookupResult(definition: "End of Day — typically means the end of the business day, used as a deadline (e.g., 'I'll have it by EOD').", category: .business)],
        "eow": [LookupResult(definition: "End of Week — used as a deadline meaning by Friday close of business.", category: .business)],
        "wfh": [LookupResult(definition: "Work From Home — working remotely from your home rather than from the office.", category: .people)],
        "ooo": [LookupResult(definition: "Out of Office — indicates someone is unavailable, typically used in email auto-replies and calendar events.", category: .people)],
        "pto": [LookupResult(definition: "Paid Time Off — vacation or personal days that employees can take while still receiving their salary.", category: .people)],

        // Product
        "mvp": [LookupResult(definition: "Minimum Viable Product — the simplest version of a product that can be released to validate a business idea and gather user feedback.", category: .product)],
        "poc": [LookupResult(definition: "Proof of Concept — a small project or experiment to demonstrate the feasibility of an idea or approach before full development.", category: .product), LookupResult(definition: "Point of Contact — the designated person for communication on a project or between teams.", category: .business)],
        "okr": [LookupResult(definition: "Objectives and Key Results — a goal-setting framework where teams define measurable objectives and track progress through quantifiable key results.", category: .product)],
        "kpi": [LookupResult(definition: "Key Performance Indicator — a measurable value that demonstrates how effectively a company or team is achieving its key business objectives.", category: .business)],
        "prd": [LookupResult(definition: "Product Requirements Document — a document written by product managers that describes what a product should do, who it's for, and why it matters.", category: .product)],
        "rfc": [LookupResult(definition: "Request for Comments — a document proposing a technical design or process change, shared with the team for feedback before implementation.", category: .product)],
        "standup": [LookupResult(definition: "A short daily meeting (usually 15 minutes) where team members share what they worked on, what they're doing next, and any blockers.", category: .product)],
        "sprint": [LookupResult(definition: "A fixed time period (usually 1-2 weeks) during which a team works to complete a set of planned tasks or user stories.", category: .product)],
        "retro": [LookupResult(definition: "Retrospective — a meeting held at the end of a sprint to reflect on what went well, what didn't, and what can be improved.", category: .product)],
        "backlog": [LookupResult(definition: "A prioritized list of features, bug fixes, and tasks that a team plans to work on in future sprints.", category: .product)],
        "stakeholder": [LookupResult(definition: "Anyone who has an interest in or is affected by a project or decision — can include executives, users, partners, or team members.", category: .business)],
        "sla": [LookupResult(definition: "Service Level Agreement — a commitment between a service provider and a client that defines the expected level of service, uptime, and response times.", category: .business)],
        "b2b": [LookupResult(definition: "Business-to-Business — a model where a company sells products or services to other businesses rather than individual consumers.", category: .business)],
        "b2c": [LookupResult(definition: "Business-to-Consumer — a model where a company sells products or services directly to individual consumers.", category: .business)],
        "sme": [LookupResult(definition: "Small and Medium Enterprise — a business with a limited number of employees and revenue, typically fewer than 250 employees.", category: .business)],
        "eosb": [LookupResult(definition: "End of Service Benefits — a lump sum payment made to employees upon termination of employment, common in UAE and GCC labor law.", category: .finance)],
        "wps": [LookupResult(definition: "Wage Protection System — a UAE government system that ensures employers pay workers on time through approved banks and exchange houses.", category: .regulatory)],
        "roi": [LookupResult(definition: "Return on Investment — a measure of profitability that calculates how much return you get relative to the cost of an investment.", category: .finance)],
        "p&l": [LookupResult(definition: "Profit and Loss — a financial statement summarizing revenues, costs, and expenses during a specific period.", category: .finance)],
        "cfo": [LookupResult(definition: "Chief Financial Officer — the senior executive responsible for managing a company's finances, financial planning, and reporting.", category: .business)],
        "cto": [LookupResult(definition: "Chief Technology Officer — the senior executive responsible for a company's technological direction, engineering team, and technical strategy.", category: .business)],
        "ceo": [LookupResult(definition: "Chief Executive Officer — the highest-ranking executive in a company, responsible for overall strategy and major decisions.", category: .business)],
        "coo": [LookupResult(definition: "Chief Operating Officer — the senior executive responsible for the day-to-day operations and internal affairs of a company.", category: .business)],
        "cpo": [LookupResult(definition: "Chief Product Officer — the senior executive responsible for product strategy, vision, and the overall product roadmap.", category: .business)],

        // People & Culture
        "1:1": [LookupResult(definition: "One-on-One — a regular private meeting between a manager and their direct report to discuss progress, feedback, and career development.", category: .people)],
        "onboarding": [LookupResult(definition: "The process of integrating a new employee into a company, including training, introductions, and getting set up with tools and access.", category: .people)],
        "ic": [LookupResult(definition: "Individual Contributor — an employee who does not manage others and contributes through their own expertise and output.", category: .people)],
        "hrbp": [LookupResult(definition: "Human Resources Business Partner — an HR professional who works closely with a specific business unit to align people strategy with business goals.", category: .people)],
        "pip": [LookupResult(definition: "Performance Improvement Plan — a formal document outlining specific areas where an employee needs to improve, with a timeline and measurable goals.", category: .people)],

        // ── Devpedia imports ──

        // Architecture & Infrastructure
        "acid": [LookupResult(definition: "Atomicity, Consistency, Isolation, Durability — four properties that guarantee reliable database transactions, even in the event of errors or crashes.", category: .engineering)],
        "api gateway": [LookupResult(definition: "A server that acts as the single entry point for API requests, handling routing, rate limiting, authentication, and load balancing across backend services.", category: .engineering)],
        "caching": [LookupResult(definition: "Storing frequently accessed data in a temporary, fast-access layer (like memory) to reduce load on databases and speed up responses.", category: .engineering)],
        "cap theorem": [LookupResult(definition: "States that a distributed system can only guarantee two of three properties: Consistency, Availability, and Partition Tolerance.", category: .engineering)],
        "containerization": [LookupResult(definition: "Packaging an application with all its dependencies into a standardized unit (container) for consistent deployment across environments.", category: .engineering)],
        "docker": [LookupResult(definition: "A platform for building, shipping, and running applications in lightweight containers that share the host OS kernel.", category: .engineering)],
        "kubernetes": [LookupResult(definition: "An open-source platform for automating the deployment, scaling, and management of containerized applications across clusters of machines.", category: .engineering)],
        "load balancer": [LookupResult(definition: "A system that distributes incoming network traffic across multiple servers to ensure no single server is overwhelmed.", category: .engineering)],
        "monorepo": [LookupResult(definition: "A version control strategy where multiple projects or packages are stored in a single repository, enabling shared tooling and atomic changes.", category: .engineering)],
        "monolith": [LookupResult(definition: "A software architecture where all components (UI, business logic, data access) are built and deployed as a single, tightly coupled unit.", category: .engineering)],
        "serverless": [LookupResult(definition: "A cloud computing model where the provider manages server infrastructure and you only pay for actual compute time used per request.", category: .engineering)],
        "horizontal scaling": [LookupResult(definition: "Adding more machines to a system to handle increased load, distributing work across multiple servers.", category: .engineering)],
        "vertical scaling": [LookupResult(definition: "Increasing the capacity of a single machine (more CPU, RAM, storage) to handle more load.", category: .engineering)],
        "sharding": [LookupResult(definition: "Splitting a database into smaller, independent pieces (shards) distributed across multiple servers to improve performance and scalability.", category: .engineering)],
        "cqrs": [LookupResult(definition: "Command Query Responsibility Segregation — a pattern that separates read operations from write operations, using different models for each.", category: .engineering)],
        "event-driven architecture": [LookupResult(definition: "A software design pattern where the flow is determined by events (user actions, sensor outputs, messages) rather than sequential logic.", category: .engineering)],
        "graphql": [LookupResult(definition: "A query language for APIs that lets clients request exactly the data they need, avoiding over-fetching and under-fetching.", category: .engineering)],
        "rest": [LookupResult(definition: "Representational State Transfer — an architectural style for APIs that uses HTTP methods (GET, POST, PUT, DELETE) to interact with resources.", category: .engineering)],
        "restful api": [LookupResult(definition: "An API that follows REST principles, using standard HTTP methods and status codes to perform operations on resources identified by URLs.", category: .engineering)],
        "grpc": [LookupResult(definition: "A high-performance RPC framework by Google that uses Protocol Buffers for serialization, commonly used for microservice communication.", category: .engineering)],
        "websocket": [LookupResult(definition: "A protocol that enables persistent, two-way communication between a client and server over a single connection, used for real-time features like chat.", category: .engineering)],

        // DevOps & Deployment
        "infrastructure as code": [LookupResult(definition: "Managing and provisioning computing infrastructure through machine-readable configuration files rather than manual processes.", category: .engineering)],
        "iac": [LookupResult(definition: "Infrastructure as Code — managing servers, networks, and other infrastructure through version-controlled configuration files instead of manual setup.", category: .engineering)],
        "blue-green deployment": [LookupResult(definition: "A deployment strategy using two identical environments (blue and green), routing traffic to the new version only after it's verified.", category: .engineering)],
        "canary testing": [LookupResult(definition: "Releasing a new feature to a small subset of users first to detect issues before rolling it out to everyone.", category: .engineering)],
        "feature flags": [LookupResult(definition: "Configuration toggles that let you enable or disable features without redeploying code, useful for gradual rollouts and A/B testing.", category: .engineering)],
        "hotfix": [LookupResult(definition: "An urgent, targeted code fix applied directly to production to resolve a critical bug, bypassing the normal release cycle.", category: .engineering)],
        "technical debt": [LookupResult(definition: "The accumulated cost of shortcuts and quick fixes in code that will need to be addressed later, slowing future development.", category: .engineering)],
        "code review": [LookupResult(definition: "The process of having other developers examine your code changes before merging, catching bugs and ensuring quality.", category: .engineering)],
        "code smell": [LookupResult(definition: "A surface-level indicator in code that suggests a deeper design problem — not a bug, but a sign that refactoring may be needed.", category: .engineering)],

        // Security
        "ddos": [LookupResult(definition: "Distributed Denial of Service — an attack that overwhelms a server with traffic from many sources, making it unavailable to legitimate users.", category: .engineering)],
        "csrf": [LookupResult(definition: "Cross-Site Request Forgery — an attack that tricks a user's browser into making unwanted requests to a site where they're authenticated.", category: .engineering)],
        "xss": [LookupResult(definition: "Cross-Site Scripting — a vulnerability where attackers inject malicious scripts into web pages viewed by other users.", category: .engineering)],
        "sql injection": [LookupResult(definition: "A code injection attack where malicious SQL statements are inserted into input fields to manipulate or access the database.", category: .engineering)],
        "zero trust": [LookupResult(definition: "A security model that requires verification for every person and device trying to access resources, regardless of whether they're inside the network.", category: .engineering)],
        "phishing": [LookupResult(definition: "A social engineering attack using deceptive emails or messages to trick people into revealing sensitive information like passwords or credit card numbers.", category: .engineering)],
        "firewall": [LookupResult(definition: "A network security system that monitors and controls incoming and outgoing traffic based on predetermined security rules.", category: .engineering)],
        "encryption": [LookupResult(definition: "The process of converting readable data (plaintext) into an unreadable format (ciphertext) to protect it from unauthorized access.", category: .engineering)],
        "penetration testing": [LookupResult(definition: "Authorized simulated cyberattacks on a system to identify security vulnerabilities before malicious hackers can exploit them.", category: .engineering)],

        // Data & Databases
        "nosql": [LookupResult(definition: "A category of databases that don't use traditional table-based relational structures — includes document, key-value, graph, and column stores.", category: .engineering)],
        "postgresql": [LookupResult(definition: "An advanced open-source relational database known for reliability, feature richness, and standards compliance.", category: .engineering)],
        "etl": [LookupResult(definition: "Extract, Transform, Load — a process for collecting data from various sources, transforming it into a usable format, and loading it into a data warehouse.", category: .engineering)],
        "data lake": [LookupResult(definition: "A centralized repository that stores vast amounts of raw data in its native format until it's needed for analysis.", category: .engineering)],
        "data warehouse": [LookupResult(definition: "A system designed for storing and analyzing large volumes of structured, historical data to support business intelligence and reporting.", category: .engineering)],
        "orm": [LookupResult(definition: "Object-Relational Mapping — a technique that lets you query and manipulate database data using an object-oriented programming language instead of raw SQL.", category: .engineering)],
        "normalization": [LookupResult(definition: "The process of organizing a database to reduce data redundancy and improve data integrity by splitting data into related tables.", category: .engineering)],
        "database indexing": [LookupResult(definition: "Creating a data structure that improves the speed of data retrieval operations on a database, similar to a book's index.", category: .engineering)],

        // Frontend & Web
        "dom": [LookupResult(definition: "Document Object Model — a programming interface that represents an HTML page as a tree of objects that can be manipulated with JavaScript.", category: .engineering)],
        "pwa": [LookupResult(definition: "Progressive Web App — a web application that uses modern browser features to deliver an app-like experience, including offline support and push notifications.", category: .engineering)],
        "ssr": [LookupResult(definition: "Server-Side Rendering — generating HTML on the server for each request, improving initial load time and SEO compared to client-side rendering.", category: .engineering)],
        "csr": [LookupResult(definition: "Client-Side Rendering — rendering web pages entirely in the browser using JavaScript, common in single-page applications.", category: .engineering)],
        "responsive design": [LookupResult(definition: "A web design approach where layouts adapt fluidly to different screen sizes and devices using flexible grids and media queries.", category: .engineering)],
        "seo": [LookupResult(definition: "Search Engine Optimization — the practice of improving a website's visibility in search engine results to drive more organic traffic.", category: .business)],
        "cms": [LookupResult(definition: "Content Management System — software that allows non-technical users to create, manage, and modify website content without needing to code.", category: .engineering)],
        "spa": [LookupResult(definition: "Single Page Application — a web app that loads a single HTML page and dynamically updates content without full page reloads.", category: .engineering)],

        // Methodologies & Practices
        "agile": [LookupResult(definition: "A project management methodology emphasizing iterative development, collaboration, flexibility, and continuous delivery of working software.", category: .product)],
        "scrum": [LookupResult(definition: "An agile framework where teams work in short sprints (1-4 weeks), with daily standups, sprint planning, and retrospectives.", category: .product)],
        "kanban": [LookupResult(definition: "A visual workflow management method using boards and cards to track work items through stages (To Do, In Progress, Done).", category: .product)],
        "tdd": [LookupResult(definition: "Test-Driven Development — a practice where you write automated tests before writing the actual code, then write code to make the tests pass.", category: .engineering)],
        "bdd": [LookupResult(definition: "Behaviour-Driven Development — a development approach where features are described in plain language scenarios that serve as both specs and tests.", category: .engineering)],
        "dry": [LookupResult(definition: "Don't Repeat Yourself — a principle that every piece of knowledge should have a single, unambiguous representation in a codebase.", category: .engineering)],
        "solid": [LookupResult(definition: "Five design principles (Single responsibility, Open-closed, Liskov substitution, Interface segregation, Dependency inversion) for maintainable object-oriented code.", category: .engineering)],
        "design patterns": [LookupResult(definition: "Reusable solutions to commonly occurring problems in software design — like Singleton, Observer, Factory, and Strategy patterns.", category: .engineering)],
        "gitops": [LookupResult(definition: "An operational framework where Git repositories are the single source of truth for infrastructure and application deployment.", category: .engineering)],
        "devsecops": [LookupResult(definition: "Integrating security practices into every phase of the DevOps pipeline, making security a shared responsibility from the start.", category: .engineering)],

        // AI & ML
        "machine learning": [LookupResult(definition: "A subset of AI where systems learn patterns from data to make predictions or decisions without being explicitly programmed for each case.", category: .engineering)],
        "deep learning": [LookupResult(definition: "A subset of machine learning using neural networks with many layers to learn complex patterns from large amounts of data.", category: .engineering)],
        "nlp": [LookupResult(definition: "Natural Language Processing — a field of AI focused on enabling computers to understand, interpret, and generate human language.", category: .engineering)],
        "llm": [LookupResult(definition: "Large Language Model — an AI system trained on massive text datasets to understand and generate human-like text (e.g., GPT, Claude).", category: .engineering)],
        "llms": [LookupResult(definition: "Large Language Models — AI systems trained on massive text datasets to understand and generate human-like text (e.g., GPT, Claude).", category: .engineering)],
        "gpt": [LookupResult(definition: "Generative Pre-trained Transformer — a type of large language model architecture developed by OpenAI for generating human-like text.", category: .engineering)],
        "rag": [LookupResult(definition: "Retrieval-Augmented Generation — an AI technique that combines a language model with external knowledge retrieval to provide more accurate, grounded answers.", category: .engineering)],

        // General Dev
        "git": [LookupResult(definition: "A distributed version control system that tracks changes in source code, enabling multiple developers to collaborate on the same codebase.", category: .engineering)],
        "github": [LookupResult(definition: "A cloud platform built on Git for hosting code repositories, code review, project management, and developer collaboration.", category: .engineering)],
        "npm": [LookupResult(definition: "Node Package Manager — the default package manager for Node.js, used to install, share, and manage JavaScript libraries and tools.", category: .engineering)],
        "typescript": [LookupResult(definition: "A superset of JavaScript that adds static type checking, helping catch errors early and making code more maintainable.", category: .engineering)],
        "react": [LookupResult(definition: "A JavaScript library by Meta for building user interfaces using reusable components and a virtual DOM for efficient updates.", category: .engineering)],
        "node.js": [LookupResult(definition: "A JavaScript runtime that lets you run JavaScript on the server side, commonly used for building APIs and real-time applications.", category: .engineering)],
        "next.js": [LookupResult(definition: "A React framework that provides server-side rendering, static site generation, API routes, and other production-ready features out of the box.", category: .engineering)],
        "big o notation": [LookupResult(definition: "A mathematical notation describing how an algorithm's time or space requirements grow as input size increases — used to evaluate efficiency.", category: .engineering)],
        "concurrency": [LookupResult(definition: "Running multiple tasks in overlapping time periods, allowing a system to handle many operations simultaneously.", category: .engineering)],
        "deadlock": [LookupResult(definition: "A situation where two or more processes are stuck waiting for each other to release resources, so none of them can proceed.", category: .engineering)],
        "race condition": [LookupResult(definition: "A bug that occurs when the behavior of software depends on the timing of events, such as two threads accessing shared data simultaneously.", category: .engineering)],
        "idempotent": [LookupResult(definition: "An operation that produces the same result no matter how many times it's performed — important in APIs and distributed systems.", category: .engineering)],
        "idempotence": [LookupResult(definition: "The property of an operation where performing it multiple times has the same effect as performing it once — critical for reliable APIs.", category: .engineering)],
        "polling": [LookupResult(definition: "Repeatedly checking a resource or service at regular intervals to detect changes or updates, as opposed to waiting for push notifications.", category: .engineering)],
        "rate limiting": [LookupResult(definition: "Controlling how many requests a client can make to an API in a given time period, preventing abuse and ensuring fair usage.", category: .engineering)],
        "circuit breaker": [LookupResult(definition: "A design pattern that prevents cascading failures by stopping requests to a failing service and returning a fallback response.", category: .engineering)],
        "n+1 query": [LookupResult(definition: "A performance problem where code makes one query to fetch a list, then N additional queries to fetch related data for each item.", category: .engineering)],
        "dependency injection": [LookupResult(definition: "A design pattern where a component receives its dependencies from external sources rather than creating them internally, improving testability.", category: .engineering)],
        "yaml": [LookupResult(definition: "YAML Ain't Markup Language — a human-readable data format commonly used for configuration files in DevOps and CI/CD pipelines.", category: .engineering)],
        "kafka": [LookupResult(definition: "Apache Kafka — a distributed event streaming platform used for building real-time data pipelines and streaming applications.", category: .engineering)],
        "redis": [LookupResult(definition: "An in-memory data store used as a database, cache, and message broker, known for extremely fast read/write operations.", category: .engineering)],
        "nginx": [LookupResult(definition: "A high-performance web server also used as a reverse proxy, load balancer, and HTTP cache.", category: .engineering)],
        "terraform": [LookupResult(definition: "An infrastructure as code tool that lets you define and provision cloud infrastructure using declarative configuration files.", category: .engineering)],
        "repo": [LookupResult(definition: "Repository — a storage location for code, typically hosted on GitHub or GitLab. Contains the full history of changes, branches, and collaboration.", category: .engineering)],
        "repos": [LookupResult(definition: "Repositories — storage locations for code, typically hosted on GitHub or GitLab. A project usually has one repo containing all its source code.", category: .engineering)],
        "lgtm": [LookupResult(definition: "Looks Good To Me — used in code reviews to approve a pull request.", category: .engineering)],
        "nit": [LookupResult(definition: "Nitpick — a minor, non-blocking comment in a code review. Not a required change, just a suggestion.", category: .engineering)],
        "ship it": [LookupResult(definition: "Approve and deploy — used to signal that code is ready to be merged and released to production.", category: .engineering)],
        "blocker": [LookupResult(definition: "A critical issue that prevents progress on a task, feature, or release until it's resolved.", category: .product)],

        // Business — commonly missed acronyms
        "gtm": [LookupResult(definition: "Go-To-Market — the strategy and plan for launching a product or feature to customers, covering positioning, pricing, channels, and sales approach.", category: .business)],
        "fy": [LookupResult(definition: "Fiscal Year — a 12-month period used for accounting and financial reporting, which may or may not align with the calendar year.", category: .finance)],
        "q1": [LookupResult(definition: "Quarter 1 — the first three months of a company's fiscal year, typically January–March.", category: .finance)],
        "q2": [LookupResult(definition: "Quarter 2 — the second three months of a company's fiscal year, typically April–June.", category: .finance)],
        "q3": [LookupResult(definition: "Quarter 3 — the third three months of a company's fiscal year, typically July–September.", category: .finance)],
        "q4": [LookupResult(definition: "Quarter 4 — the final three months of a company's fiscal year, typically October–December.", category: .finance)],
        "yoy": [LookupResult(definition: "Year-over-Year — a comparison of a metric from one period to the same period in the previous year, showing growth or decline.", category: .finance)],
        "mom": [LookupResult(definition: "Month-over-Month — a comparison of a metric from one month to the previous month.", category: .finance)],
        "qoq": [LookupResult(definition: "Quarter-over-Quarter — a comparison of a metric from one quarter to the previous quarter.", category: .finance)],
        "nps": [LookupResult(definition: "Net Promoter Score — a customer loyalty metric measured by asking 'How likely are you to recommend us?' on a 0-10 scale.", category: .business)],
        "dau": [LookupResult(definition: "Daily Active Users — the number of unique users who engage with a product on a given day.", category: .product)],
        "mau": [LookupResult(definition: "Monthly Active Users — the number of unique users who engage with a product within a 30-day period.", category: .product)],
        "churn": [LookupResult(definition: "The rate at which customers stop using a product or cancel their subscription over a given period.", category: .business)],
        "runway": [LookupResult(definition: "The amount of time a startup can operate before running out of money, calculated from current cash and burn rate.", category: .finance)],
        "burn rate": [LookupResult(definition: "The rate at which a company spends its cash reserves, typically measured monthly. Used to calculate runway.", category: .finance)],
        "series a": [LookupResult(definition: "The first significant round of venture capital funding, typically raised after a startup has proven product-market fit.", category: .finance)],
        "series b": [LookupResult(definition: "A follow-on venture funding round focused on scaling the business — expanding teams, markets, and infrastructure.", category: .finance)],
        "seed": [LookupResult(definition: "The earliest stage of venture funding, used to develop the initial product and validate the business idea.", category: .finance)],
        "term sheet": [LookupResult(definition: "A non-binding document outlining the key terms of an investment deal between a startup and investors.", category: .finance)],
        "due diligence": [LookupResult(definition: "The investigation and analysis of a company before an investment, acquisition, or partnership — reviewing financials, legal, tech, and operations.", category: .business)],
        "moat": [LookupResult(definition: "A competitive advantage that protects a business from competitors — like network effects, brand loyalty, patents, or switching costs.", category: .business)],
        "pmf": [LookupResult(definition: "Product-Market Fit — the stage where a product satisfies a strong market demand, evidenced by organic growth and retention.", category: .product)],
        "north star metric": [LookupResult(definition: "The single most important metric that best captures the core value your product delivers to customers.", category: .product)],
        "ops": [LookupResult(definition: "Operations — the day-to-day activities required to run a business, or a team responsible for those activities.", category: .business)],
        "raci": [LookupResult(definition: "Responsible, Accountable, Consulted, Informed — a matrix used to clarify roles and responsibilities for tasks and decisions.", category: .product)],
        "otp": [LookupResult(definition: "One-Time Password — a temporary code used for authentication, typically sent via SMS or email for verification.", category: .engineering)],
        "cta": [LookupResult(definition: "Call To Action — a prompt that encourages users to take a specific action, like a button saying 'Sign Up', 'Buy Now', or 'Learn More'.", category: .product)],
        "ctr": [LookupResult(definition: "Click-Through Rate — the percentage of people who click a link or button out of the total who saw it.", category: .product)],
        "cpc": [LookupResult(definition: "Cost Per Click — the amount an advertiser pays each time someone clicks on their ad.", category: .business)],
        "cpm": [LookupResult(definition: "Cost Per Mille — the cost per 1,000 ad impressions, used to price display advertising.", category: .business)],
        "csat": [LookupResult(definition: "Customer Satisfaction Score — a metric measuring how satisfied customers are with a product, service, or interaction, typically via survey.", category: .business)],
        "ces": [LookupResult(definition: "Customer Effort Score — a metric measuring how easy it was for a customer to accomplish a task or resolve an issue.", category: .business)],
        "aha moment": [LookupResult(definition: "The point in onboarding when a new user first realizes the value of a product — a key activation metric.", category: .product)],
        "dri": [LookupResult(definition: "Directly Responsible Individual — the single person accountable for a project or decision, commonly used at Apple and tech companies.", category: .business)],
        "roas": [LookupResult(definition: "Return on Ad Spend — a marketing metric measuring revenue generated per dollar spent on advertising.", category: .business)],
        "sem": [LookupResult(definition: "Search Engine Marketing — paid advertising on search engines (like Google Ads) to drive traffic to a website.", category: .business)],
        "sku": [LookupResult(definition: "Stock Keeping Unit — a unique identifier assigned to each product variant for inventory tracking and management.", category: .business)],
        "usp": [LookupResult(definition: "Unique Selling Proposition — the key differentiator that makes a product or service stand out from competitors.", category: .business)],
        "r&d": [LookupResult(definition: "Research and Development — activities aimed at discovering new knowledge and creating new products, processes, or services.", category: .business)],
        "aov": [LookupResult(definition: "Average Order Value — the average amount spent each time a customer places an order.", category: .business)],
        "d2c": [LookupResult(definition: "Direct-to-Consumer — a business model where companies sell directly to customers, bypassing traditional retail channels.", category: .business)],
        "go-live": [LookupResult(definition: "The moment a product, feature, or system is deployed and made available to real users in production.", category: .product)],
        "dogfooding": [LookupResult(definition: "Using your own product internally before releasing it to customers — helps catch bugs and build empathy for users.", category: .product)],
        "scope creep": [LookupResult(definition: "The gradual expansion of a project's requirements beyond the original plan, often leading to delays and budget overruns.", category: .product)],
        "hard launch": [LookupResult(definition: "A full public release of a product or feature with marketing, announcements, and availability to all users.", category: .product)],
        "soft launch": [LookupResult(definition: "A limited release of a product to a small audience to test and gather feedback before a full public launch.", category: .product)],
        "ux writing": [LookupResult(definition: "The practice of crafting the text that appears in user interfaces — buttons, error messages, onboarding flows, and notifications.", category: .product)],
        "a/b testing": [LookupResult(definition: "An experiment comparing two versions of something (a webpage, feature, email) to see which performs better with users.", category: .product)],
        "ab testing": [LookupResult(definition: "An experiment comparing two versions of something (a webpage, feature, email) to see which performs better with users.", category: .product)],
        "north star": [LookupResult(definition: "The single most important metric that best captures the core value your product delivers to customers.", category: .product)],
        "tiger team": [LookupResult(definition: "A small, focused group assembled to solve a specific, urgent problem — typically cross-functional and time-limited.", category: .business)],
        "war room": [LookupResult(definition: "A dedicated space (physical or virtual) where a team gathers to resolve a critical incident or work intensely on a high-priority project.", category: .business)],
        "postmortem": [LookupResult(definition: "A structured review after an incident or project to understand what happened, why, and how to prevent recurrence.", category: .engineering)],
        "rca": [LookupResult(definition: "Root Cause Analysis — a method of investigating the underlying cause of a problem rather than just treating symptoms.", category: .engineering)],
        "sop": [LookupResult(definition: "Standard Operating Procedure — documented step-by-step instructions for completing routine tasks consistently.", category: .business)],
        "tldr": [LookupResult(definition: "Too Long; Didn't Read — a brief summary of a long document or message, giving the key takeaway.", category: .business)],
        "tl;dr": [LookupResult(definition: "Too Long; Didn't Read — a brief summary of a long document or message, giving the key takeaway.", category: .business)],
        "wip": [LookupResult(definition: "Work In Progress — something that's currently being worked on but not yet complete.", category: .product)],
        "eom": [LookupResult(definition: "End of Month — used as a deadline or reporting period marker.", category: .business)],
        "eoq": [LookupResult(definition: "End of Quarter — used as a deadline, often for sales targets or financial reporting.", category: .business)],
        "fyi": [LookupResult(definition: "For Your Information — used to share information that doesn't require a response or action.", category: .business)],
        "asap": [LookupResult(definition: "As Soon As Possible — indicates urgency, meaning the task should be prioritized.", category: .business)],
        "smb": [LookupResult(definition: "Small and Medium-sized Business — companies with limited employees and revenue, typically the target market for B2B SaaS and fintech products.", category: .business)],
        "crm": [LookupResult(definition: "Customer Relationship Management — software (like Salesforce, HubSpot) used to manage interactions with customers and prospects throughout the sales cycle.", category: .business)],
        "crms": [LookupResult(definition: "Customer Relationship Management systems — software platforms (like Salesforce, HubSpot) used to manage customer interactions, sales pipelines, and support.", category: .business)],
        "erp": [LookupResult(definition: "Enterprise Resource Planning — integrated software systems that manage core business processes like finance, HR, supply chain, and inventory.", category: .business)],
        "ipo": [LookupResult(definition: "Initial Public Offering — the first time a company's shares are offered to the public on a stock exchange.", category: .finance)],
        "pnl": [LookupResult(definition: "Profit and Loss — a financial statement summarizing revenues, costs, and expenses during a specific period.", category: .finance)],
        "opex": [LookupResult(definition: "Operating Expenses — the ongoing costs of running a business day-to-day, like salaries, rent, and utilities.", category: .finance)],
        "capex": [LookupResult(definition: "Capital Expenditure — money spent on acquiring or maintaining physical assets like equipment, property, or technology infrastructure.", category: .finance)],
        "ebitda": [LookupResult(definition: "Earnings Before Interest, Taxes, Depreciation, and Amortization — a measure of a company's operating performance.", category: .finance)],
        "mql": [LookupResult(definition: "Marketing Qualified Lead — a prospect who has shown interest through marketing channels and is likely to become a customer.", category: .business)],
        "icp": [LookupResult(definition: "Ideal Customer Profile — a description of the type of company or person that would benefit most from your product.", category: .business)],
        "swot": [LookupResult(definition: "Strengths, Weaknesses, Opportunities, Threats — a strategic planning framework used to evaluate a business or project.", category: .business)],
        "dm": [LookupResult(definition: "Direct Message — a private message sent to a specific person on platforms like Slack, Twitter, or LinkedIn, as opposed to a public channel post.", category: .business)],
        "dms": [LookupResult(definition: "Direct Messages — private messages sent to specific people on platforms like Slack, Twitter, or LinkedIn.", category: .business)],
        "adlc": [LookupResult(definition: "Agentic Development Lifecycle — a software development approach where AI agents autonomously handle tasks across the development lifecycle.", category: .engineering)],
        "pager": [LookupResult(definition: "An alert system (like PagerDuty) that notifies on-call engineers when a production incident occurs, often via phone call or SMS.", category: .engineering)],
        "oncall": [LookupResult(definition: "On-Call — a rotation where engineers are responsible for responding to production incidents and alerts outside regular working hours.", category: .engineering)],
        "on-call": [LookupResult(definition: "On-Call — a rotation where engineers are responsible for responding to production incidents and alerts outside regular working hours.", category: .engineering)],
        "p0": [LookupResult(definition: "Priority Zero — the highest severity level for incidents or bugs. Indicates a critical production outage requiring immediate attention.", category: .engineering)],
        "p1": [LookupResult(definition: "Priority One — a high-severity incident or bug that significantly impacts users but may have a workaround.", category: .engineering)],
        "sre": [LookupResult(definition: "Site Reliability Engineering — a discipline that applies software engineering practices to infrastructure and operations to build reliable systems.", category: .engineering)],
        "toil": [LookupResult(definition: "Manual, repetitive operational work that scales linearly with service size, adds no lasting value, and should be automated.", category: .engineering)],

        // AI & Tooling
        "mcp": [LookupResult(definition: "Model Context Protocol — an open standard by Anthropic that lets AI assistants connect to external tools, data sources, and services through a unified interface.", category: .engineering)],
        "mcp server": [LookupResult(definition: "A service that exposes tools and resources to AI assistants via the Model Context Protocol, allowing them to read files, query databases, or interact with APIs.", category: .engineering)],
        "context window": [LookupResult(definition: "The maximum amount of text (measured in tokens) that an AI model can process in a single conversation. Larger windows allow more context.", category: .engineering)],
        "tokens": [LookupResult(definition: "The basic units of text that AI models process — roughly 4 characters or 3/4 of a word. Used to measure input/output size and pricing.", category: .engineering)],
        "prompt": [LookupResult(definition: "The text input given to an AI model to generate a response. Prompt engineering is the practice of crafting effective prompts.", category: .engineering)],
        "prompt engineering": [LookupResult(definition: "The practice of designing and refining text prompts to get better, more accurate, or more useful responses from AI models.", category: .engineering)],
        "fine-tuning": [LookupResult(definition: "Training a pre-existing AI model on a specific dataset to specialize it for a particular task or domain.", category: .engineering)],
        "embedding": [LookupResult(definition: "A numerical representation of text (or images) as a vector, used to measure semantic similarity between pieces of content.", category: .engineering)],
        "embeddings": [LookupResult(definition: "Numerical vector representations of text used for semantic search, clustering, and finding similar content in AI applications.", category: .engineering)],
        "vector database": [LookupResult(definition: "A database optimized for storing and querying embedding vectors, used for semantic search and retrieval in AI applications (e.g., Pinecone, Weaviate).", category: .engineering)],
        "hallucination": [LookupResult(definition: "When an AI model generates confident-sounding but factually incorrect or fabricated information. A known limitation of large language models.", category: .engineering)],
        "grounding": [LookupResult(definition: "Techniques to connect AI model responses to factual data sources, reducing hallucinations and improving accuracy.", category: .engineering)],
        "agentic": [LookupResult(definition: "AI systems that can autonomously plan, use tools, make decisions, and take actions to accomplish goals — beyond simple question-answering.", category: .engineering)],
        "ai agent": [LookupResult(definition: "An AI system that can autonomously perform multi-step tasks by planning, using tools, and making decisions to achieve a goal.", category: .engineering)],
        "tool use": [LookupResult(definition: "The ability of an AI model to call external functions or APIs during a conversation — like searching the web, running code, or querying a database.", category: .engineering)],
        "system prompt": [LookupResult(definition: "Hidden instructions given to an AI model that define its behavior, persona, and constraints for a conversation.", category: .engineering)],
        "temperature": [LookupResult(definition: "A parameter controlling AI output randomness. Low temperature (0) = deterministic/focused. High temperature (1) = creative/varied.", category: .engineering)],
        "inference": [LookupResult(definition: "The process of running an AI model to generate predictions or responses from input data. Distinct from training.", category: .engineering)],
        "multimodal": [LookupResult(definition: "AI models that can process and generate multiple types of content — text, images, audio, video — not just text.", category: .engineering)],
    ]
}


