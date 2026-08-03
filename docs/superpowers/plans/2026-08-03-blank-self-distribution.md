# Blank Self-Distribution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Blank 做成一个可从 `blank.hoshikihao.com` 下载安装的、经过公证的免费开源 macOS 应用。

**Architecture:** 不改动 Finder 扩展的文件写入实现。Release 与 Debug 统一改用 Developer ID Application 签名并开启 hardened runtime，归档导出后打包为 DMG，签名、公证、装订，发布到 GitHub Releases，由 Cloudflare Pages 上的单页站点提供下载与 `version.json`。应用内新增一个用户主动触发的检查更新按钮。

**Tech Stack:** Tuist、xcodebuild、codesign、notarytool、hdiutil、SwiftUI、XCTest、Cloudflare Pages、GitHub Releases、`gh` CLI。

**Spec:** `docs/superpowers/specs/2026-08-03-blank-distribution-design.md`

## Inputs Required Before Execution

这三项不具备时，Task 1 无法开始，后续任务全部阻塞：

1. **Developer ID Application 证书已安装到本机钥匙串。** 验证命令：
   `security find-identity -v -p codesigning` 输出中必须出现
   `Developer ID Application: hao hoshiki (6SKPUQN55Z)`。
   取得方式：Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application。
2. **App Store Connect 403 已解除。** 验证命令：`npm run asc -- apps list` 不再报
   `requires an in-effect agreement`。公证使用同一套 ASC API key。
3. **GitHub 账号用户名。** 执行 Task 6 步骤 1 时由用户提供，记为 `GITHUB_OWNER`。
   Task 7 的 `version.json` 依赖 Task 6 步骤 2 实际创建出的仓库 URL。

## Global Constraints

- 部署目标 macOS 13.0，`Project.swift` 中六处，不得上调。
- Team ID `6SKPUQN55Z`。App bundle id `com.xingshuhao.NewFile`，扩展 bundle id
  `com.xingshuhao.NewFile.FinderExtension`。这些内部标识不改。
- 产品显示名 `Blank`。内部 target 名、scheme、`NewFile.xcodeproj`、`NewFile/` 源码目录保持 `NewFile` 拼写。
- `NewFile/NewFileFinderExtension.entitlements` 中的 `com.apple.security.app-sandbox` 与
  `com.apple.security.temporary-exception.files.absolute-path.read-write = ["/"]` 必须保留。
  `NewFile/Tests/EntitlementsTests.swift` 锁定这两条，任何改动导致该测试失败即为错误。
- 不引入任何第三方依赖。
- 用户可见字符串一律走 `Localizable.strings`，不得硬编码。语言：`en`、`zh-Hans`。
- 应用不得后台联网、不得采集数据。唯一允许的网络请求是用户点击「检查更新」后发起的单次请求。
- 修改 `Project.swift` 后必须运行 `tuist generate --no-open --cache-profile none`。
- 测试命令：
  `xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test`
- 提交信息用英文，正文说明「为什么」。不在提交中包含任何密钥、token、`.p8` 内容。

---

### Task 1: Developer ID 签名 + hardened runtime 可行性验证

这是整个计划的成败点。hardened runtime、app sandbox、temporary exception 三者能否共存
从未验证过。此任务失败意味着整条自分发路线需要重新设计，因此必须最先执行，
且在通过之前不得开始任何其他任务。

**本任务包含人工验证步骤，无法由 subagent 独立完成。步骤 6 必须由用户在 Finder 中操作确认。**

**Files:**
- Modify: `Project.swift:18-48`（四组签名设置合并为一组）
- Modify: `AGENTS.md:66-82`（签名章节）

**Interfaces:**
- Consumes: 无
- Produces: 一个用 Developer ID Application 签名、开启 hardened runtime、且 Finder 右键功能正常的
  `~/Applications/Blank.app`。Task 3 依赖同一套签名设置产出 Release 归档。

- [ ] **Step 1: 确认证书存在**

Run: `security find-identity -v -p codesigning`

Expected: 输出中包含 `Developer ID Application: hao hoshiki (6SKPUQN55Z)`。
若不存在，停止执行整个计划并告知用户。

- [ ] **Step 2: 合并签名设置并开启 hardened runtime**

Mac App Store 路线已放弃，`appSigningSettings`、`extensionSigningSettings`、
`appDistributionSettings`、`extensionDistributionSettings` 四组内容将完全一致，
合并为一组，Debug 与 Release 共用。Debug 同样开启 hardened runtime，
使日常 `./script/build_and_run.sh --verify` 的验证环境等同于发布环境。

