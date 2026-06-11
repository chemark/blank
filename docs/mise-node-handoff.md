# Codex Handoff: Node/npm 已切回 mise 管理

## 背景

用户在安装 App Store Connect CLI 时发现 npm 行为异常，并怀疑是否和 `mise` 管理 Node 有关。

排查发现：问题不是 `mise` 本身坏了，而是 PATH 中仍有 Hermes 卸载后的残留入口抢在 `mise` 前面。

## 当时发现的状态

- `mise current node` 显示 `25.9.0`
- `mise which node` 指向：
  - `/Users/xingshuhao/.local/share/mise/installs/node/25.9.0/bin/node`
- 但实际 `type -a node` 第一项曾是：
  - `/Users/xingshuhao/.local/bin/node`
- 该文件是 Hermes 残留 symlink：
  - `/Users/xingshuhao/.local/bin/node -> /Users/xingshuhao/.hermes/node/bin/node`
  - `/Users/xingshuhao/.local/bin/npm -> /Users/xingshuhao/.hermes/node/bin/npm`
- PATH 里 `/Users/xingshuhao/.local/bin` 排在 `/Users/xingshuhao/.local/share/mise/shims` 前面，所以 Hermes 残留抢先。

## 已做的改动

1. 删除了两个 Hermes 残留 symlink：

```sh
rm -f /Users/xingshuhao/.local/bin/node /Users/xingshuhao/.local/bin/npm
```

2. 在 `/Users/xingshuhao/.zshrc` 末尾追加了 mise 优先级覆盖：

```sh
# Prefer mise-managed tool shims after other PATH installers.
export PATH="$HOME/.local/share/mise/shims:$PATH"
typeset -U path PATH
```

这么做的原因：`.zshrc` 前面和 `.zprofile` 里都有工具安装器会把 `~/.local/bin` 提前，包括 Antigravity/pipx 相关配置。把 mise shims 放在 `.zshrc` 末尾，可以让最终 PATH 解析以 mise 为准。

## 验证结果

在新的 zsh 登录/交互环境里验证过：

```sh
zsh -lic 'type -a node; node -v; mise current node; mise which node'
```

结果显示：

- `node` 第一项为 `/Users/xingshuhao/.local/share/mise/shims/node`
- `node -v` 为 `v25.9.0`
- `mise current node` 为 `25.9.0`
- `mise which node` 指向 `/Users/xingshuhao/.local/share/mise/installs/node/25.9.0/bin/node`

也验证过：

```sh
zsh -lic 'type -a npm; npm -v; npm config get prefix; npm config get cache'
```

结果显示：

- `npm` 第一项为 `/Users/xingshuhao/.local/share/mise/shims/npm`
- `npm -v` 为 `11.12.1`
- `npm config get prefix` 为 `/Users/xingshuhao/.local/share/mise/installs/node/25.9.0`
- `npm config get cache` 仍为 `/Users/xingshuhao/.npm`

## 注意事项

- 当前已打开的终端可能仍保留旧 PATH，需要重开终端或执行：

```sh
source ~/.zshrc
```

- 我没有修改 `~/.npm` 权限，也没有清理 npm cache。
- 之前 npm 提示 `~/.npm` 可能有 root-owned 文件，但只读检查没有在 `~/.npm` 下找到非当前用户拥有的文件。后续如果 npm 仍报 cache 权限问题，再单独处理。
- side conversation 中用户中断了安装 `@onmyway133/asc-cli`，所以不要假设 App Store Connect CLI 已经安装完成。

## 给下一个 Codex 会话的建议开场白

你可以这样开场：

> 我先接上上个会话的状态：Hermes 已卸载，但它遗留的 `~/.local/bin/node` 和 `~/.local/bin/npm` 曾经抢在 mise 前面。上个会话已经删除这两个残留 symlink，并在 `~/.zshrc` 末尾把 `~/.local/share/mise/shims` 提到 PATH 最前。最新验证显示新 zsh 环境下 `node`/`npm` 已经走 mise，Node 是 `25.9.0`，npm 是 `11.12.1`。我接下来会先用 `zsh -lic 'node -v && npm -v && type -a node npm'` 复核当前状态，然后再继续安装或配置 App Store Connect CLI。

## 建议下一个会话先跑的只读命令

```sh
zsh -lic 'type -a node; type -a npm; node -v; npm -v; mise current node; mise which node'
```

如果结果仍是 mise，则可以继续安装 CLI。为了避免 npm cache 历史问题，安装时可以继续使用临时 cache：

```sh
npm install --save-dev @onmyway133/asc-cli --cache /private/tmp/newfile-npm-cache
```

