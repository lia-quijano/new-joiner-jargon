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
    private var glossaryWindow: NSWindow?

    func openGlossaryWindow() {
        if let window = glossaryWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = GlossaryListView()
            .environment(glossaryStore)
            .environment(settings)
            .environment(navigationState)

        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "My Glossary"

        if settings.hasCompletedOnboarding {
            window.setContentSize(NSSize(width: 800, height: 600))
            window.minSize = NSSize(width: 600, height: 500)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        } else {
            let screen = NSScreen.main ?? NSScreen.screens[0]
            let frame = screen.visibleFrame
            let w = (frame.width * 0.6).rounded()
            let h = (frame.height * 0.6).rounded()
            window.setContentSize(NSSize(width: w, height: h))
            window.styleMask = [.titled, .closable]
        }

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        glossaryWindow = window
    }

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

        if !settings.hasCompletedOnboarding {
            openGlossaryWindow()
        }

        // Only auto-prompt returning users — new users go through the onboarding wizard
        if settings.hasCompletedOnboarding && !AccessibilityService.hasPermission {
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
        guard settings.hasCompletedOnboarding else {
            openGlossaryWindow()
            return
        }
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