替换 `Project.swift:18-48` 为：

```swift
// Debug 与 Release 统一用 Developer ID Application 签名，不带描述文件。
// hardened runtime 是公证的硬性要求，Debug 也开启，让日常验证等同发布环境。
let signingSettings: SettingsDictionary = [
    "DEVELOPMENT_TEAM": "6SKPUQN55Z",
    "CODE_SIGN_STYLE": "Manual",
    "CODE_SIGN_IDENTITY": "Developer ID Application",
    "CODE_SIGN_INJECT_BASE_ENTITLEMENTS": "NO",
    "PROVISIONING_PROFILE_SPECIFIER": "",
    "ENABLE_HARDENED_RUNTIME": "YES",
]
```

同时把 `sharedSettings` 中的 `"CODE_SIGN_IDENTITY": "Apple Development"`
（`Project.swift:12`）改为 `"Developer ID Application"`，
并把 `"CODE_SIGN_STYLE": "Automatic"`（`Project.swift:11`）改为 `"Manual"`。
该项目级默认此前指向已丢失私钥的证书，是误导来源。

- [ ] **Step 3: 更新三处 target 的 settings 引用**

`Project.swift` 中 app target（约 `:82-86`）、extension target（约 `:112-116`）的
`settings:` 块，把 `debug:` 与 `release:` 两个参数都指向 `signingSettings`：

```swift
            settings: .settings(
                base: ["PRODUCT_NAME": "Blank", "INFOPLIST_KEY_LSMinimumSystemVersion": "13.0"],
                debug: signingSettings,
                release: signingSettings
            )
```

extension target 同理，`base` 保持 `["PRODUCT_NAME": "NewFileFinderExtension", "INFOPLIST_KEY_LSMinimumSystemVersion": "13.0"]`。

- [ ] **Step 4: 重新生成并运行测试**

Run:
```bash
tuist generate --no-open --cache-profile none
xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test
```

Expected: `** TEST SUCCEEDED **`，5 个测试通过（`EntitlementsTests` 2 个，`FileCreationServiceTests` 3 个）。

- [ ] **Step 5: 签名构建并检查签名产物**

Run:
```bash
./script/build_and_run.sh --verify
```

Expected: `BUILD SUCCEEDED` 且输出 `Blank is running.`

然后检查扩展的签名与 entitlements：

```bash
codesign -dv --verbose=4 ~/Applications/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex 2>&1 | grep -E 'Authority|flags'
codesign -d --entitlements - --xml ~/Applications/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex | plutil -p -
```

Expected:
- `Authority=Developer ID Application: hao hoshiki (6SKPUQN55Z)`
- `flags=0x10000(runtime)` — 这是 hardened runtime 已启用的标志
- entitlements 输出中同时包含 `com.apple.security.app-sandbox => 1` 和
  `com.apple.security.temporary-exception.files.absolute-path.read-write => ["/"]`

若 `flags` 中没有 `runtime`，说明 `ENABLE_HARDENED_RUNTIME` 未生效，先解决再继续。

- [ ] **Step 6: 人工验证 Finder 功能（必须由用户执行）**

确认扩展已注册：

```bash
pluginkit -m -A -D -vvv -p com.apple.FinderSync | rg -i 'NewFile|xingshuhao|FinderExtension'
```

Expected: 出现 `com.xingshuhao.NewFile.FinderExtension(1.0)`，
`Path = /Users/xingshuhao/Applications/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex`

**请用户在 Finder 中右键点击任意文件夹，选择「新建文件」，确认目录中出现 `未命名` 文件。**

失败时读日志定位：

```bash
/usr/bin/log show --last 10m --predicate 'subsystem == "com.xingshuhao.NewFile.finder-extension"' --style compact
```

若文件未创建且日志显示写入被拒，说明 hardened runtime 与 sandbox temporary exception
不能共存。**此时停止整个计划**，向用户报告，并回到 spec 重新评估
security-scoped bookmark 方案——那会同时改变 App Store 的可行性结论。

- [ ] **Step 7: 更新 AGENTS.md 签名章节**

把 `AGENTS.md` 的 `## Signing And Provisioning` 整节替换为：

