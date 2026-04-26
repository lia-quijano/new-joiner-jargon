import SwiftUI

struct SeedTerm {
    let term: String
    let definition: String
    let category: TermCategory
}

struct IndustryPack: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let terms: [SeedTerm]
}

extension IndustryPack {
    static let all: [IndustryPack] = [engineering, finance, marketing, product, people, legal]

    static let engineering = IndustryPack(
        id: "engineering",
        name: "Engineering",
        icon: "chevron.left.forwardslash.chevron.right",
        color: .purple,
        terms: [
            SeedTerm("PR", "Pull Request. A proposed change to a codebase submitted for review by teammates before being merged into the main branch.", .engineering),
            SeedTerm("LGTM", "Looks Good To Me. Approval shorthand used in code reviews.", .engineering),
            SeedTerm("Tech debt", "The accumulated cost of quick fixes and shortcuts taken during development that will need to be properly addressed later.", .engineering),
            SeedTerm("Standup", "A short daily team sync (usually 15 minutes) where each person covers what they did, what they're doing next, and any blockers.", .engineering),
            SeedTerm("Deploy", "The process of releasing a new version of software to a live environment where users can access it.", .engineering),
            SeedTerm("On-call", "A rotation where engineers are responsible for responding to production incidents, including outside of working hours.", .engineering),
            SeedTerm("Sprint", "A fixed period of work (usually 1–2 weeks) during which a team commits to completing a defined set of tasks.", .engineering),
        ]
    )

    static let finance = IndustryPack(
        id: "finance",
        name: "Finance",
        icon: "chart.line.uptrend.xyaxis",
        color: .indigo,
        terms: [
            SeedTerm("ARR", "Annual Recurring Revenue. The value of subscription revenue normalised to a one-year figure.", .finance),
            SeedTerm("MRR", "Monthly Recurring Revenue. Predictable revenue a company expects each month, typically from subscriptions.", .finance),
            SeedTerm("Runway", "How long a company can continue operating at its current spend rate before running out of cash.", .finance),
            SeedTerm("Burn rate", "The rate at which a company spends its cash reserves, usually measured monthly.", .finance),
            SeedTerm("EBITDA", "Earnings Before Interest, Taxes, Depreciation and Amortisation. A measure of core operational profitability.", .finance),
            SeedTerm("CAC", "Customer Acquisition Cost. The average amount spent to acquire a single new customer.", .finance),
            SeedTerm("LTV", "Lifetime Value. The total revenue a business can expect from a customer over the entire relationship.", .finance),
        ]
    )

    static let marketing = IndustryPack(
        id: "marketing",
        name: "Marketing",
        icon: "megaphone",
        color: .orange,
        terms: [
            SeedTerm("CTR", "Click-Through Rate. The percentage of people who clicked a link or ad out of the total who saw it.", .business),
            SeedTerm("Funnel", "A model describing the stages a potential customer moves through, from first awareness to making a purchase.", .business),
            SeedTerm("MQL", "Marketing Qualified Lead. A prospect deemed likely enough to convert that they're worth passing to the sales team.", .business),
            SeedTerm("Churn", "The rate at which customers stop using a product or cancel a subscription over a given time period.", .business),
            SeedTerm("Conversion", "When a user completes a desired action — signing up, purchasing, or another defined goal.", .business),
            SeedTerm("Impressions", "The number of times a piece of content or ad is displayed, regardless of whether anyone clicked it.", .business),
            SeedTerm("A/B test", "An experiment comparing two versions of something (an email, page, or ad) to determine which performs better.", .business),
        ]
    )

    static let product = IndustryPack(
        id: "product",
        name: "Product",
        icon: "shippingbox",
        color: .pink,
        terms: [
            SeedTerm("OKR", "Objectives and Key Results. A goal-setting framework pairing an ambitious objective with measurable outcomes to track progress.", .product),
            SeedTerm("Roadmap", "A strategic plan outlining what a product team intends to build, and roughly when.", .product),
            SeedTerm("MVP", "Minimum Viable Product. The simplest version of a product that can be shipped to gather real user feedback.", .product),
            SeedTerm("Discovery", "The phase of product work focused on deeply understanding user problems before committing to a solution.", .product),
            SeedTerm("North Star metric", "A single metric a team treats as the primary indicator of whether the product is delivering long-term value.", .product),
            SeedTerm("Stakeholder", "Anyone with an interest in or influence over a product decision — including internal teams, customers, and leadership.", .product),
            SeedTerm("Iteration", "A short build-measure-learn cycle used to progressively improve a product or feature based on feedback.", .product),
        ]
    )

    static let people = IndustryPack(
        id: "people",
        name: "People & HR",
        icon: "person.2",
        color: .teal,
        terms: [
            SeedTerm("1:1", "A regular private meeting between a manager and a direct report, used to discuss work, growth, and blockers.", .people),
            SeedTerm("L&D", "Learning and Development. The function responsible for employee training, skill-building, and professional growth.", .people),
            SeedTerm("HRBP", "HR Business Partner. An HR professional embedded in a specific team or business unit to support people strategy.", .people),
            SeedTerm("Headcount", "The total number of employees in a team, department, or company — often used in planning and budgeting discussions.", .people),
            SeedTerm("Probation", "A trial period at the start of employment (typically 3–6 months) during which performance is formally evaluated.", .people),
            SeedTerm("360 feedback", "A review process where an employee receives feedback from their manager, peers, and direct reports.", .people),
        ]
    )

    static let legal = IndustryPack(
        id: "legal",
        name: "Legal & Compliance",
        icon: "checkmark.shield",
        color: .green,
        terms: [
            SeedTerm("NDA", "Non-Disclosure Agreement. A legal contract that prevents parties from sharing confidential information with outsiders.", .regulatory),
            SeedTerm("GDPR", "General Data Protection Regulation. EU law governing how companies collect, store, and use personal data.", .regulatory),
            SeedTerm("Due diligence", "A thorough review of a company, contract, or investment before a decision is made.", .regulatory),
            SeedTerm("SLA", "Service Level Agreement. A contract defining the expected standard of service between a provider and a client.", .regulatory),
            SeedTerm("IP", "Intellectual Property. Creations of the mind — inventions, designs, brand names — protected by law.", .regulatory),
            SeedTerm("Indemnity", "A contractual obligation where one party agrees to compensate another for specific losses or liabilities.", .regulatory),
        ]
    )
}

extension SeedTerm {
    init(_ term: String, _ definition: String, _ category: TermCategory) {
        self.term = term
        self.definition = definition
        self.category = category
    }
}
