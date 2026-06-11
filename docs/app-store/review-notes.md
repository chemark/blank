# App Review Notes

NewFile is a macOS productivity utility that adds a Finder Sync Extension named
"NewFile Finder Extension".

## Reviewer Test Steps

1. Launch NewFile.
2. Click "Open Extension Settings".
3. Enable "NewFile Finder Extension" in System Settings → Privacy & Security → Extensions.
4. In Finder, right-click any folder or the background of a folder window.
5. Choose "New File" from the context menu.
6. An empty file named "Untitled" (no extension) appears in the folder.
7. Rename the file with any extension, such as "note.md" or "data.json".

If the Finder menu does not appear immediately after enabling the extension,
click "Relaunch Finder" in the app.

## Entitlement Justification

The Finder Sync Extension requests:

```
com.apple.security.temporary-exception.files.absolute-path.read-write = ["/"]
```

**Reason:** The extension must create an empty file in whichever directory the
user right-clicks in Finder. That directory is determined at runtime by
`FIFinderSyncController.targetedURL()` and cannot be known in advance. The
App Sandbox's `user-selected.read-write` entitlement only covers paths opened
via NSOpenPanel, which does not apply here. A broad path exception is the only
way a Finder Sync Extension can write to user-chosen directories from within
the sandbox.

## Privacy

The app does not use networking, analytics, privileged helpers, background
daemons, file indexing, or private APIs. The extension only creates a single
empty file at the path chosen by the user via the Finder context menu.
