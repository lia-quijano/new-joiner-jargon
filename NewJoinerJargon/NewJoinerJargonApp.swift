import SwiftUI

@main
struct NewJoinerJargonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("My Glossary", id: "glossary") {
            GlossaryListView()
                .environment(appDelegate.glossaryStore)
                .environment(appDelegate.settings)
                .environment(appDelegate.navigationState)
                .frame(minWidth: 500, minHeight: 400)
        }
        .handlesExternalEvents(matching: [])

        Settings {
            SettingsView()
                .environment(appDelegate.settings)
        }
    }
}