```markdown
## Signing And Provisioning

Debug 和 Release 都用 `Developer ID Application: hao hoshiki (6SKPUQN55Z)` 手动签名，
不带描述文件，并开启 hardened runtime。

- The old `Apple Development` certificate's private key is lost. Do not configure any target to use it.
- Mac App Store distribution is abandoned. Do not restore the `3rd Party Mac Developer Application` identity or the Mac App Store provisioning profiles.
- Apple TeamIdentifier: `6SKPUQN55Z`
- App bundle id: `com.xingshuhao.NewFile`
- Finder extension bundle id: `com.xingshuhao.NewFile.FinderExtension`

Do not switch back to ad-hoc signing for Finder Sync testing. `pluginkit -a` silently refuses to register an ad-hoc signed extension; the signature must chain to Apple Root CA.

Keep `com.apple.security.app-sandbox` in `NewFile/NewFileFinderExtension.entitlements`. `pluginkit -a` silently refuses to register an unsandboxed Finder Sync extension, regardless of signing identity. Because the extension is sandboxed, it also needs `com.apple.security.temporary-exception.files.absolute-path.read-write` to write into the folder the user right-clicks. This entitlement is why the Mac App Store submission was rejected under Guideline 2.4.5(i); it is fine for Developer ID distribution.
```

- [ ] **Step 8: 提交**

```bash
git add Project.swift NewFile.xcodeproj Derived AGENTS.md
git commit -m "Sign with Developer ID and enable hardened runtime

Mac App Store is abandoned, so the four signing setting groups collapse
into one shared by Debug and Release. Debug enables hardened runtime too,
so build_and_run.sh verifies the same configuration that ships.

Verified: sandbox and the absolute-path temporary exception survive
hardened runtime, and the Finder right-click still creates a file."
```

---

### Task 2: 应用内检查更新

**Files:**
- Create: `NewFile/Shared/UpdateChecker.swift`
- Create: `NewFile/Tests/UpdateCheckerTests.swift`
- Modify: `NewFile/App/ContentView.swift`
- Modify: `NewFile/Resources/en.lproj/Localizable.strings`
- Modify: `NewFile/Resources/zh-Hans.lproj/Localizable.strings`

**Interfaces:**
- Consumes: 无
- Produces:
  - `UpdateChecker.isNewer(latest: String, than current: String) -> Bool`
  - `UpdateChecker.fetchLatest(from url: URL) async throws -> UpdateInfo`
  - `struct UpdateInfo: Decodable, Equatable { let version: String; let downloadURL: URL }`
  - Task 7 的 `version.json` 必须匹配 `UpdateInfo` 的解码键：`version`、`download_url`

- [ ] **Step 1: 写失败的测试**

版本比较是这个功能里唯一有逻辑、值得测的部分。网络请求不做单测。
比较用标准库的 `compare(_:options:.numeric)`，它能正确处理 `1.10 > 1.9`，
不需要自己写 semver 解析。

Create `NewFile/Tests/UpdateCheckerTests.swift`:

```swift
import XCTest

final class UpdateCheckerTests: XCTestCase {
    func testNewerVersionIsDetected() {
        XCTAssertTrue(UpdateChecker.isNewer(latest: "1.1", than: "1.0"))
    }

    func testSameVersionIsNotNewer() {
        XCTAssertFalse(UpdateChecker.isNewer(latest: "1.0", than: "1.0"))
    }

    func testOlderVersionIsNotNewer() {
        XCTAssertFalse(UpdateChecker.isNewer(latest: "1.0", than: "1.1"))
    }

    // 字符串比较会把 "1.10" 判成小于 "1.9"，数值比较不会。
    func testDoubleDigitMinorVersionIsNewer() {
        XCTAssertTrue(UpdateChecker.isNewer(latest: "1.10", than: "1.9"))
    }

    func testUpdateInfoDecodesFromVersionJSON() throws {
        let json = Data("""
        {"version":"1.1","download_url":"https://example.com/releases"}
        """.utf8)

        let info = try JSONDecoder().decode(UpdateInfo.self, from: json)

        XCTAssertEqual(info.version, "1.1")
        XCTAssertEqual(info.downloadURL, URL(string: "https://example.com/releases"))
    }
}
```

- [ ] **Step 2: 运行测试确认失败**

Run:
```bash
tuist generate --no-open --cache-profile none
xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test 2>&1 | grep -E 'error:|TEST'
```

Expected: 编译失败，`cannot find 'UpdateChecker' in scope` 与 `cannot find type 'UpdateInfo' in scope`。

- [ ] **Step 3: 写最小实现**

放在 `NewFile/Shared/` 而不是 `NewFile/App/`，是因为测试 target 的 sources 只有
`NewFile/Tests/**` 与 `NewFile/Shared/**`（`Project.swift:125-128`），放 App 下就测不到。
代价是扩展 target 也会编译这个文件——它不会被扩展调用，扩展的 entitlements 里
也没有 `network.client`，所以不影响「扩展不联网」这一事实。

