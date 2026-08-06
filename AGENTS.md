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
- Release entrypoint: `script/release.sh`
- Landing page: `site/`
- Codex run button config: `.codex/environments/environment.toml`
- Design docs and implementation plans: `docs/superpowers/`
- Known work not yet scheduled: `docs/roadmap.md`

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

Do not configure any target to use the old `Apple Development` certificate. Its private key is
lost and it no longer appears in `security find-identity -v -p codesigning`.

Mac App Store distribution is abandoned. Do not restore the `3rd Party Mac Developer Application`
identity or the Mac App Store provisioning profiles.

Do not switch back to ad-hoc signing for Finder Sync testing. `pluginkit -a` silently refuses to register an ad-hoc signed extension; the signature must chain to Apple Root CA.

Keep `ENABLE_HARDENED_RUNTIME` on. Notarization requires it, and it is verified to coexist with
the sandbox and the absolute-path temporary exception.

Keep `com.apple.security.app-sandbox` in `NewFile/NewFileFinderExtension.entitlements`. `pluginkit -a` silently refuses to register an unsandboxed Finder Sync extension, regardless of signing identity. Because the extension is sandboxed, it also needs `com.apple.security.temporary-exception.files.absolute-path.read-write` to write into the folder the user right-clicks. Apple rejected that entitlement for the Mac App Store under guideline 2.4.5(i); it is fine for Developer ID distribution.

## Release Workflow

Three version numbers must always match. Missing the third one makes Check for Updates
report "up to date" forever, with no error anywhere:

1. `MARKETING_VERSION` in `Project.swift`
2. `version` in `site/version.json`
3. the git tag passed to `gh release create`

Release order:

```sh
# 1. bump MARKETING_VERSION in Project.swift, then
tuist generate --no-open --cache-profile none
# 2. build, notarize, staple, package
./script/release.sh
# 3. publish the DMG
gh release create <version> dist/Blank.dmg --title "Blank <version>"
# 4. bump site/version.json, commit, and push — Cloudflare Pages deploys main automatically
```

`./script/release.sh` archives, exports, notarizes, staples, and packages a signed DMG.
Notarization uses a keychain profile named `blank-notary`, created once with
`xcrun notarytool store-credentials`. The App Store Connect API key id, issuer id, and `.p8`
path are deliberately not recorded in this repository. Do not paste or commit `.p8` contents.

## Site

`site/` is deployed to Cloudflare Pages (project `blank`, domain `blank.hoshikihao.com`)
from `main` on every push. Build command is empty; build output directory is `site`.

`site/version.json` is the data source for the app's Check for Updates button. Its
`version` and `download_url` keys must stay compatible with `UpdateInfo` in
`NewFile/Shared/UpdateChecker.swift`.

The page has no build step, no framework, and no external requests. Keep it that way:
no CDN links, no web fonts, no analytics.

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

## Current Caveats

- The repository is initialized, but many project files are still untracked. Do not assume a clean committed baseline.
- Finder Sync behavior requires signed builds, installation to `/Applications/Blank.app`, pluginkit registration, extension enablement, and Finder restart.
- The host app UI no longer manages file-type toggles. `TemplatePreferences` and old fixed-template code may still exist in shared/tests for legacy coverage; do not revive that UX unless explicitly requested.
