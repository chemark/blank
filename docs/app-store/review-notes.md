# App Review Notes

NewFile is a macOS productivity utility that adds a Finder Sync Extension named
"NewFile Finder Extension".

Reviewer test steps:

1. Launch NewFile.
2. Click "Open Extension Settings".
3. Enable "NewFile Finder Extension" in System Settings.
4. In Finder, right-click a folder or the background of a folder window.
5. Use the "New File" menu to create an empty file named "Untitled".
6. Rename the file with any extension, such as "note.md" or "data.json".

The app does not use networking, analytics, privileged helpers, background
daemons, file indexing, or private APIs. The extension only creates an empty
"Untitled" file in the Finder location where the user invoked the menu.

If the Finder menu does not appear immediately after enabling the extension,
relaunch Finder from the NewFile app.
