import SwiftUI

@main
struct NewFileApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 520, minHeight: 360)
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView()
        }
    }
}
