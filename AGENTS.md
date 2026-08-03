# Blank Agent Guide

## Project

Blank is a native macOS utility that adds a Finder Sync Extension.

- Product name: `Blank`. Site: `blank.hoshikihao.com`.
- Repo root directory is `blank`. Inside it, target names, scheme, `NewFile.xcodeproj`, the `NewFile/` source directory, and bundle ids keep the old `NewFile` spelling. Do not rename them.
- User-visible product name lives in `CFBundleDisplayName` (app and extension), `PRODUCT_NAME` of the app target, the `Window(...)` title, and `Localizable.strings`.

The intended Finder behavior is:

- Right-click a folder, selected folder, or folder background.
- Show one menu item, localized: `New File` / `新建文件`.
- Create an empty file in that folder, named with the localized base name: `Untitled` / `未命名`.
- If needed, append a number: `Untitled 2` / `未命名 2`, and so on.
- The user renames the file manually to choose any extension, such as `note.md` or `data.json`.

Menu title and file base name both come from `Localizable.strings` in
`NewFile/FinderExtensionResources/<locale>.lproj/`. Keys: `menu.new_file`, `file.untitled_base`.
Add a new locale by adding an `.lproj` directory there; do not hardcode user-visible strings.

Do not bring back the old fixed menu items for `.txt`, `.md`, `.json`, `.csv`, and `.html`.

Finder places all Finder Sync extension menu items in a fixed region at the bottom of the
context menu. There is no API to position the item near `New Folder`. Do not attempt code
injection into Finder.

## Repository Shape

- Tuist project definition: `Project.swift`
- Xcode project/workspace: `NewFile.xcodeproj`, `NewFile.xcworkspace`
- Host app source: `NewFile/App/`
- Finder Sync Extension source: `NewFile/FinderExtension/`
- Shared app/extension logic: `NewFile/Shared/`
- Tests: `NewFile/Tests/`
- Build/run entrypoint: `script/build_and_run.sh`
- Codex run button config: `.codex/environments/environment.toml`
- App Store notes: `docs/app-store/`
- Detailed handoff: `docs/claude-code-handoff.md`

## Development Commands

Regenerate the Xcode project after editing `Project.swift`:

```sh
tuist generate --no-open --cache-profile none
```

Run tests:

```sh
xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test
```

Build, sign, install to `~/Applications/Blank.app`, register the Finder extension, launch, and verify the app:

```sh
./script/build_and_run.sh --verify
```

Important: after running tests with `CODE_SIGNING_ALLOWED=NO`, run `./script/build_and_run.sh --verify` again before Finder-extension testing. Finder must use the signed Debug app/extension installed at `~/Applications/Blank.app`; `.derivedData` registration may appear in `pluginkit` but Finder may not load it.

## Signing And Provisioning

Both Development (Debug) and Distribution (Release) are configured for manual signing.

### Development (Debug)

- Signing identity: `3rd Party Mac Developer Application: hao hoshiki (6SKPUQN55Z)`, no provisioning profile.
- The `Apple Development: hoshikihao@proton.me (ABD492V5HK)` private key is lost. The certificate still shows in the keychain but not in `security find-identity -v -p codesigning`. Do not configure Debug to use it.
- Switch Debug to `Developer ID Application` once that certificate exists.
- Registered Mac device UDID: `00008112-0004095C2E08201E`

### Distribution (Release / Mac App Store)

- Signing identity: `3rd Party Mac Developer Application: hao hoshiki (6SKPUQN55Z)`
- Distribution certificate ASC id: `XR849UQQ74`
- Host provisioning profile: `NewFile Mac App Store`
- Host profile UUID: `89e4b80e-4bdc-4338-a54b-0dfce667d04d`
- Extension provisioning profile: `NewFile Finder Extension Mac App Store`
- Extension profile UUID: `6c5d713b-c8f5-4f96-a6e7-f508a182fc02`

### Common

