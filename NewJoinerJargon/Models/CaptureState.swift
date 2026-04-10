import Foundation
import SwiftUI

@Observable
final class CaptureState {
    var term = ""
    var sourceApp = ""
    var surroundingText = ""
    var sourceURL = ""
    var timestamp = Date()

    func update(from context: HotkeyService.CapturedContext) {
        term = context.selectedText
        sourceApp = context.sourceApp
        surroundingText = context.surroundingText
        sourceURL = context.sourceURL
        timestamp = Date()
    }

    func clear() {
        term = ""
        sourceApp = ""
        surroundingText = ""
        sourceURL = ""
    }
}
