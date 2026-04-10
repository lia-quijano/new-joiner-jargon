import SwiftUI

enum TermCategory: String, CaseIterable, Codable, Identifiable {
    case business       = "Business"
    case payments       = "Payments"
    case regulatory     = "Regulatory"
    case engineering    = "Engineering"
    case product        = "Product"
    case people         = "People & Culture"
    case finance        = "Finance"
    case uncategorized  = "Uncategorized"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .business:      return "building.2"
        case .payments:      return "creditcard"
        case .regulatory:    return "checkmark.shield"
        case .engineering:   return "chevron.left.forwardslash.chevron.right"
        case .product:       return "shippingbox"
        case .people:        return "person.2"
        case .finance:       return "chart.line.uptrend.xyaxis"
        case .uncategorized: return "tag"
        }
    }

    var color: Color {
        switch self {
        case .business:      return .blue
        case .payments:      return .green
        case .regulatory:    return .orange
        case .engineering:   return .purple
        case .product:       return .pink
        case .people:        return .teal
        case .finance:       return .indigo
        case .uncategorized: return .gray
        }
    }
}
