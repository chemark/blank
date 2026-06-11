import SwiftUI
import AppKit

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            Divider()
            enablementPanel
            privacyPanel
            Spacer(minLength: 0)
        }
        .padding(28)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NewFile")
                .font(.largeTitle.weight(.semibold))
            Text("Create a new empty file from Finder's right-click menu, then rename it with any extension you need.")
                .foregroundStyle(.secondary)
        }
    }

    private var enablementPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Enable the Finder extension", systemImage: "puzzlepiece.extension")
                .font(.headline)
            Text("Open System Settings, find Extensions, then enable NewFile Finder Extension. After it is enabled, right-click a folder and choose New File.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Open Extension Settings") {
                    ExtensionSettingsOpener.open()
                }
                Button("Relaunch Finder") {
                    FinderRelauncher.relaunch()
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var privacyPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Privacy", systemImage: "lock.shield")
                .font(.headline)
            Text("NewFile does not use network access, analytics, background daemons, file indexing, or content scanning. It only creates an empty Untitled file in the Finder folder you act on.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }
}

enum ExtensionSettingsOpener {
    static func open() {
        let urls = [
            URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?Finder"),
            URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"),
        ].compactMap { $0 }

        for url in urls where NSWorkspace.shared.open(url) {
            return
        }
    }
}

enum FinderRelauncher {
    static func relaunch() {
        let script = "tell application \"Finder\" to quit\n delay 0.5\n tell application \"Finder\" to activate"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
}