Create `NewFile/Shared/UpdateChecker.swift`:

```swift
import Foundation

struct UpdateInfo: Decodable, Equatable {
    let version: String
    let downloadURL: URL

    enum CodingKeys: String, CodingKey {
        case version
        case downloadURL = "download_url"
    }
}

enum UpdateChecker {
    /// 用数值方式比较版本号，避免 "1.10" 被判成小于 "1.9"。
    static func isNewer(latest: String, than current: String) -> Bool {
        latest.compare(current, options: .numeric) == .orderedDescending
    }

    static func fetchLatest(from url: URL) async throws -> UpdateInfo {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(UpdateInfo.self, from: data)
    }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run:
```bash
xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test 2>&1 | tail -6
```

Expected: `** TEST SUCCEEDED **`，10 个测试通过（原 5 个 + 新增 5 个）。

- [ ] **Step 5: 提交逻辑层**

```bash
git add NewFile/Shared/UpdateChecker.swift NewFile/Tests/UpdateCheckerTests.swift NewFile.xcodeproj Derived
git commit -m "Add UpdateChecker

Numeric version comparison so 1.10 sorts above 1.9, and a Decodable that
matches the version.json served by the site. Network fetch is not unit
tested; the comparison is where the logic lives."
```

- [ ] **Step 6: 加入本地化字符串**

追加到 `NewFile/Resources/en.lproj/Localizable.strings`:

```
/* 检查更新 */
"update.check" = "Check for Updates";
"update.checking" = "Checking…";
"update.up_to_date" = "Blank is up to date.";
"update.available" = "A new version is available.";
"update.failed" = "Could not check for updates.";
```

追加到 `NewFile/Resources/zh-Hans.lproj/Localizable.strings`:

```
/* 检查更新 */
"update.check" = "检查更新";
"update.checking" = "正在检查…";
"update.up_to_date" = "Blank 已是最新版本。";
"update.available" = "有新版本可用。";
"update.failed" = "检查更新失败。";
```

- [ ] **Step 7: 修正隐私文案**

现有 `privacy.body` 声称不联网，加入检查更新后不再属实。

`NewFile/Resources/en.lproj/Localizable.strings` 中把 `privacy.body` 整行替换为：

```
"privacy.body" = "Blank does not use analytics, background daemons, file indexing, or content scanning. It only creates an empty Untitled file in the Finder folder you act on. It goes online only when you click Check for Updates.";
```

`NewFile/Resources/zh-Hans.lproj/Localizable.strings` 中把 `privacy.body` 整行替换为：

```
"privacy.body" = "Blank 不做分析统计、不驻留后台进程、不索引文件、不扫描内容。它只在你操作的 Finder 文件夹里创建一个空的「未命名」文件。只有你主动点击「检查更新」时它才会联网。";
```

- [ ] **Step 8: 在界面上接入按钮**

`NewFile/App/ContentView.swift` 中，`ContentView` 需要状态，改为持有 `@State`。
把 `struct ContentView: View {` 之后的 `var body` 之前插入：

```swift
    @State private var updateStatusKey: String?
    @State private var isCheckingUpdate = false
```

把 `enablementPanel` 中的 `HStack { ... }` 块（当前 `ContentView.swift:32-40`）替换为：

```swift
            HStack {
                Button("setup.open_settings") {
                    ExtensionSettingsOpener.open()
                }
                Button("setup.relaunch_finder") {
                    FinderRelauncher.relaunch()
                }
                Button("update.check") {
                    Task { await checkForUpdates() }
                }
                .disabled(isCheckingUpdate)
                if let updateStatusKey {
                    Text(LocalizedStringKey(updateStatusKey))
                        .foregroundStyle(.secondary)
                }
            }
```

在 `privacyPanel` 之后、`ContentView` 结构体结束的 `}` 之前插入：

```swift
    private static let versionManifestURL = URL(string: "https://blank.hoshikihao.com/version.json")!

    private func checkForUpdates() async {
        isCheckingUpdate = true
        updateStatusKey = "update.checking"
        defer { isCheckingUpdate = false }

        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

        do {
            let info = try await UpdateChecker.fetchLatest(from: Self.versionManifestURL)
            if UpdateChecker.isNewer(latest: info.version, than: current) {
                updateStatusKey = "update.available"
                NSWorkspace.shared.open(info.downloadURL)
            } else {
                updateStatusKey = "update.up_to_date"
            }
        } catch {
            updateStatusKey = "update.failed"
        }
    }
