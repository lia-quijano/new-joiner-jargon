import AppKit
import Carbon

@MainActor
final class HotkeyService {
    struct CapturedContext: Sendable {
        let selectedText: String
        let surroundingText: String
        let sourceApp: String
        let sourceAppBundleId: String
        let sourceURL: String
    }

    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let onCapture: @MainActor (CapturedContext) -> Void

    // Store a reference so the C callback can reach us
    private static var current: HotkeyService?

    init(onCapture: @escaping @MainActor (CapturedContext) -> Void) {
        self.onCapture = onCapture
    }

    /// Register ⌃⌥J (Control + Option + J) as a system-wide hotkey
    func start() {
        HotkeyService.current = self

        // Register the hotkey event type
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            DispatchQueue.main.async {
                HotkeyService.current?.handleHotkey()
            }
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandlerRef)

        // ⌃⌥J: Control + Option + J
        // J key = keycode 38
        // Modifiers: controlKey (bit 12) + optionKey (bit 11)
        let modifiers: UInt32 = UInt32(controlKey | optionKey)
        let hotkeyID = EventHotKeyID(signature: OSType(0x4E4A4A00), id: 1) // "NJJ\0"

        RegisterEventHotKey(38, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    private func handleHotkey() {
        let frontApp = NSWorkspace.shared.frontmostApplication
        let rawAppName = frontApp?.localizedName ?? "Unknown"
        let bundleId = frontApp?.bundleIdentifier ?? ""

        guard let capture = AccessibilityService.capture() else { return }

        // Get window title
        var windowTitle = ""
        if let app = frontApp {
            windowTitle = AccessibilityService.getWindowTitle(for: app) ?? ""
        }

        // Build rich source label
        let displaySourceApp = buildSourceLabel(
            appName: rawAppName,
            bundleId: bundleId,
            url: capture.sourceURL,
            windowTitle: windowTitle
        )

        // Use surrounding text if available, otherwise use window title as context
        var contextText = capture.surroundingText
        if contextText.isEmpty {
            contextText = windowTitle
        }

        let context = CapturedContext(
            selectedText: capture.selectedText,
            surroundingText: contextText,
            sourceApp: displaySourceApp,
            sourceAppBundleId: bundleId,
            sourceURL: capture.sourceURL
        )

        onCapture(context)
    }

    /// Build a rich source label from all available info
    /// Examples: "LinkedIn · Dia", "#team_general · Slack", "Sprint Planning · Notion", "Dia"
    private func buildSourceLabel(appName: String, bundleId: String, url: String, windowTitle: String) -> String {
        // 1. Browser with URL — use website name
        if !url.isEmpty, let websiteName = AccessibilityService.websiteName(from: url) {
            return "\(websiteName) · \(appName)"
        }

        // 2. Slack desktop — parse "#channel - Workspace - Slack"
        if bundleId.contains("slack") || appName == "Slack" {
            if let detail = parseSlackWindowTitle(windowTitle) {
                return "\(detail) · Slack"
            }
            return "Slack"
        }

        // 3. Notion desktop — use window title (may be "Page - Workspace" or "Page - Notion")
        if bundleId.contains("notion") || appName == "Notion" {
            if let pageName = parseNotionWindowTitle(windowTitle) {
                return "\(pageName) · Notion"
            }
            // Window title often omits "Notion" suffix — use the full title
            let trimmed = windowTitle.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                return "\(trimmed) · Notion"
            }
            return "Notion"
        }

        // 4. Figma desktop
        if bundleId.contains("figma") || appName == "Figma" {
            if let fileName = parseFigmaWindowTitle(windowTitle) {
                return "\(fileName) · Figma"
            }
            return "Figma"
        }

        // 5. Default — just the app name
        return appName
    }

    /// Parse "team_general - Aurem - Slack" → "#team_general"
    /// or "Jenny - Aurem - Slack" → "Jenny" (DM)
    private func parseSlackWindowTitle(_ title: String) -> String? {
        let parts = title.components(separatedBy: " - ")
        guard parts.count >= 2 else { return nil }
        let channelOrPerson = parts[0].trimmingCharacters(in: .whitespaces)
        guard !channelOrPerson.isEmpty, channelOrPerson != "Slack" else { return nil }

        // If it looks like a channel name (lowercase, has underscores or hyphens)
        if channelOrPerson.lowercased() == channelOrPerson {
            return "#\(channelOrPerson)"
        }
        return channelOrPerson
    }

    /// Parse "Sprint Planning - Notion" → "Sprint Planning"
    private func parseNotionWindowTitle(_ title: String) -> String? {
        let suffixes = [" - Notion", " – Notion"]
        for suffix in suffixes {
            if title.hasSuffix(suffix) {
                let pageName = String(title.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                if !pageName.isEmpty { return pageName }
            }
        }
        return nil
    }

    /// Parse "Design System - Figma" → "Design System"
    private func parseFigmaWindowTitle(_ title: String) -> String? {
        let suffixes = [" - Figma", " – Figma"]
        for suffix in suffixes {
            if title.hasSuffix(suffix) {
                let fileName = String(title.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                if !fileName.isEmpty { return fileName }
            }
        }
        return nil
    }

    func stop() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        HotkeyService.current = nil
    }

    nonisolated deinit {
    }
}
