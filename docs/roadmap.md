# Roadmap

Known work, not yet scheduled. Items are removed when done, not marked done.

## Make ExtensionSettingsOpener version-proof

`NewFile/App/ContentView.swift` opens System Settings with a versioned anchor:

```swift
x-apple.systempreferences:com.apple.ExtensionsPreferences?Finder
```

The anchor path changed across macOS releases, and the current fallback array does not
actually work: `NSWorkspace.open` returns `true` whenever System Settings itself can be
launched, regardless of whether the anchor resolves, so the loop always returns after the
first URL and never tries the second.

Worst case today is that System Settings opens on its main page instead of the Finder
Extensions pane — an annoyance, not a failure, and `setup.body` already spells out the path
in text.

Fix by either dropping the version-specific anchor entirely, or by verifying the pane
actually opened before returning. Do not add more URLs to the existing array; that pattern
is what does not work.

Deployment target is macOS 13, so any solution has to hold from Ventura onward.

## Verify on macOS 13 / 14 / 15

The 13.0 deployment target has only been compile-verified on the development machine
(macOS 26). No build has ever run on an older system.

There is no macOS simulator — Xcode's Simulator covers iOS and its siblings only, and a
Finder Sync extension needs a real Finder process regardless. Testing requires a VM (UTM
is free on Apple silicon) or older hardware.

Priority order when this happens:

1. Right-click a folder → New File actually creates the file. This is the one that would
   make the app useless if it fails, because the sandbox implementation of
   `temporary-exception.files.absolute-path.read-write` differs across releases.
2. The extension registers and can be enabled in System Settings.
3. Whether the Open Extension Settings button lands on the right pane.
