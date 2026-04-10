import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    let glossaryStore = GlossaryStore()
    let settings = SettingsManager()
    let captureState = CaptureState()
    let navigationState = NavigationState()

    private var hotkeyService: HotkeyService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "book.closed.fill", accessibilityDescription: "New Joiner Jargon")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create the popover with the shared observable state
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.delegate = self

        let popoverView = PopoverView()
            .environment(glossaryStore)
            .environment(settings)
            .environment(captureState)
            .environment(navigationState)

        popover.contentViewController = NSHostingController(rootView: popoverView)

        glossaryStore.migrateDisplayTerms()

        // Setup hotkey
        setupHotkey()

        // Check accessibility
        if !AccessibilityService.hasPermission {
            AccessibilityService.requestPermission()
        }
    }

    // Prevent app from quitting when glossary window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func setupHotkey() {
        hotkeyService = HotkeyService { [weak self] context in
            guard let self else { return }

            // Update the shared observable state — SwiftUI will react automatically
            self.captureState.update(from: context)

            // Auto-show the popover
            self.showPopover()
        }
        hotkeyService?.start()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}
