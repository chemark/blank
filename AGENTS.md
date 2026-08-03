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

Build, sign, install to `/Applications/Blank.app`, register the Finder extension, launch, and verify the app:

```sh
./script/build_and_run.sh --verify
```

Important: after running tests with `CODE_SIGNING_ALLOWED=NO`, run `./script/build_and_run.sh --verify` again before Finder-extension testing. Finder must use the signed Debug app/extension installed at `/Applications/Blank.app`; `.derivedData` registration may appear in `pluginkit` but Finder may not load it.

## Signing And Provisioning

Debug and Release both sign manually with `Developer ID Application: hao hoshiki (6SKPUQN55Z)`,
no provisioning profile, hardened runtime enabled. One `signingSettings` dictionary in
`Project.swift` covers both configurations and both targets.

- Apple TeamIdentifier: `6SKPUQN55Z`
- App bundle id: `com.xingshuhao.NewFile`
- Finder extension bundle id: `com.xingshuhao.NewFile.FinderExtension`

Do not configure any target to use `Apple Development: hoshikihao@proton.me (ABD492V5HK)`.
Its private key is lost.

Mac App Store distribution is abandoned. Do not restore the `3rd Party Mac Developer Application`
identity or the Mac App Store provisioning profiles.

Do not switch back to ad-hoc signing for Finder Sync testing. `pluginkit -a` silently refuses to register an ad-hoc signed extension; the signature must chain to Apple Root CA.

Keep `ENABLE_HARDENED_RUNTIME` on. Notarization requires it, and it is verified to coexist with
the sandbox and the absolute-path temporary exception.

Keep `com.apple.security.app-sandbox` in `NewFile/NewFileFinderExtension.entitlements`. `pluginkit -a` silently refuses to register an unsandboxed Finder Sync extension, regardless of signing identity. Because the extension is sandboxed, it also needs `com.apple.security.temporary-exception.files.absolute-path.read-write` to write into the folder the user right-clicks. Apple rejected that entitlement for the Mac App Store under guideline 2.4.5(i); it is fine for Developer ID distribution.

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

It unregisters every currently registered extension with the same bundle id, replaces
`/Applications/Blank.app` with the signed Debug build, registers that one extension, and launches
the app. Keep exactly one registration: when several are registered, Finder picks one
non-deterministically and may run a stale build.

Manual equivalent:

```sh
pluginkit -r /Users/xingshuhao/blank/.derivedData/Build/Products/Debug/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
pluginkit -r /Users/xingshuhao/blank/.derivedData/Build/Products/Release/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
pluginkit -a /Applications/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
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
Path = /Applications/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
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
- Finder Sync behavior requires signed builds, installation to `/Applications/Blank.app`, pluginkit registration, extension enablement, and Finder restart.
- The host app UI no longer manages file-type toggles. `TemplatePreferences` and old fixed-template code may still exist in shared/tests for legacy coverage; do not revive that UX unless explicitly requested.
