# NewFile

NewFile is a native macOS 26+ utility that adds a Finder Sync Extension for
creating common empty files from Finder's right-click menu.

## Features

- Finder contextual menu group: `New File`
- Creates an empty `Untitled` file that the user can rename with any extension
- Conflict-safe names such as `Untitled`, `Untitled 2`, and `Untitled 3`
- Reveals and selects the created file in Finder
- App Sandbox and App Group entitlements for Mac App Store distribution

## Development

Generate the Xcode project:

```sh
tuist generate --no-open --cache-profile none
```

Build and launch:

```sh
./script/build_and_run.sh --verify
```

Run tests:

```sh
xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test
```

## App Store Notes

Set a real Apple Developer Team ID before archiving for upload. Review notes and
privacy copy live in `docs/app-store/`.