```

- [ ] **Step 9: 确认应用具备出网能力**

沙盒应用默认没有网络权限。检查 `NewFile/NewFile.entitlements`，
若不含 `com.apple.security.network.client`，加入：

```xml
	<key>com.apple.security.network.client</key>
	<true/>
```

只加在主应用的 entitlements，**不要**加到 `NewFileFinderExtension.entitlements`——
扩展不联网，多给权限会削弱隐私声明。

- [ ] **Step 10: 构建并人工验证**

Run:
```bash
xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug -derivedDataPath .derivedData -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO test 2>&1 | tail -4
./script/build_and_run.sh --verify
```

Expected: 测试通过，应用启动。此时 `version.json` 尚未上线，
**点击「检查更新」预期显示 `update.failed` 对应的文案**，这是正确行为。
Task 7 部署站点后会复验成功路径。

- [ ] **Step 11: 提交界面层**

```bash
git add NewFile/App/ContentView.swift NewFile/Resources NewFile/NewFile.entitlements NewFile.xcodeproj Derived
git commit -m "Add Check for Updates button

User-triggered only: no background polling, no analytics. The privacy
copy previously claimed the app never goes online, which stops being
true here, so both locales now say it goes online only on that click.

network.client is granted to the host app only. The extension stays
offline."
```

---

### Task 3: 归档、导出、公证、装订

**Files:**
- Modify: `ExportOptions.plist`
- Create: `script/release.sh`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: Task 1 的 Developer ID 签名设置
- Produces: `dist/Blank.app`，已签名、已公证、已装订。Task 4 从此路径打包 DMG。

- [ ] **Step 1: 把 ExportOptions.plist 改为 developer-id**

替换 `ExportOptions.plist` 全文：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>6SKPUQN55Z</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
```

`provisioningProfiles` 与 `installerSigningCertificate` 两项一并删除，Developer ID 分发不使用描述文件。

- [ ] **Step 2: 存储公证凭据**

Run（`--key` 路径来自 `AGENTS.md` 记录的本地 `.p8` 位置）:

```bash
xcrun notarytool store-credentials blank-notary \
  --key <path-to-your-AuthKey.p8> \
  --key-id <your-key-id> \
  --issuer <your-issuer-id>
```

Expected: `Validating your credentials... Success.`

若报 403 或 agreement 相关错误，说明 Inputs 第 2 项未真正解除，停止并告知用户。

凭据存进钥匙串，**不写入仓库任何文件**。

- [ ] **Step 3: 写发布脚本**

Create `script/release.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/NewFile.xcodeproj"
ARCHIVE_PATH="$PROJECT_ROOT/build/Blank.xcarchive"
EXPORT_DIR="$PROJECT_ROOT/dist"
APP_PATH="$EXPORT_DIR/Blank.app"
NOTARY_PROFILE="blank-notary"

cd "$PROJECT_ROOT"

rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme NewFile \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -skipPackagePluginValidation \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$PROJECT_ROOT/ExportOptions.plist"

echo "==> 导出完成，检查签名"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "==> 公证 app"
DITTO_ZIP="$PROJECT_ROOT/build/Blank.zip"
/usr/bin/ditto -c -k --keepParent "$APP_PATH" "$DITTO_ZIP"
xcrun notarytool submit "$DITTO_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> 装订"
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "==> Gatekeeper 评估"
spctl -a -vvv -t exec "$APP_PATH"

echo "Done: $APP_PATH"
```

Run: `chmod +x script/release.sh`

- [ ] **Step 4: 忽略构建产物**

追加到 `.gitignore`:

```
build/
dist/
```

- [ ] **Step 5: 执行发布脚本**

Run: `./script/release.sh`

Expected:
- `ARCHIVE SUCCEEDED` 与 `EXPORT SUCCEEDED`
- notarytool 输出 `status: Accepted`
- `stapler validate` 输出 `The validate action worked!`
- `spctl` 输出 `accepted` 且 `source=Notarized Developer ID`

若 notarytool 返回 `Invalid`，用以下命令取详细原因后停止并报告：

```bash
xcrun notarytool log <submission-id> --keychain-profile blank-notary
```

公证被拒最可能的原因是某个嵌套二进制未开 hardened runtime 或签名不完整，
而不是 entitlement——若日志显示是 entitlement 问题，那是 spec 中风险 2 成立，
需向用户报告后重新评估。

- [ ] **Step 6: 人工验证公证后的应用仍能工作（必须由用户执行）**