- Apple TeamIdentifier: `6SKPUQN55Z`
- App bundle id: `com.xingshuhao.NewFile`
- Finder extension bundle id: `com.xingshuhao.NewFile.FinderExtension`

Do not switch back to ad-hoc signing for Finder Sync testing. `pluginkit -a` silently refuses to register an ad-hoc signed extension; the signature must chain to Apple Root CA.

Keep `com.apple.security.app-sandbox` in `NewFile/NewFileFinderExtension.entitlements`. `pluginkit -a` silently refuses to register an unsandboxed Finder Sync extension, regardless of signing identity. Because the extension is sandboxed, it also needs `com.apple.security.temporary-exception.files.absolute-path.read-write` to write into the folder the user right-clicks.

## App Store Connect CLI

`@onmyway133/asc-cli@1.0.6` is installed locally and exposed via:

```sh
npm run asc -- <command>
```

The default asc profile is configured and active:

- Key ID: `H96X8J37ZU`
- Issuer ID: `bc57f3ee-053c-4a19-a1d4-f2ff402adf19`
- Credentials file: `/Users/xingshuhao/.asc/credentials.json`
- Private key is stored in macOS Keychain by asc-cli.
- Original local `.p8` path: `/Users/xingshuhao/Downloads/AuthKey_H96X8J37ZU.p8`

Do not paste or commit `.p8` private key contents.

Useful checks:

```sh
npm run asc -- auth list
npm run asc -- apps list
npm run asc -- signing bundle-ids list --output json
npm run asc -- signing profiles list --output json
```

## Finder Extension Workflow

After a signed build, prefer the project script:

```sh
./script/build_and_run.sh --verify
```

It installs the signed Debug app to `~/Applications/Blank.app`, removes Debug/Release `.derivedData` extension registrations if present, registers the installed extension, and launches the app.

Manual equivalent:

```sh
pluginkit -r /Users/xingshuhao/blank/.derivedData/Build/Products/Debug/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
pluginkit -r /Users/xingshuhao/blank/.derivedData/Build/Products/Release/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
pluginkit -a /Users/xingshuhao/Applications/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
pluginkit -e use -i com.xingshuhao.NewFile.FinderExtension
osascript -e 'tell application "Finder" to quit' -e 'delay 0.5' -e 'tell application "Finder" to activate'
```

Verify registration:

```sh
pluginkit -m -A -D -vvv -p com.apple.FinderSync | rg -i 'NewFile|xingshuhao|FinderExtension'
```

Expected result includes:

```text
com.xingshuhao.NewFile.FinderExtension(1.0)
Path = /Users/xingshuhao/Applications/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
Display Name = Blank
Parent Name = Blank
```

If clicking `New File` does not create a file, inspect logs:

```sh
/usr/bin/log show --last 10m --predicate 'subsystem == "com.xingshuhao.NewFile.finder-extension"' --style compact
```

## Node/npm Environment

Node/npm are managed by mise. Current verified versions:

- Node: `v25.9.0`
- npm: `11.12.1`
- `node` first hit: `/Users/xingshuhao/.local/share/mise/shims/node`
- `npm` first hit: `/Users/xingshuhao/.local/share/mise/shims/npm`

Hermes was previously uninstalled; stale `~/.local/bin/node` and `~/.local/bin/npm` symlinks were removed. `.zshrc` puts mise shims first.

Recheck with:

```sh
zsh -lic 'node -v && npm -v && type -a node npm'
```

Ignore harmless oh-my-zsh cache-write warnings in restricted sandboxes; the important part is the first `node`/`npm` path.

## Current Caveats

- The repository is initialized, but many project files are still untracked. Do not assume a clean committed baseline.
- Finder Sync behavior requires signed builds, installation to `~/Applications/Blank.app`, pluginkit registration, extension enablement, and Finder restart.
- The host app UI no longer manages file-type toggles. `TemplatePreferences` and old fixed-template code may still exist in shared/tests for legacy coverage; do not revive that UX unless explicitly requested.
