# Blank

A macOS Finder extension that adds one menu item: create an empty file.

Right-click a folder, choose **New File**, and an extension-less file named `Untitled`
appears. Rename it to whatever you need — `note.md`, `data.json`, `script.sh`, anything.
That is the whole app.

Finder can make a new folder from the right-click menu but not a new file. Blank fills
that one gap and does nothing else.

## Install

Download the latest DMG from [Releases](https://github.com/OWNER/REPO/releases/latest),
drag Blank to Applications, then **enable the extension**:

> System Settings → General → Login Items & Extensions → Finder Extensions → turn on **Blank**

The menu item does not appear until the extension is enabled. If it still does not show up,
restart Finder: hold Option, right-click the Finder icon in the Dock, and choose Relaunch.

Requires macOS 13.0 or later. Signed with a Developer ID certificate and notarized by Apple.

## Privacy

No analytics, no background daemon, no file indexing, no content scanning. Blank creates one
empty file in the folder you right-click. It goes online only when you click
**Check for Updates**, which fetches a single static JSON file and nothing else.

## Why it asks for such a broad file permission

The Finder Sync extension ships with this entitlement:

```
com.apple.security.temporary-exception.files.absolute-path.read-write = ["/"]
```

That looks alarming for an app this small, so here is the reasoning in full.

A Finder Sync extension must be sandboxed — `pluginkit` silently refuses to register an
unsandboxed one, with no error message. Inside the sandbox, the extension can only write to
paths the sandbox already permits. The folder it needs to write to is whichever folder you
just right-clicked, which is only known at runtime via `FIFinderSyncController.targetedURL()`.
The usual entitlement for user-chosen paths, `files.user-selected.read-write`, covers only
paths returned from an open panel, and no open panel is involved here.

So the extension needs a blanket path exception, or it cannot do the one thing it exists to do.

Apple rejected exactly this under App Store Review guideline 2.4.5(i), stating the exception
"will not be granted" and that this may prevent approval for the Mac App Store. That is why
Blank is distributed directly from here rather than through the App Store.

The entitlement grants the ability to write anywhere. What the code actually does with it is
in [`NewFile/Shared/FileCreationService.swift`](NewFile/Shared/FileCreationService.swift) and
[`NewFile/FinderExtension/FinderSync.swift`](NewFile/FinderExtension/FinderSync.swift) —
roughly sixty lines total. Read them; that is why this repository is public.

## Build

Requires [Tuist](https://tuist.io).

```sh
tuist generate --no-open --cache-profile none
./script/build_and_run.sh --verify
```

Tests:

```sh
xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug \
  -derivedDataPath .derivedData -skipPackagePluginValidation \
  CODE_SIGNING_ALLOWED=NO test
```

Building a signed, notarized DMG requires a Developer ID certificate and a notarization
keychain profile; see `script/release.sh`.

The repository directory is `blank`, but internal target names, the Xcode project, and bundle
ids keep the original `NewFile` spelling. Renaming them would invalidate the signing setup for
no user-visible benefit.

## License

MIT
