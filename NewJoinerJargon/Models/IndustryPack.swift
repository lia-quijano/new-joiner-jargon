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
            SeedTerm("LGTM", "Looks Good To Me. Shorthand approval used in code reviews.", .engineering),
            SeedTerm("Tech debt", "The accumulated cost of quick fixes and shortcuts taken during development that will need to be properly addressed later.", .engineering),
            SeedTerm("Standup", "A short daily team sync (usually 15 minutes) where each person covers what they did yesterday, what they're doing today, and any blockers.", .engineering),
            SeedTerm("Deploy", "The process of releasing a new version of software to a live environment where users can access it.", .engineering),
            SeedTerm("On-call", "A rotation where engineers are responsible for responding to production incidents, including outside of working hours.", .engineering),
            SeedTerm("Sprint", "A fixed period of work (usually 1–2 weeks) during which a team commits to completing a defined set of tasks.", .engineering),
            SeedTerm("CI/CD", "Continuous Integration / Continuous Deployment. A practice where code changes are automatically tested and released to production with minimal manual steps.", .engineering),
            SeedTerm("Refactor", "Rewriting existing code to improve its structure, readability, or performance without changing what it actually does.", .engineering),
            SeedTerm("Regression", "A bug introduced by a recent change that breaks something that was previously working.", .engineering),
            SeedTerm("Hotfix", "An urgent, targeted fix deployed directly to production to address a critical bug — bypassing the normal release cycle.", .engineering),
            SeedTerm("Merge conflict", "When two branches of code contain competing changes to the same file that Git can't automatically reconcile.", .engineering),
            SeedTerm("Code review", "The process of teammates reading and providing feedback on a proposed code change before it's merged.", .engineering),
            SeedTerm("Repo", "Repository. The version-controlled folder that holds all the source code and history for a project.", .engineering),
            SeedTerm("Branch", "An isolated copy of the codebase where changes can be made without affecting the main version until they're ready to merge.", .engineering),
            SeedTerm("Staging", "A test environment that mirrors production as closely as possible, used to verify changes before they go live.", .engineering),
            SeedTerm("Prod", "Production. The live environment that real users interact with.", .engineering),
            SeedTerm("Pair programming", "Two engineers working together at the same machine — one writes code while the other reviews in real time.", .engineering),
            SeedTerm("Retrospective", "A regular team meeting (usually end of sprint) to reflect on what went well, what didn't, and what to improve.", .engineering),
            SeedTerm("Velocity", "A measure of how much work a team completes in a sprint, used to forecast future capacity.", .engineering),
            SeedTerm("Backlog", "A prioritised list of all the work — features, bugs, tasks — that hasn't been started yet.", .engineering),
            SeedTerm("Story points", "A relative unit used to estimate the effort or complexity of a task, not tied to time.", .engineering),
            SeedTerm("Feature flag", "A toggle that lets engineers turn a feature on or off without deploying new code — useful for gradual rollouts or A/B testing.", .engineering),
            SeedTerm("API", "Application Programming Interface. A defined contract that lets two systems communicate and share data with each other.", .engineering),
            SeedTerm("Unit test", "An automated test that verifies a single, isolated piece of code behaves as expected.", .engineering),
            SeedTerm("Incident", "An unplanned disruption to a service — ranging from a minor bug to a full outage — that requires a coordinated response.", .engineering),
            SeedTerm("Postmortem", "A document written after an incident that explains what happened, why, and what steps will prevent it happening again. Blameless by design.", .engineering),
            SeedTerm("Legacy code", "Older code that is still in use but difficult to change — often underdocumented and written before current standards.", .engineering),
            SeedTerm("Microservices", "An architecture where an application is split into small, independently deployable services that each handle a specific function.", .engineering),
            SeedTerm("Scrum", "A structured agile framework for managing work in sprints, with defined roles (like Scrum Master and Product Owner) and ceremonies.", .engineering),
            SeedTerm("Rubber duck debugging", "The practice of explaining your code out loud — to a person or even a rubber duck — to help identify where logic breaks down.", .engineering),
            SeedTerm("Dogfooding", "When a team uses its own product internally before releasing it to customers, to catch issues firsthand.", .engineering),
            SeedTerm("Greenfield", "A project built from scratch with no legacy constraints — as opposed to inheriting an existing codebase.", .engineering),
            SeedTerm("Linter", "A tool that automatically checks code for style issues, common errors, and deviations from team conventions.", .engineering),
            SeedTerm("Dependency", "An external library or package that your code relies on to function.", .engineering),
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
            SeedTerm("EBITDA", "Earnings Before Interest, Taxes, Depreciation and Amortisation. A measure of core operational profitability, stripping out financing and accounting decisions.", .finance),
            SeedTerm("CAC", "Customer Acquisition Cost. The average amount spent to acquire a single new customer, including sales and marketing costs.", .finance),
            SeedTerm("LTV", "Lifetime Value. The total revenue a business expects to earn from a customer over the entire relationship.", .finance),
            SeedTerm("Gross margin", "Revenue minus the direct cost of delivering a product or service, expressed as a percentage. A key indicator of unit-level profitability.", .finance),
            SeedTerm("NRR", "Net Revenue Retention. Measures revenue from existing customers over time, accounting for upgrades, downgrades, and churn. Above 100% means expansion outweighs loss.", .finance),
            SeedTerm("P&L", "Profit and Loss statement. A financial report showing revenue, costs, and profit over a given period — sometimes called the income statement.", .finance),
            SeedTerm("OpEx", "Operating Expenditure. The day-to-day costs of running the business — salaries, rent, software subscriptions.", .finance),
            SeedTerm("CapEx", "Capital Expenditure. Spending on long-term assets like equipment, infrastructure, or property.", .finance),
            SeedTerm("COGS", "Cost of Goods Sold. The direct costs of producing or delivering a product or service, used to calculate gross margin.", .finance),
            SeedTerm("ROI", "Return on Investment. A measure of the financial return generated relative to the cost of an investment.", .finance),
            SeedTerm("Valuation", "The estimated total worth of a company, typically established during fundraising rounds or acquisitions.", .finance),
            SeedTerm("Cap table", "Capitalisation table. A record of who owns what percentage of a company — including founders, investors, and employees with options.", .finance),
            SeedTerm("Equity", "Ownership stake in a company. As a shareholder, you're entitled to a proportion of the company's value and profits.", .finance),
            SeedTerm("Vesting", "The process by which employees gradually earn the right to their equity over time, typically over a 4-year schedule.", .finance),
            SeedTerm("Cliff", "The minimum time you must stay at a company before any equity vests. Typically 12 months — leave before then and you get nothing.", .finance),
            SeedTerm("Stock options", "The right to buy shares in the company at a fixed price (the strike price) in the future, typically lower than market value.", .finance),
            SeedTerm("Dilution", "When new shares are issued, existing shareholders own a smaller percentage of the company. Your stake gets diluted.", .finance),
            SeedTerm("GMV", "Gross Merchandise Value. The total value of transactions processed through a platform — does not equal revenue, which is usually a cut of this.", .finance),
            SeedTerm("Take rate", "The percentage of GMV a platform keeps as its own revenue. Also called the 'rake'.", .finance),
            SeedTerm("Unit economics", "The revenue and costs directly tied to a single customer or transaction — used to assess whether the core business model is sustainable.", .finance),
            SeedTerm("Payback period", "How long it takes to recoup the cost of acquiring a customer through the revenue they generate.", .finance),
            SeedTerm("Break-even", "The point at which total revenue equals total costs — neither profit nor loss.", .finance),
            SeedTerm("Working capital", "The difference between current assets and current liabilities — a measure of short-term financial health.", .finance),
            SeedTerm("Cash flow", "The movement of money in and out of a business. Positive cash flow means more is coming in than going out.", .finance),
            SeedTerm("Forecast", "A projection of future financial performance based on current trends, targets, and assumptions.", .finance),
            SeedTerm("Headcount plan", "A budget and projection for how many people the company expects to hire, by team and timeframe.", .finance),
            SeedTerm("Term sheet", "A non-binding document outlining the key terms of an investment deal, before full legal agreements are drafted.", .finance),
            SeedTerm("Bridge round", "A small, interim funding round to extend runway while the company prepares for a larger raise.", .finance),
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
            SeedTerm("CPL", "Cost Per Lead. How much is spent on average to generate a single new lead.", .business),
            SeedTerm("CPC", "Cost Per Click. The amount paid each time someone clicks on an ad.", .business),
            SeedTerm("CPM", "Cost Per Mille. The cost of 1,000 ad impressions — a standard way to price display and social advertising.", .business),
            SeedTerm("ROAS", "Return on Ad Spend. Revenue generated for every pound or dollar spent on advertising.", .business),
            SeedTerm("SEO", "Search Engine Optimisation. The practice of improving a website's content and structure so it ranks higher in organic search results.", .business),
            SeedTerm("SEM", "Search Engine Marketing. Paid advertising on search engines (like Google Ads) to drive traffic.", .business),
            SeedTerm("Brand awareness", "The extent to which potential customers recognise and recall your brand.", .business),
            SeedTerm("Share of voice", "Your brand's visibility in a market relative to competitors — measured across ads, social, press, or search.", .business),
            SeedTerm("ToFu / MoFu / BoFu", "Top, Middle, and Bottom of Funnel. Describes where a prospect is in the buying journey — from first awareness (ToFu) to ready to buy (BoFu).", .business),
            SeedTerm("SQL", "Sales Qualified Lead. A prospect that the sales team has vetted and believes is genuinely ready to buy.", .business),
            SeedTerm("Bounce rate", "The percentage of website visitors who leave after viewing only one page without taking any action.", .business),
            SeedTerm("Organic traffic", "Visitors who arrive at your site through unpaid channels — search, social shares, word of mouth.", .business),
            SeedTerm("GTM", "Go-to-Market. The strategy and plan for launching a product or entering a market — covering positioning, channels, and target customers.", .business),
            SeedTerm("ICP", "Ideal Customer Profile. A detailed description of the type of company or person most likely to buy and get value from your product.", .business),
            SeedTerm("Persona", "A fictional but research-based profile representing a key type of customer, used to guide messaging and product decisions.", .business),
            SeedTerm("NPS", "Net Promoter Score. A customer loyalty metric based on how likely people are to recommend your product on a scale of 0–10.", .business),
            SeedTerm("Content marketing", "Creating and distributing useful content — articles, videos, guides — to attract and retain an audience rather than advertising directly.", .business),
            SeedTerm("Attribution", "Determining which marketing touchpoint (ad, email, search result) gets credit for a conversion.", .business),
            SeedTerm("Demand generation", "Activities designed to create awareness and interest in a product among potential customers who aren't yet looking to buy.", .business),
            SeedTerm("CTA", "Call to Action. The instruction that prompts a user to do something — 'Sign up', 'Book a demo', 'Download now'.", .business),
            SeedTerm("Landing page", "A standalone web page designed for a specific campaign goal, where visitors 'land' after clicking an ad or link.", .business),
            SeedTerm("PLG", "Product-Led Growth. A go-to-market strategy where the product itself drives acquisition, conversion, and expansion — think free trials and freemium.", .business),
            SeedTerm("Campaign", "A coordinated set of marketing activities with a defined goal, audience, budget, and timeline.", .business),
            SeedTerm("Earned media", "Coverage or mentions your brand receives without paying for it — press features, social shares, word of mouth.", .business),
            SeedTerm("Paid media", "Any marketing exposure you pay for — ads, sponsored content, influencer partnerships.", .business),
            SeedTerm("Lead nurturing", "The process of building a relationship with prospects over time through relevant content and touchpoints until they're ready to buy.", .business),
            SeedTerm("CSAT", "Customer Satisfaction Score. A simple survey metric asking customers how satisfied they were with a specific interaction or product.", .business),
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
            SeedTerm("PRD", "Product Requirements Document. A document describing what a feature should do, why it's being built, and what success looks like.", .product),
            SeedTerm("User story", "A short description of a feature from the user's perspective, usually in the format: 'As a [user], I want to [action] so that [benefit]'.", .product),
            SeedTerm("Epic", "A large body of work that can be broken down into smaller user stories or tasks — typically spanning multiple sprints.", .product),
            SeedTerm("Acceptance criteria", "The specific conditions a feature must meet to be considered done and ready to ship.", .product),
            SeedTerm("Backlog refinement", "A regular session where the team reviews, clarifies, and prioritises upcoming work items before they enter a sprint.", .product),
            SeedTerm("Beta", "An early version of a product or feature released to a limited group of users to gather feedback before a full launch.", .product),
            SeedTerm("GA", "General Availability. The point at which a feature or product is fully released to all users.", .product),
            SeedTerm("Wireframe", "A low-fidelity sketch or diagram showing the layout and structure of a screen — without colour or final design.", .product),
            SeedTerm("Prototype", "An interactive mockup used to simulate and test a product experience before building the real thing.", .product),
            SeedTerm("User research", "Structured methods — interviews, surveys, usability tests — for understanding user needs, behaviours, and pain points.", .product),
            SeedTerm("JTBD", "Jobs to Be Done. A framework for understanding what problem a user is trying to solve, rather than focusing on features alone.", .product),
            SeedTerm("Pain point", "A specific problem or frustration a user experiences that a product is designed to solve.", .product),
            SeedTerm("Edge case", "An unusual scenario or input that falls outside the typical use of a product — often where bugs and unexpected behaviour appear.", .product),
            SeedTerm("Happy path", "The ideal, error-free flow through a product where everything works as expected and the user achieves their goal.", .product),
            SeedTerm("Sunset", "To formally retire a product, feature, or service — stopping development and eventually turning it off.", .product),
            SeedTerm("DAU / MAU", "Daily Active Users / Monthly Active Users. Metrics measuring how many unique users engage with a product in a day or month.", .product),
            SeedTerm("Retention", "The percentage of users who continue using a product over time. High retention means users find ongoing value.", .product),
            SeedTerm("Rollout", "The gradual release of a feature to users — often starting with a small percentage and expanding over time.", .product),
            SeedTerm("Rollback", "Reverting a feature or release to a previous state when something goes wrong after deployment.", .product),
            SeedTerm("Hypothesis", "A testable assumption about user behaviour or product impact that a team designs an experiment around.", .product),
            SeedTerm("Competitive analysis", "A structured review of what competitors are building, how they position themselves, and where gaps exist.", .product),
            SeedTerm("TAM", "Total Addressable Market. The total revenue opportunity available if a product captured 100% of its target market.", .product),
            SeedTerm("Cohort", "A group of users who share a common characteristic — often the date they joined — used to analyse behaviour over time.", .product),
            SeedTerm("Engagement", "A measure of how actively and meaningfully users interact with a product — clicks, sessions, features used.", .product),
            SeedTerm("Friction", "Anything in a product flow that slows users down, creates confusion, or discourages them from completing an action.", .product),
            SeedTerm("Ship", "To release a feature or product to users. 'When are we shipping this?' means when does it go live.", .product),
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
            SeedTerm("360 feedback", "A review process where an employee receives feedback from their manager, peers, and direct reports — giving a fuller picture than top-down review alone.", .people),
            SeedTerm("Performance review", "A formal, periodic evaluation of an employee's work against expectations and goals — typically used to inform pay, promotion, and development decisions.", .people),
            SeedTerm("PIP", "Performance Improvement Plan. A formal process outlining specific areas where an employee must improve, with clear milestones and timelines.", .people),
            SeedTerm("All-hands", "A company-wide meeting — usually held monthly or quarterly — where leadership shares updates, results, and priorities with the whole organisation.", .people),
            SeedTerm("Town hall", "Similar to all-hands, but often with more emphasis on Q&A, allowing employees to ask leadership questions directly.", .people),
            SeedTerm("DEIB", "Diversity, Equity, Inclusion and Belonging. The organisational commitment to ensuring all employees feel welcomed, represented, and valued.", .people),
            SeedTerm("Attrition", "The rate at which employees leave a company, whether voluntarily (resignation) or involuntarily (redundancy, performance). Also called turnover.", .people),
            SeedTerm("Time to hire", "The number of days between opening a role and a candidate accepting an offer — a key metric for recruiting efficiency.", .people),
            SeedTerm("Notice period", "The amount of time an employee must give before leaving a role, or a company must give before ending employment.", .people),
            SeedTerm("Garden leave", "When an employee serves their notice period at home, still on the payroll but not working — typically used to protect sensitive information.", .people),
            SeedTerm("Comp & Ben", "Compensation and Benefits. The total package an employee receives — salary, bonus, equity, pension, health cover, and perks.", .people),
            SeedTerm("Total comp", "Total Compensation. The full value of everything an employee earns — base salary plus bonus, equity, and benefits.", .people),
            SeedTerm("Salary band", "A defined range of pay for a given role or level, used to ensure consistency and fairness in compensation across the company.", .people),
            SeedTerm("PTO", "Paid Time Off. The amount of leave an employee can take while still receiving their salary — covering holiday, sick days, and personal time.", .people),
            SeedTerm("Hybrid working", "A working arrangement where employees split their time between the office and working remotely.", .people),
            SeedTerm("Skip-level", "A meeting between an employee and their manager's manager — used to share feedback and build visibility across levels.", .people),
            SeedTerm("eNPS", "Employee Net Promoter Score. A measure of how likely employees are to recommend the company as a place to work, on a scale of 0–10.", .people),
            SeedTerm("Org chart", "A diagram showing the structure of a company or team — who reports to whom and how functions relate.", .people),
            SeedTerm("IC", "Individual Contributor. An employee who does hands-on work and contributes directly, without managing other people.", .people),
            SeedTerm("Career ladder", "A defined framework outlining the levels, skills, and expectations for progression within a role or function.", .people),
            SeedTerm("Engagement survey", "A periodic survey asking employees how they feel about their work, team, and the company — used to identify what's working and what needs improvement.", .people),
            SeedTerm("Offsite", "A team gathering held away from the usual office — often used for strategy, planning, or team building.", .people),
            SeedTerm("Levelling", "The process of defining and assigning seniority levels to roles, used to standardise expectations and compensation across teams.", .people),
            SeedTerm("Succession planning", "Identifying and developing people within the company who could step into key leadership roles in the future.", .people),
            SeedTerm("Redundancy", "When a role is eliminated — usually due to restructuring, cost-cutting, or a function becoming obsolete. The person is made redundant, not dismissed for cause.", .people),
        ]
    )

    static let legal = IndustryPack(
        id: "legal",
        name: "Legal & Compliance",
        icon: "checkmark.shield",
        color: .green,
        terms: [
            SeedTerm("NDA", "Non-Disclosure Agreement. A legal contract that prevents parties from sharing confidential information with outsiders.", .regulatory),
            SeedTerm("GDPR", "General Data Protection Regulation. EU law governing how companies collect, store, process, and delete personal data.", .regulatory),
            SeedTerm("Due diligence", "A thorough investigation of a company, contract, or investment before a decision is made — covering financials, legal standing, and risk.", .regulatory),
            SeedTerm("SLA", "Service Level Agreement. A contract defining the expected level of service between a provider and a client, including uptime, response times, and remedies.", .regulatory),
            SeedTerm("IP", "Intellectual Property. Creations of the mind — inventions, designs, brand names, written works — protected by copyright, patents, or trademarks.", .regulatory),
            SeedTerm("Indemnity", "A contractual obligation where one party agrees to compensate the other for specific losses or legal claims.", .regulatory),
            SeedTerm("Terms of Service", "The legal agreement between a company and its users governing how a product or service may be used.", .regulatory),
            SeedTerm("Privacy Policy", "A document explaining what personal data a company collects, why, how it's stored, and who it's shared with.", .regulatory),
            SeedTerm("CCPA", "California Consumer Privacy Act. US state law giving California residents rights over their personal data, similar in intent to GDPR.", .regulatory),
            SeedTerm("AML", "Anti-Money Laundering. Laws and procedures designed to prevent criminals from disguising illegally obtained funds as legitimate income.", .regulatory),
            SeedTerm("KYC", "Know Your Customer. The process of verifying a customer's identity before doing business with them — required in financial services.", .regulatory),
            SeedTerm("Data controller", "The entity that decides why and how personal data is processed. Under GDPR, they bear primary responsibility for data compliance.", .regulatory),
            SeedTerm("Data processor", "A third party that processes personal data on behalf of the data controller — like a cloud hosting provider or email platform.", .regulatory),
            SeedTerm("Right to erasure", "Also called 'the right to be forgotten'. Under GDPR, individuals can request that a company delete all personal data held about them.", .regulatory),
            SeedTerm("Force majeure", "A contract clause that excuses a party from performing their obligations due to extraordinary events beyond their control — natural disasters, pandemics, war.", .regulatory),
            SeedTerm("MSA", "Master Service Agreement. A framework contract setting out the general terms between two parties, under which individual projects or services are later agreed.", .regulatory),
            SeedTerm("SOW", "Statement of Work. A document attached to an MSA that defines the specific deliverables, timeline, and cost for a particular piece of work.", .regulatory),
            SeedTerm("SOC 2", "A compliance framework assessing how a company manages customer data security, availability, and confidentiality — widely required by enterprise clients.", .regulatory),
            SeedTerm("Whistleblowing", "The act of reporting illegal, unethical, or unsafe practices within an organisation. Companies are legally required to have a protected reporting process.", .regulatory),
            SeedTerm("Trade secret", "Confidential business information — a formula, process, or strategy — that gives a competitive advantage and is protected without registration.", .regulatory),
            SeedTerm("Trademark", "A registered symbol, name, or phrase that legally distinguishes a company's products or services from others.", .regulatory),
            SeedTerm("Licensing", "A legal agreement granting permission to use intellectual property — software, patents, content — under defined terms.", .regulatory),
            SeedTerm("Liability", "Legal responsibility for causing harm or failing to meet an obligation. Contracts often cap or limit liability between parties.", .regulatory),
            SeedTerm("Warranty", "A promise that something will work as described. In contracts, a warranty is a factual statement the maker guarantees to be true.", .regulatory),
            SeedTerm("Governing law", "The jurisdiction whose laws will apply if a contract is disputed — important in cross-border agreements.", .regulatory),
            SeedTerm("Arbitration", "A private dispute resolution process where an independent arbitrator rules on a disagreement, as an alternative to going to court.", .regulatory),
            SeedTerm("PCI-DSS", "Payment Card Industry Data Security Standard. A set of security requirements for any company that stores, processes, or transmits card payment data.", .regulatory),
            SeedTerm("Consent", "Under data protection law, a freely given, informed agreement from an individual to have their data collected or processed for a specific purpose.", .regulatory),
            SeedTerm("Regulatory sandbox", "A controlled environment where startups can test new products or business models with relaxed regulatory requirements — common in fintech.", .regulatory),
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
