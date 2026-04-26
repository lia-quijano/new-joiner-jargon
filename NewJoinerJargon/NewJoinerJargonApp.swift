import SwiftUI

@main
struct NewJoinerJargonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(appDelegate.settings)
        }
    }
}
