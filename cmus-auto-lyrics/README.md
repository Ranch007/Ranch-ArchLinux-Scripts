# cmus-auto-lyrics 修复笔记

cmus 歌词显示工具。AUR 包编译时绑死了 Python 3.14，导致在 Arch 上运行时报 `PyUnicode_AsWideChar` 符号缺失。

---

## 📋 问题

从 AUR 安装 `cmus-auto-lyrics` 后运行报错：

```
ImportError: /tmp/onefile_xxx/_curses.so: undefined symbol: PyUnicode_AsWideChar
```

## 🔍 根因分析

### 现象

- `cmus-auto-lyrics` 是一个 Nuitka 编译的单文件 Python 二进制
- 内部嵌了 `_curses.so`，它链接了 Python 的 C API 符号 `PyUnicode_AsWideChar`
- 启动时动态加载 `_curses.so`，发现系统上没有这个符号 → 炸了

### 排查过程

1. **确认二进制本身没问题** — `file cmus-auto-lyrics` 显示是正常的 ELF 64-bit 可执行文件
2. **看 PKGBUILD** — AUR 的 `cmus-auto-lyrics` PKGBUILD 里 `prepare()` 硬编码了 `uv python install 3.14`，编译阶段强制用 Python 3.14
3. **查 Python 3.14 变更** — Python 3.14 的 C API 移除了 `PyUnicode_AsWideChar`（PEP 623 彻底执行，这个 deprecated 的 API 在 3.12 被标记废弃，3.14 直接删了）
4. **定位到根因** — Nuitka 在 Python 3.14 环境下编译出的 `_curses.so` 缺少 `PyUnicode_AsWideChar` 符号，而运行时的动态链接器找不到它

### 根因

**PKGBUILD 强制用 Python 3.14 编译，但 `_curses` 模块依赖的 `PyUnicode_AsWideChar` 在 3.14 中已被移除。**

## 🛠 解决方法

换用 Python 3.12 重新编译。Python 3.12 仍然保留 `PyUnicode_AsWideChar`，且是 Arch 官方仓库中可用的稳定版本。

### 步骤

```bash
# 1. 安装 Python 版本管理器 mise + 包管理器 uv
sudo pacman -S mise uv

# 2. 激活 mise（fish shell）
mise activate fish | source

# 3. 安装 Python 3.12 并设为全局默认
mise install python@3.12
mise use python@3.12 --global

# 4. 克隆源码
git clone https://github.com/xxx/cmus-auto-lyrics.git
cd cmus-auto-lyrics

# 5. 用 Python 3.12 重新编译
uv sync --all-groups
uv run build.py --nuitka

# 6. 安装到 PATH
cp dist/cmus-auto-lyrics ~/.local/bin/
```

### 关键点

- **不要用 AUR 的二进制包**，它的编译环境绑死了 Python 3.14
- **不要直接用 pip/nuitka** 在当前 Python 上编，用 uv 管理依赖更干净
- 编译产物放到 `~/.local/bin/`，确保这个路径在 `$PATH` 里

## 🔄 使用方式

`cmus-auto-lyrics` 不是 cmus 插件，是独立程序。需要和 cmus 同时运行：

```bash
# 方式一：tmux 分屏（推荐）
tmux new-session -s cmus -d 'cmus'
tmux split-window -h -l 40 'cmus-auto-lyrics'
tmux attach -t cmus

# 方式二：单独终端
cmus-auto-lyrics
```

## 📦 依赖

| 组件 | 用途 | 安装来源 |
|------|------|----------|
| [mise](https://mise.jdx.dev/) | Python 版本管理 | `pacman -S mise` |
| [uv](https://docs.astral.sh/uv/) | Python 包管理 + 虚拟环境 | `pacman -S uv` |
| [cmus](https://cmus.github.io/) | 终端音乐播放器 | `pacman -S cmus` |

## ⚠️ 注意事项

1. **mise 激活** — fish 用户需要在 `~/.config/fish/config.fish` 里加 `mise activate fish | source`，否则 `mise use` 不生效
2. **usage 补全包** — `pacman -S usage`，否则 mise 启动时会报 `usage CLI not found`（不影响核心功能，但烦人）
3. **Python 版本共存** — mise 管理的 Python 和系统 Python 互不干扰，不用担心搞坏系统
4. **AUR 包上游问题** — 已确认是 PKGBUILD 的 Python 版本选择问题，可向维护者提 issue 建议改用 `python@3.12` 或添加版本检测逻辑