Run:
```bash
/usr/bin/ditto dist/Blank.app ~/Applications/Blank.app
/usr/bin/pluginkit -a ~/Applications/Blank.app/Contents/PlugIns/NewFileFinderExtension.appex
/usr/bin/pluginkit -e use -i com.xingshuhao.NewFile.FinderExtension
osascript -e 'tell application "Finder" to quit' -e 'delay 0.5' -e 'tell application "Finder" to activate'
```

**请用户在 Finder 中右键点击文件夹，选择「新建文件」，确认文件被创建。**

Release 配置与公证后的产物此前从未验证过，不能假设与 Debug 行为一致。

- [ ] **Step 7: 提交**

```bash
git add ExportOptions.plist script/release.sh .gitignore
git commit -m "Add release script for Developer ID notarization

Archives Release, exports with developer-id, notarizes through notarytool
with a keychain profile, staples, and asserts the result with stapler
validate and spctl. Credentials live in the keychain, never in the repo."
```

---

### Task 4: DMG 打包

**Files:**
- Modify: `script/release.sh`

**Interfaces:**
- Consumes: Task 3 产出的 `dist/Blank.app`（已装订）
- Produces: `dist/Blank.dmg`，已签名、已公证、已装订。Task 6 上传此文件。

DMG 需要独立签名与公证。装订到 DMG 上，用户下载后即使离线首次打开也能通过 Gatekeeper。

- [ ] **Step 1: 在发布脚本末尾追加 DMG 步骤**

把 `script/release.sh` 最后一行 `echo "Done: $APP_PATH"` 替换为：

```bash
echo "==> 打包 DMG"
DMG_PATH="$EXPORT_DIR/Blank.dmg"
STAGING_DIR="$PROJECT_ROOT/build/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
/usr/bin/ditto "$APP_PATH" "$STAGING_DIR/Blank.app"
ln -s /Applications "$STAGING_DIR/Applications"

/usr/bin/hdiutil create \
  -volname Blank \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"

echo "==> 签名并公证 DMG"
codesign --sign "Developer ID Application" --timestamp "$DMG_PATH"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
spctl -a -vvv -t install "$DMG_PATH"

echo "Done: $DMG_PATH"
```

`ln -s /Applications` 生成拖拽安装用的快捷方式，是 macOS DMG 的惯例布局。

- [ ] **Step 2: 执行并验证**

Run: `./script/release.sh`

Expected:
- `hdiutil` 输出 `created: .../dist/Blank.dmg`
- DMG 的 notarytool 输出 `status: Accepted`
- `stapler validate` 输出 `The validate action worked!`
- `spctl -a -t install` 输出 `accepted` 且 `source=Notarized Developer ID`

- [ ] **Step 3: 人工验证下载体验（必须由用户执行）**

模拟真实用户首次打开。先给 DMG 打上隔离标记，再双击：

```bash
xattr -w com.apple.quarantine "0081;00000000;Safari;" dist/Blank.dmg
open dist/Blank.dmg
```

**请用户确认：双击 DMG 不出现「无法打开，因为无法验证开发者」类警告，
把 Blank 拖入 Applications 后能正常启动。**

这是唯一能证明公证链路对最终用户真正生效的验证。

- [ ] **Step 4: 提交**

```bash
git add script/release.sh
git commit -m "Package, sign, notarize and staple a DMG

Stapling the DMG means a first launch works offline. Verified against a
quarantined copy, which is what a real download looks like."
```

---

### Task 5: 开源准备

**Files:**
- Modify: `AGENTS.md`
- Create: `LICENSE`
- Create: `README.md`

**Interfaces:**
- Consumes: 无
- Produces: 一个可公开的仓库工作树。Task 6 推送它。

**README.md 的创建是本任务的必要产物**：公开仓库没有 README 时，
GitHub 仓库首页与 Releases 页对访问者不可读。这是开源决定的直接推论。

- [ ] **Step 1: 从 AGENTS.md 移除账号标识符**

删除 `## App Store Connect CLI` 整节。Mac App Store 路线已放弃，
`asc-cli` 不再是项目工作流的一部分，该节同时是 Key ID 与 Issuer ID 的来源。

删除 `### Development (Debug)` 中的 `Registered Mac device UDID` 一行。

删除 `package.json` 中的 `asc` script 与 `@onmyway133/asc-cli` 依赖，
运行 `npm uninstall @onmyway133/asc-cli`。若删除后 `package.json` 只剩空壳，
一并删除 `package.json`、`package-lock.json`、`node_modules/`。
**删除文件前向用户确认。**

公证凭据的引用改为不含具体 id 的说明。在 `## Signing And Provisioning` 末尾追加：

