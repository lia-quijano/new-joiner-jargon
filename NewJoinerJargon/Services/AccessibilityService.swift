import ApplicationServices
import AppKit

enum AccessibilityService {

    struct CaptureResult {
        let selectedText: String
        let surroundingText: String
        let sourceURL: String
    }

    static func capture() -> CaptureResult? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        let bundleId = frontApp.bundleIdentifier ?? ""

        var focusedElement: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        var selectedText = ""
        var surroundingText = ""

        if focusResult == .success, let element = focusedElement {
            let axElement = element as! AXUIElement

            // Get selected text
            var selValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selValue) == .success,
               let text = selValue as? String, !text.isEmpty {
                selectedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Get surrounding text from the full value
            if !selectedText.isEmpty {
                surroundingText = getSurroundingText(from: axElement, selectedText: selectedText)
            }
        }

        // Fallback to clipboard if no selected text
        if selectedText.isEmpty {
            if let clipResult = getSelectedTextViaClipboard() {
                selectedText = clipResult
            }
        }

        guard !selectedText.isEmpty else { return nil }

        // Try to get browser URL
        let sourceURL = getBrowserURL(appElement: appElement, bundleId: bundleId)

        return CaptureResult(
            selectedText: selectedText,
            surroundingText: surroundingText,
            sourceURL: sourceURL
        )
    }

    static func getSelectedText() -> String? {
        capture()?.selectedText
    }

    // MARK: - Surrounding Text

    private static func getSurroundingText(from element: AXUIElement, selectedText: String) -> String {
        // Method 1: Try AXValue (works in native text fields)
        var fullValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &fullValue) == .success,
           let fullText = fullValue as? String, !fullText.isEmpty {
            return extractSentence(from: fullText, around: selectedText)
        }

        // Method 2: Try selecting more text using AXSelectedTextRange
        // Get the selected range, expand it, read the expanded text
        var rangeValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeValue) == .success {
            var range = CFRange()
            if AXValueGetValue(rangeValue as! AXValue, .cfRange, &range) {
                // Try to read text around the selection (100 chars before and after)
                let expandedStart = max(0, range.location - 100)
                let expandedLength = range.length + 200

                var expandedRange = CFRange(location: expandedStart, length: expandedLength)
                if let expandedRangeValue = AXValueCreate(.cfRange, &expandedRange) {
                    var paramText: CFTypeRef?
                    if AXUIElementCopyParameterizedAttributeValue(
                        element,
                        kAXStringForRangeParameterizedAttribute as CFString,
                        expandedRangeValue,
                        &paramText
                    ) == .success, let text = paramText as? String {
                        return extractSentence(from: text, around: selectedText)
                    }
                }
            }
        }

        return ""
    }

    private static func extractSentence(from fullText: String, around selection: String) -> String {
        guard let range = fullText.range(of: selection) else { return "" }

        let beforeSelection = fullText[fullText.startIndex..<range.lowerBound]
        let afterSelection = fullText[range.upperBound...]

        // Find sentence boundaries
        let breakChars: [Character] = [".", "!", "?", "\n", "\r"]

        let sentenceStart: String.Index
        if let lastBreak = beforeSelection.lastIndex(where: { breakChars.contains($0) }) {
            sentenceStart = fullText.index(after: lastBreak)
        } else {
            sentenceStart = fullText.startIndex
        }

        let sentenceEnd: String.Index
        if let nextBreak = afterSelection.firstIndex(where: { breakChars.contains($0) }) {
            sentenceEnd = fullText.index(after: nextBreak)
        } else {
            sentenceEnd = fullText.endIndex
        }

        var sentence = String(fullText[sentenceStart..<sentenceEnd])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if sentence.count > 300 {
            sentence = String(sentence.prefix(300)) + "..."
        }

        // Don't return if it's the same as the selected text
        if sentence == selection { return "" }

        return sentence
    }

    // MARK: - Browser URL

    private static func getBrowserURL(appElement: AXUIElement, bundleId: String) -> String {
        let browserBundles = [
            "com.google.Chrome",
            "com.apple.Safari",
            "company.thebrowser.Browser",  // Arc
            "company.thebrowser.dia",      // Dia
            "org.mozilla.firefox",
            "com.brave.Browser",
            "com.microsoft.edgemac",
        ]

        let lowerBundle = bundleId.lowercased()
        let isBrowser = browserBundles.contains(where: { bundleId == $0 })
            || lowerBundle.contains("browser")
            || lowerBundle.contains("thebrowser")

        guard isBrowser else { return "" }

        // Strategy 1: AppleScript — most reliable for active tab URL
        if let url = getURLViaAppleScript(bundleId: bundleId) {
            return url
        }

        // Strategy 2: toolbar/address bar via accessibility (fallback)
        if let url = getAddressBarURL(appElement: appElement) {
            return url
        }

        return ""
    }

    /// Use AppleScript to get the current tab URL — most reliable for Chromium-based browsers
    private static func getURLViaAppleScript(bundleId: String) -> String? {
        // Try multiple AppleScript approaches in order of reliability
        let scripts: [String]

        if bundleId == "company.thebrowser.dia" {
            scripts = [
                "tell application \"Dia\" to get URL of active tab of front window",
                "tell application id \"company.thebrowser.dia\" to get URL of active tab of front window",
            ]
        } else if bundleId == "company.thebrowser.Browser" {
            scripts = [
                "tell application \"Arc\" to get URL of active tab of front window",
            ]
        } else if bundleId.contains("Chrome") {
            scripts = [
                "tell application \"Google Chrome\" to get URL of active tab of front window",
            ]
        } else if bundleId.contains("brave") {
            scripts = [
                "tell application \"Brave Browser\" to get URL of active tab of front window",
            ]
        } else if bundleId.contains("edgemac") {
            scripts = [
                "tell application \"Microsoft Edge\" to get URL of active tab of front window",
            ]
        } else if bundleId.contains("Safari") {
            scripts = [
                "tell application \"Safari\" to get URL of front document",
            ]
        } else {
            return nil
        }

        for script in scripts {
            guard let appleScript = NSAppleScript(source: script) else { continue }
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            if error == nil, let url = result.stringValue, !url.isEmpty {
                return url
            }
        }

        return nil
    }

    /// Find the URL specifically from the browser's address bar (toolbar),
    /// avoiding picking up random URLs from page content.
    private static func getAddressBarURL(appElement: AXUIElement) -> String? {
        // Get the focused window
        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue) == .success else {
            return nil
        }
        let window = windowValue as! AXUIElement

        // Find toolbar elements in the window
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXChildrenAttribute as CFString, &children) == .success,
              let windowChildren = children as? [AXUIElement] else {
            return nil
        }

        // Search for AXToolbar first — address bars live there
        for child in windowChildren {
            var role: CFTypeRef?
            if AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &role) == .success,
               let roleStr = role as? String, roleStr == "AXToolbar" {
                if let url = findURLInElement(child, depth: 0, maxDepth: 6) {
                    return url
                }
            }
        }

        // Fallback: search AXGroup elements at the top level (some browsers use groups instead)
        for child in windowChildren {
            var role: CFTypeRef?
            if AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &role) == .success,
               let roleStr = role as? String, roleStr == "AXGroup" {
                if let url = findURLInElement(child, depth: 0, maxDepth: 4) {
                    return url
                }
            }
        }

        return nil
    }

    /// Extract a friendly website name from a URL (e.g. "linkedin.com" → "LinkedIn")
    static func websiteName(from url: String) -> String? {
        guard let parsed = URL(string: url), let host = parsed.host else { return nil }

        // Remove www. prefix
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host

        // Map common domains to friendly names
        let knownSites: [String: String] = [
            "linkedin.com": "LinkedIn",
            "twitter.com": "Twitter",
            "x.com": "X (Twitter)",
            "github.com": "GitHub",
            "stackoverflow.com": "Stack Overflow",
            "medium.com": "Medium",
            "notion.so": "Notion",
            "slack.com": "Slack",
            "app.slack.com": "Slack",
            "figma.com": "Figma",
            "docs.google.com": "Google Docs",
            "drive.google.com": "Google Drive",
            "mail.google.com": "Gmail",
            "youtube.com": "YouTube",
            "reddit.com": "Reddit",
            "atlassian.net": "Atlassian",
            "jira.atlassian.com": "Jira",
            "confluence.atlassian.com": "Confluence",
            "trello.com": "Trello",
            "producthunt.com": "Product Hunt",
            "hackernews.com": "Hacker News",
            "news.ycombinator.com": "Hacker News",
        ]

        // Check exact matches first
        if let name = knownSites[domain] { return name }

        // Check if domain ends with a known site
        for (key, name) in knownSites {
            if domain.hasSuffix(key) { return name }
        }

        // Fallback: capitalize the domain name without TLD
        let parts = domain.split(separator: ".")
        if let siteName = parts.first, parts.count >= 2 {
            return siteName.prefix(1).uppercased() + siteName.dropFirst()
        }

        return domain
    }

    /// Try to extract page title from the browser window
    static func getWindowTitle(for app: NSRunningApplication) -> String? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue) == .success else {
            return nil
        }

        var titleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(windowValue as! AXUIElement, kAXTitleAttribute as CFString, &titleValue) == .success,
              let title = titleValue as? String, !title.isEmpty else {
            return nil
        }

        return title
    }

    private static func findURLInElement(_ element: AXUIElement, depth: Int, maxDepth: Int) -> String? {
        guard depth < maxDepth else { return nil }

        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success,
           let stringValue = value as? String,
           looksLikeURL(stringValue) {

            var role: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
               let roleString = role as? String,
               roleString == "AXTextField" || roleString == "AXComboBox" || roleString == "AXStaticText" {
                // Add https:// if missing
                if !stringValue.hasPrefix("http") {
                    return "https://\(stringValue)"
                }
                return stringValue
            }
        }

        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success,
              let childArray = children as? [AXUIElement] else { return nil }

        for child in childArray {
            if let url = findURLInElement(child, depth: depth + 1, maxDepth: maxDepth) {
                return url
            }
        }

        return nil
    }

    private static func looksLikeURL(_ string: String) -> Bool {
        let s = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("http://") || s.hasPrefix("https://") { return true }
        // Looks like a domain
        let domainPattern = #"^[a-zA-Z0-9][\w.-]+\.[a-zA-Z]{2,}"#
        return s.range(of: domainPattern, options: .regularExpression) != nil
    }

    // MARK: - Clipboard Fallback

    private static func getSelectedTextViaClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cmdDown?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cmdUp?.flags = .maskCommand

        cmdDown?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        usleep(100_000)

        let copiedText = pasteboard.string(forType: .string)

        if let previous = previousContents {
            pasteboard.clearContents()
            pasteboard.setString(previous, forType: .string)
        }

        if let text = copiedText, text != previousContents, !text.isEmpty {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    // MARK: - Permissions

    static var hasPermission: Bool {
        AXIsProcessTrusted()
    }

    @MainActor
    static func requestPermission() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
