import SwiftUI

@main
struct NewFileApp: App {
    var body: some Scene {
        Window("NewFile", id: "main") {
            ContentView()
                .frame(minWidth: 520, minHeight: 360)
        }
        .windowResizability(.contentMinSize)
    }
}