```markdown
Notarization uses a keychain profile named `blank-notary`, created with
`xcrun notarytool store-credentials`. The App Store Connect API key id, issuer id,
and `.p8` path are intentionally not recorded in this repository.
```

- [ ] **Step 2: 确认仓库中没有密钥材料**

Run:
```bash
rg -i 'BEGIN PRIVATE KEY|BEGIN RSA|AuthKey_|\.p8|password|secret' --glob '!node_modules' --glob '!.derivedData' .
git log -p --all | rg -i 'BEGIN PRIVATE KEY|BEGIN EC PRIVATE KEY' | head
```

Expected: 无私钥内容命中。若命中，停止并向用户报告——那会改变「历史不改写」的决定。

- [ ] **Step 3: 加入 LICENSE**

Create `LICENSE`，MIT 全文，版权行为 `Copyright (c) 2026 Xing Shuhao`。
MIT 与项目现有的 `NSHumanReadableCopyright` 一致，且对一个小工具最省事。
若用户希望换成 GPL 或 Apache-2.0，在执行时替换。

- [ ] **Step 4: 写 README.md**

Create `README.md`:

```markdown
# Blank

A macOS Finder extension that adds one menu item: create an empty file.

Right-click a folder, choose **New File**, and an extension-less file named
`Untitled` appears. Rename it to whatever you need — `note.md`, `data.json`,
anything. That is the whole app.

## Install

Download the latest DMG from [Releases](https://github.com/OWNER/REPO/releases/latest),
drag Blank to Applications, then enable the extension:

**System Settings → General → Login Items & Extensions → Finder Extensions → enable Blank.**

The menu item will not appear until the extension is enabled.

Requires macOS 13.0 or later.

## Privacy

Blank has no analytics, no background daemon, no file indexing, no content
scanning. It creates one empty file in the folder you right-click. It goes
online only when you click **Check for Updates**.

## Why the broad entitlement

The Finder Sync extension ships with
`com.apple.security.temporary-exception.files.absolute-path.read-write`.
A sandboxed Finder Sync extension cannot write into the folder the user
right-clicked without it — the target folder is only known at runtime, and
`user-selected.read-write` covers only paths chosen through an open panel.
Apple rejected this entitlement for the Mac App Store under guideline 2.4.5(i),
which is why Blank is distributed directly instead.

## Build

Requires [Tuist](https://tuist.io).

    tuist generate --no-open --cache-profile none
    ./script/build_and_run.sh --verify

Tests:

    xcodebuild -project NewFile.xcodeproj -scheme NewFile -configuration Debug \
      -derivedDataPath .derivedData -skipPackagePluginValidation \
      CODE_SIGNING_ALLOWED=NO test

The repository directory is `blank`, but internal target names, the Xcode
project, and bundle ids keep the original `NewFile` spelling.

## License

MIT
```

`OWNER/REPO` 在 Task 6 步骤 2 创建仓库后用实际值替换。

- [ ] **Step 5: 提交**

```bash
git add AGENTS.md LICENSE README.md package.json package-lock.json
git commit -m "Prepare for open source

Drop the App Store Connect CLI section and the device UDID from AGENTS.md;
those identifiers should not be public and asc-cli is no longer part of the
workflow. Add MIT license and a README that explains the broad entitlement
up front, since that is the first thing a careful user will question."
```

---

### Task 6: 推送到 GitHub 并发布首个 Release

**Files:**
- Modify: `README.md`（填入实际仓库 URL）

**Interfaces:**
- Consumes: Task 4 的 `dist/Blank.dmg`，Task 5 的工作树
- Produces: 公开仓库 URL 与 Release 下载 URL。Task 7 的 `version.json` 依赖它们。

**本任务包含红线操作（`git push`、公开发布），每一步都必须先向用户确认。**

- [ ] **Step 1: 取得 GitHub 用户名并确认 gh 已登录**

Run: `gh auth status`

Expected: 显示已登录账号。未登录时提示用户运行 `! gh auth login`，不要代为执行。

向用户确认仓库名，默认建议 `blank`。

- [ ] **Step 2: 创建公开仓库（需用户确认后执行）**

Run:
```bash
gh repo create <OWNER>/<REPO> --public --source=. --remote=origin --description "A macOS Finder extension that creates an empty file"
```

记录输出的仓库 URL。

- [ ] **Step 3: 用实际 URL 替换 README 占位**

把 `README.md` 中的 `https://github.com/OWNER/REPO/releases/latest`
替换为步骤 2 得到的实际地址。

```bash
git add README.md
git commit -m "Point README download link at the real repository"
```

- [ ] **Step 4: 推送（红线，需用户明确确认）**

