# Blank Distribution Design

Date: 2026-08-03

## Decision

只做 Developer ID 自分发，免费，开源。放弃 Mac App Store。

## Why Not Mac App Store

App Store Connect 提交 `924cbb5f-fea4-49a4-8a57-ea7955fb2707`（1.0 build 2）于 2026-06-18 被拒，
Guideline 2.4.5(i) - Performance。Apple 原文：

> We continue to find that one or more temporary entitlement exceptions requested for this app
> are not appropriate and will not be granted:
> • `com.apple.security.temporary-exception.files.absolute-path.read-write`
> We understand this may prevent the app from being approved for the Mac App Store.

"continue to find" 表示至少拒过两次。这不是审核员误判，是明确的永久性拒绝。

保留 MAS 需要更换文件写入方式，评估过两条：

- security-scoped bookmark + App Group：主 app 通过 NSOpenPanel 让用户授权一次，
  bookmark 存入 App Group 共享容器，扩展从中取访问权。合规，但需新增 App Group，
  且用户授权范围外的目录不工作。
- AppleEvent 让 Finder 代劳：上个会话实现过并已回退。首次弹自动化授权对话框，审核不稳。

两条都会让 App Store 版体验明显差于自分发版。不做。

## Scope

做：Developer ID 签名、公证、DMG、站点、手动检查更新。

不做：改 Finder 扩展的文件写入实现、license 机制、支付、后台自动更新、分析统计。

`com.apple.security.temporary-exception.files.absolute-path.read-write = ["/"]` 原样保留。
Apple 的拒绝只对 Mac App Store 有效，自分发不受审核约束。

## Blockers

1. **Developer ID Application 证书不存在。** `security find-identity -v -p codesigning`
   只有 `3rd Party Mac Developer Application: hao hoshiki (6SKPUQN55Z)`。
   用户操作：Xcode → Settings → Accounts → Manage Certificates → + → Developer ID Application。
2. **App Store Connect API 返回 403**：`requires an in-effect agreement that has not been
   signed or has expired`。可能卡住证书申请和公证（notarytool 用同一套 ASC API key）。
   先查 developer.apple.com/account 是否有待接受的 Program License Agreement。

## Pipeline

| # | 步骤 | 谁做 |
|---|---|---|
| 1 | 取得 Developer ID Application 证书 | 用户 |
| 2 | Release 配置换签名身份、开 hardened runtime、移除 MAS 描述文件 | Claude |
| 3 | 归档与导出 | Claude |
| 4 | `notarytool` 公证 + `stapler` | Claude |
| 5 | DMG 打包 | Claude |
| 6 | Cloudflare Pages 站点 + GitHub Releases | Claude |

## Risks To Verify Before Building Anything Else

三条都必须实测，不接受推理结论：

1. **hardened runtime + app sandbox + temporary exception 能否共存。**
   公证要求 hardened runtime，Finder Sync 要求 sandbox，写文件要求 temporary exception。
   已验证的只是「无描述文件时 temporary exception 生效」，那次用 MAS 证书签名且未开
   hardened runtime。这是整条链路的成败点。
2. **公证服务是否接受扩展中的 temporary exception。** 公证为自动化恶意软件扫描，
   理论上不审 entitlement，未验证。
3. **403 协议错误是否连带阻塞证书申请与公证。**

**执行顺序硬约束：** 拿到证书后，第一件事是用 Developer ID + hardened runtime 本地签名、
安装到 `~/Applications/Blank.app`、在 Finder 中右键实测创建文件。此步通过后才进入公证、
DMG、站点。不得先做站点。

## Update Mechanism

主窗口增加「检查更新」按钮，用户主动点击才发起一次请求，读取站点上的静态 JSON，
比对 `MARKETING_VERSION`，有新版则用默认浏览器打开下载页。

不引入第三方依赖，不后台联网，不采集任何数据。

`version.json` 结构：

```json
{
  "version": "1.1",
  "download_url": "https://github.com/<owner>/<repo>/releases/latest",
  "release_notes_url": "https://github.com/<owner>/<repo>/releases/latest"
}
```

**隐私文案必须同步修改。** `NewFile/Resources/{en,zh-Hans}.lproj/Localizable.strings`
中的 `privacy.body` 现在声称「不联网」，加入检查更新后该表述不再属实，
改为「除非用户主动点击检查更新，否则不联网」。

## Hosting

- 仓库：**公开**。GitHub，仓库名待定。
- DMG：GitHub Releases。私有仓库的 Release 资产需认证才能下载，故必须公开。
  Releases 自带下载计数，是唯一的免费反馈信号。
- 站点与 `version.json`：Cloudflare Pages，绑定 `blank.hoshikihao.com`。
  域名 NS 已在 Cloudflare（`karina/sevki.ns.cloudflare.com`），无需引入第二个平台。

开源前必须从 `AGENTS.md` 移除或占位化以下标识符：ASC Key ID、Issuer ID、
分发证书 ASC id、两个 profile UUID、注册设备 UDID、本地 `.p8` 路径。
`.p8` 私钥内容从未进入仓库。

**git 历史不改写。** 上述标识符在 `a5cb0ed` 及更早的 commit 中已存在。
没有 `.p8` 私钥时这些标识符不可用，UDID 泄露基本无害，接受此残留。

## Site Scope

单页，双语切换（纯前端，无框架依赖）：

- 产品名与一句话说明
- 演示图或短 GIF：右键 → New File → 文件出现
- 下载按钮，指向 GitHub Releases 最新 DMG
- **启用扩展的步骤，需显眼。** Finder 扩展安装后默认不生效，必须在系统设置中启用。
  此步是这类工具流失率最高的环节。
- 系统要求：macOS 13.0+
- 隐私说明一句话，GitHub 链接

不做：博客、独立更新日志页、邮件订阅、分析统计。

## Open Items

- Developer ID Application 证书（用户）
- App Store Connect 403 协议（用户）
- App Store Connect 上被拒提交的处理方式：取消提交，或保留不动
- GitHub 仓库名与 owner
- `AGENTS.md` 标识符清理
- macOS 13/14/15 真机验证。当前部署目标已从 26.0 降至 13.0 并通过本机编译与测试，
  但未在旧系统运行。最可能的弱点是 `NewFile/App/ContentView.swift:60`
  的 `x-apple.systempreferences` URL。
