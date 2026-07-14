# DMS + Matugen + Pywalfox + Kitty 配色同步

换壁纸时自动将 Material You 配色推送到 Firefox、Kitty、GTK 等应用。

---

## 📋 解决的问题

在 [DMS](https://github.com/notwidow/dms) 桌面环境下换壁纸时，希望配色能自动同步到所有应用，而不是手动一套一套配。

本脚本把整个链路串起来，一键部署到位。

## 🚀 快速开始

```bash
# 从仓库根目录运行
./dms-matugen-setup/dms-matugen-setup.sh
```

或单独下载运行：

```bash
curl -O https://raw.githubusercontent.com/Ranch/Ranch-ArchLinux-Scripts/main/dms-matugen-setup.sh
chmod +x dms-matugen-setup.sh
./dms-matugen-setup.sh
```

脚本会自动检测系统、安装缺失组件、完成配置和验证。

## 🔧 功能详解

脚本按以下步骤顺序执行：

### ① 系统检测
- 识别包管理器：`pacman` / `apt` / `dnf` / `zypper`
- 识别 AUR helper：`yay` / `paru`
- 列出已安装和缺失的软件包

### ② 自动安装缺失软件
- **Arch Linux**：官方源走 `pacman`，AUR 包走 `yay`/`paru`
- **Debian/Ubuntu**：`apt install kitty`、`pip install pywalfox`、`cargo install matugen`
- 安装完成后二次验证，仍有缺失则提示手动安装

### ③ 检测 pywalfox 浏览器扩展
- 注册 Native Messaging Manifest（`~/.mozilla/native-messaging-hosts/pywalfox.json`）
- 启动 pywalfox daemon
- 提示安装 Firefox 扩展：[Pywalfox](https://addons.mozilla.org/firefox/addon/pywalfox/)

### ④ 配置 Matugen 模板
- 写入 `~/.config/matugen/templates/pywalfox-colors.json` — 16 色 Material You 配色模板
- 在 `~/.config/matugen/config.toml` 中追加 `[templates.pywalfox]` 段，配置：
  - 输入模板路径
  - 输出到 `~/.cache/wal/colors.json`
  - 输出后自动执行 `pywalfox update` + `kitty @ reload-kitty.conf`

### ⑤ 配置 Kitty 终端
- 确保 `~/.config/kitty/dank-theme.conf` 存在（由 DMS + Matugen 生成）
- 在 `kitty.conf` 末尾添加 `include dank-theme.conf`，保证最高优先级
- 生成初始配色

### ⑥ 验证
- 检查 `~/.cache/wal/colors.json` 是否完整（16 色）
- 检查 pywalfox daemon 运行状态
- 检查 kitty 主题文件
- 检查 DMS matugen 集成

## 🔄 自动化流程

换壁纸后自动触发：

```
DMS 换壁纸（GUI 或 dms ipc call wallpaper set）
         ↓ 自动
  SessionData.setWallpaper()
         ↓ 自动
  dms matugen queue
    ├─→ ~/.cache/wal/colors.json
    │    ↓ pywalfox update
    │    ↓ Firefox → 变色 ✓
    ├─→ ~/.config/kitty/dank-theme.conf
    │    ↓ kitty reload
    │    ↓ Kitty → 变色 ✓
    ├─→ GTK / niri / VS Code … 全部自动更新
    └─→ 你的 btop / cava / fastfetch 模板
```

**全程无需手动干预。**

## 📦 依赖

| 组件 | 用途 | 安装来源 |
|------|------|----------|
| [DMS / quickshell-git](https://github.com/notwidow/dms) | 桌面环境 | AUR / 手动编译 |
| [matugen-bin](https://github.com/InioX/Matugen) | Material You 颜色生成器 | AUR / `cargo install` |
| [python-pywalfox](https://github.com/Frewacom/pywalfox) | Firefox 主题桥接 | AUR / `pip install` |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | 终端模拟器 | 系统源 |

## 🖥 支持的系统

| 发行版 | 支持程度 |
|--------|----------|
| **Arch Linux** | ✅ 全自动（含 AUR） |
| Debian / Ubuntu | ✅ 自动安装（apt + pip + cargo） |
| Fedora (dnf) / openSUSE (zypper) | ⚠️ 检测到包管理器，需手动补装缺失组件 |

## ⚠️ 注意事项

1. **Firefox 扩展需要手动安装** — 脚本会提示，也可以在运行前装好：[Pywalfox 扩展](https://addons.mozilla.org/firefox/addon/pywalfox/)
2. 如果 Firefox 没有自动变色，在扩展弹窗中点击 **Fetch Colors**（或 `Ctrl+Alt+F`）
3. 脚本可重复运行，已配置的部分会自动跳过

## 🛠 手动命令参考

```bash
# 手动触发一次配色生成
matugen image "$(dms ipc call wallpaper get)" \
  -c ~/.config/matugen/config.toml \
  -m dark --prefer darkness

# 查看 DMS matugen 集成状态
dms matugen check
```
