# NewFile Agent Guide

## Project

NewFile is a native macOS utility that adds a Finder Sync Extension. The intended Finder behavior is:

- Right-click a folder, selected folder, or folder background.
- Show one menu item: `New File`.
- Create an empty file named `Untitled` in that folder.
- If needed, use conflict-safe names: `Untitled 2`, `Untitled 3`, etc.
- The user renames the file manually to choose any extension, such as `note.md` or `data.json`.

Do not bring back the old fixed menu items for `.txt`, `.md`, `.json`, `.csv`, and `.html`.

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

Build, sign, launch, and verify the app:

```sh
./script/build_and_run.sh --verify
```

Important: after running tests with `CODE_SIGNING_ALLOWED=NO`, run `./script/build_and_run.sh --verify` again before Finder-extension testing, because Finder must use the signed Debug app/extension.

## Signing And Provisioning

Both Development (Debug) and Distribution (Release) are configured for manual signing.

### Development (Debug)

- Signing identity: `Apple Development: hoshikihao@proton.me (ABD492V5HK)`
- Host provisioning profile: `NewFile Mac Development`
- Host profile UUID: `b3514bbe-c3a5-4cbc-afb8-32bcd8fa35d6`
- Extension provisioning profile: `NewFile Finder Extension Mac Development`
- Extension profile UUID: `2d41ac9e-5a21-4d26-bedd-1ebbd8c0e39d`
- Registered Mac device UDID: `00008112-0004095C2E08201E`

### Distribution (Release / Mac App Store)

- Signing identity: `3rd Party Mac Developer Application: hao hoshiki (6SKPUQN55Z)`
- Distribution certificate ASC id: `XR849UQQ74`
- Host provisioning profile: `NewFile Mac App Store`
- Host profile UUID: `9515779f-885c-4bd2-9d45-82a989b38e36`
- Extension provisioning profile: `NewFile Finder Extension Mac App Store`
- Extension profile UUID: `6cd9bbbc-1759-4f40-b862-a2f911ad2300`

### Common

- Apple TeamIdentifier: `6SKPUQN55Z`
- App bundle id: `com.xingshuhao.NewFile`
- Finder extension bundle id: `com.xingshuhao.NewFile.FinderExtension`

Do not switch back to ad-hoc signing for Finder Sync testing. Unsigned/ad-hoc builds may run the host app but Finder may not load or execute the extension correctly.

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

After a signed build:

```sh
pluginkit -a /Users/xingshuhao/newfile/.derivedData/Build/Products/Debug/NewFile.app/Contents/PlugIns/NewFileFinderExtension.appex
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
Path = /Users/xingshuhao/newfile/.derivedData/Build/Products/Debug/NewFile.app/Contents/PlugIns/NewFileFinderExtension.appex
Display Name = NewFile Finder Extension
Parent Name = NewFile
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
- Finder Sync behavior requires signed builds, pluginkit registration, extension enablement, and Finder restart.
- The host app UI no longer manages file-type toggles. `TemplatePreferences` and old fixed-template code may still exist in shared/tests for legacy coverage; do not revive that UX unless explicitly requested.