向用户说明：这会把全部 git 历史公开，包括 `a5cb0ed` 及更早 commit 中
`AGENTS.md` 里的 ASC Key ID、Issuer ID、证书 id、profile UUID、设备 UDID。
这是 spec 中「历史不改写」的既定决策，请用户再确认一次。

Run: `git push -u origin main`

- [ ] **Step 5: 发布 Release（红线，需用户明确确认）**

Run:
```bash
gh release create 1.0 dist/Blank.dmg \
  --title "Blank 1.0" \
  --notes "First public release.

Right-click a folder in Finder and choose New File to create an empty,
extension-less file. Requires macOS 13.0 or later.

After installing, enable the extension in System Settings → General →
Login Items & Extensions → Finder Extensions."
```

- [ ] **Step 6: 验证下载链路**

Run:
```bash
curl -sIL https://github.com/<OWNER>/<REPO>/releases/latest/download/Blank.dmg | grep -E '^HTTP|location'
```

Expected: 最终返回 `HTTP/2 200`，确认匿名用户可下载。

---

### Task 7: 站点与 version.json

**Files:**
- Create: `site/index.html`
- Create: `site/version.json`

**Interfaces:**
- Consumes: Task 6 的仓库与 Release URL；`UpdateInfo` 的解码键 `version`、`download_url`
- Produces: `https://blank.hoshikihao.com` 与 `https://blank.hoshikihao.com/version.json`

- [ ] **Step 1: 写 version.json**

Create `site/version.json`（`<OWNER>/<REPO>` 用 Task 6 的实际值）:

```json
{
  "version": "1.0",
  "download_url": "https://github.com/<OWNER>/<REPO>/releases/latest"
}
```

`version` 必须与 `Project.swift` 中的 `MARKETING_VERSION` 保持同步。
每次发版都要更新此文件，否则「检查更新」会永远报告已是最新。

- [ ] **Step 2: 写单页站点**

Create `site/index.html`。要求：

- 单文件，无框架、无外部依赖、无分析脚本
- 中英双语，一个按钮切换，`lang` 属性随之更新；默认语言按 `navigator.language`
  是否以 `zh` 开头决定
- 内容顺序：产品名 → 一句话说明 → 下载按钮（指向 Release）→ **启用扩展的三步说明**
  → 系统要求 macOS 13.0+ → 隐私一句话 → GitHub 链接
- 启用扩展的说明必须视觉突出。Finder 扩展装完默认不生效，这是流失率最高的一步。
- 深浅色都要可读，用 `prefers-color-scheme`

具体视觉设计在执行时用 `frontend-design` skill 展开，避免模板感。

- [ ] **Step 3: 本地检查**

Run: `open site/index.html`

**请用户确认：双语切换正常，下载按钮指向正确的 Release 地址，
启用扩展的步骤一眼能看到。**

- [ ] **Step 4: 提交**

```bash
git add site/
git commit -m "Add landing page and version manifest

Single file, no dependencies, no analytics. The extension-enabling steps
are given the most visual weight: a Finder extension does nothing until
the user turns it on in System Settings, and that is where people give up."
```

- [ ] **Step 5: 部署到 Cloudflare Pages（红线，公开发布，需用户确认）**

使用 `cloudflare-deploy` skill 部署 `site/` 目录，绑定自定义域名
`blank.hoshikihao.com`。域名 NS 已在 Cloudflare（`karina/sevki.ns.cloudflare.com`）。

- [ ] **Step 6: 端到端验证**

Run:
```bash
curl -s https://blank.hoshikihao.com/version.json
curl -sI https://blank.hoshikihao.com | head -1
```

Expected: JSON 内容正确返回，站点返回 `HTTP/2 200`。

然后复验 Task 2 步骤 10 中未能验证的成功路径：

```bash
./script/build_and_run.sh --verify
```

**请用户点击应用中的「检查更新」，确认显示「Blank 已是最新版本」
而不是失败文案。** 这证明 `version.json` 的格式与 `UpdateInfo` 解码一致。

---

## Post-Plan Follow-ups

不在本计划范围内，但已知需要跟进：

- macOS 13/14/15 真机验证。当前只做过本机（macOS 26）编译。
  最可能的弱点是 `NewFile/App/ContentView.swift` 中的
  `x-apple.systempreferences` URL 在旧系统上打不开。
- App Store Connect 中被拒的提交 `924cbb5f` 如何处理：取消提交，或保留不动。
- 发版流程文档化：`MARKETING_VERSION`、`site/version.json`、
  `gh release create` 的 tag 三处版本号必须同步，目前靠人记。
