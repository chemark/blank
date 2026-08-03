# Claude Code Entry Point

Read these first:

1. `AGENTS.md` for project-level agent instructions.
2. `docs/claude-code-handoff.md` for the full current handoff and configuration state.

## Do Not Touch

Do not reconfigure Node, npm, asc-cli, App Store Connect API credentials, Bundle IDs,
signing certificates, devices, or provisioning profiles unless a verification command
proves the existing setup is broken.

## Product Direction

Product name is `Blank`; site is `blank.hoshikihao.com`. Internal target names, directories,
and bundle ids keep the old `NewFile` spelling — do not rename them.

One Finder menu item, localized (`New File` / `新建文件`). Clicking it creates an empty
no-extension file in the target folder, named with the localized base name (`Untitled` /
`未命名`). Conflicts resolve as `Untitled 2` / `未命名 2`, etc. The user renames the file
to choose any extension.

Do not restore the old five fixed file-type menu entries (`.txt`, `.md`, `.json`,
`.csv`, `.html`).

## Current Status

Core feature is verified working end-to-end (2026-06-11):
- Finder right-click → New File → `Untitled` file created in the target folder.

## Critical Entitlement

The Finder Sync Extension requires:

```xml
<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
<array>
    <string>/</string>
</array>
```

in `NewFile/NewFileFinderExtension.entitlements`. Without it, the sandboxed extension
cannot write to directories surfaced through Finder (even with `user-selected.read-write`
in place). This entitlement needs a justification comment in App Store review notes.
