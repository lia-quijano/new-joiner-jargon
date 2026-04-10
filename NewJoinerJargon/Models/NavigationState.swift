import Foundation
import SwiftUI

@Observable
final class NavigationState {
    var selectedTermName: String?

    func navigateTo(term: String) {
        selectedTermName = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clear() {
        selectedTermName = nil
    }
}
