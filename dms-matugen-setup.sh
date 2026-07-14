#!/bin/bash
# ═══════════════════════════════════════════════════
# DMS + Matugen + Pywalfox + Kitty 全自动配置脚本
# 全自动坐好版 —— 检测 → 自动安装 → 配置 → 验证
# ═══════════════════════════════════════════════════
set -euo pipefail

# ─── 颜色输出 ──────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m' # No Color
info()  { echo -e "${CYAN}ℹ${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
err()   { echo -e "${RED}✗${NC} $1"; }
header(){ echo -e "\n${CYAN}════════════════════════════════════════${NC}"; echo -e "${CYAN} $1${NC}"; echo -e "${CYAN}════════════════════════════════════════${NC}"; }

# ─── 需要安装的软件 ─────────────────────────────────
# 格式: 包名|可执行文件|安装命令提示
REQUIRED_PKG=(
    "python-pywalfox|pywalfox|pywalfox (Firefox 主题桥接)"
    "matugen-bin|matugen|Matugen (Material You 颜色生成器)"
    "quickshell-git|quickshell|Quickshell/DMS 桌面环境"
    "kitty|kitty|Kitty 终端"
)

# Debian/Ubuntu 下 pywalfox 走 pip, matugen 无官方包
REQUIRED_PKG_APT=(
    "|pywalfox|pywalfox (需 pip install pywalfox)"
    "|matugen|Matugen (需 cargo install matugen)"
    "|quickshell|Quickshell/DMS (需编译安装)"
)

# ─── 第一步：检测系统 ─────────────────────────────
detect_system() {
    header "① 系统检测"

    # 包管理器
    if   command -v pacman &>/dev/null; then PM="pacman"
    elif command -v apt    &>/dev/null; then PM="apt"
    elif command -v dnf    &>/dev/null; then PM="dnf"
    elif command -v zypper &>/dev/null; then PM="zypper"
    else PM="unknown"; fi
    info "包管理器: $PM"

    # AUR helper (仅 Arch)
    AUR_HELPER=""
    if command -v yay &>/dev/null; then AUR_HELPER="yay"
    elif command -v paru &>/dev/null; then AUR_HELPER="paru"; fi
    [ -n "$AUR_HELPER" ] && ok "AUR helper: $AUR_HELPER" || warn "未检测到 AUR helper"

    # 已安装的软件
    INSTALLED=""
    MISSING=""
    case "$PM" in
        pacman)
            # pacman + AUR
            for entry in "${REQUIRED_PKG[@]}"; do
                pkg="${entry%%|*}"; bin="${entry#*|}"; bin="${bin%%|*}"; desc="${entry##*|}"
                if command -v "${bin}" &>/dev/null; then
                    ok "$desc 已就绪"
                    INSTALLED="$INSTALLED $pkg"
                else
                    warn "$desc 未安装"
                    MISSING="$MISSING $pkg|$bin"
                fi
            done
            ;;
        apt)
            # apt + pip/cargo
            # pywalfox via pip, matugen via cargo, quickshell from source
            for bin in pywalfox matugen quickshell kitty; do
                desc=""; case $bin in pywalfox) desc="pywalfox";; matugen) desc="Matugen";; quickshell) desc="Quickshell/DMS";; kitty) desc="Kitty";; esac
                if command -v "$bin" &>/dev/null; then ok "$desc 已就绪"
                else warn "$desc 未安装"; MISSING="$MISSING |$bin"; fi
            done
            ;;
        *)
            warn "暂不支持 $PM 的自动安装，将跳过安装步骤"
            SKIP_INSTALL=1
            for entry in "${REQUIRED_PKG[@]}"; do
                bin="${entry#*|}"; bin="${bin%%|*}"; desc="${entry##*|}"
                if ! command -v "${bin}" &>/dev/null; then MISSING="$MISSING |$bin"; fi
            done
            ;;
    esac
}

# ─── 第二步：安装缺失软件 ─────────────────────────
install_missing() {
    [ -z "$MISSING" ] && { info "所有软件已就绪，跳过安装"; return; }
    [ "${SKIP_INSTALL:-0}" = 1 ] && { warn "跳过自动安装，请手动安装缺失软件"; return; }

    header "② 自动安装缺失软件"

    case "$PM" in
        pacman)
            # 先装 pacman 官方源里的
            OFFICIAL=""
            AUR_PKGS=""
            for entry in $MISSING; do
                pkg="${entry%%|*}"
                case "$pkg" in
                    kitty) OFFICIAL="$OFFICIAL kitty" ;;
                    python-pywalfox) AUR_PKGS="$AUR_PKGS python-pywalfox" ;;
                    matugen-bin)     AUR_PKGS="$AUR_PKGS matugen-bin" ;;
                    quickshell-git)  AUR_PKGS="$AUR_PKGS quickshell-git" ;;
                esac
            done

            # 官方源
            if [ -n "$OFFICIAL" ]; then
                info "安装官方源包: $OFFICIAL"
                sudo pacman -S --needed --noconfirm $OFFICIAL
                ok "官方源包安装完成"
            fi

            # AUR
            if [ -n "$AUR_PKGS" ]; then
                if [ -z "$AUR_HELPER" ]; then
                    warn "未检测到 yay/paru，跳过 AUR 包安装"
                    warn "请手动运行:"
                    for p in $AUR_PKGS; do warn "  paru -S $p  或  yay -S $p"; done
                else
                    info "从 AUR 安装: $AUR_PKGS"
                    $AUR_HELPER -S --needed --noconfirm $AUR_PKGS
                    ok "AUR 包安装完成"
                fi
            fi
            ;;
        apt)
            sudo apt update
            info "安装 kitty..."
            sudo apt install -y kitty 2>/dev/null || warn "kitty 安装失败，请手动: sudo apt install kitty"
            info "安装 pywalfox (pip)..."
            pip3 install --user pywalfox 2>/dev/null && ok "pywalfox 安装完成" || warn "pip install pywalfox 失败，请手动安装"
            info "安装 matugen (cargo)..."
            cargo install matugen 2>/dev/null && ok "matugen 安装完成" || warn "cargo install matugen 失败，请手动安装"
            info "注意: DMS/Quickshell 在非 Arch 系统上需手动编译安装"
            ;;
    esac

    # 验证安装
    STILL_MISSING=""
    for entry in "${REQUIRED_PKG[@]}"; do
        bin="${entry#*|}"; bin="${bin%%|*}"
        if ! command -v "$bin" &>/dev/null; then STILL_MISSING="$STILL_MISSING $bin"; fi
    done
    if [ -n "$STILL_MISSING" ]; then
        warn "以下软件仍未安装: $STILL_MISSING"
        warn "请手动安装后再运行本脚本"
        echo ""
        warn "Arch Linux:"
        warn "  paru -S python-pywalfox matugen-bin quickshell-git kitty"
        warn "Debian/Ubuntu:"
        warn "  sudo apt install kitty"
        warn "  pip3 install --user pywalfox"
        warn "  cargo install matugen"
        echo ""
        read -rp "按回车继续配置已安装的部分… "
    fi
}

# ─── 第三步：确认 pywalfox 扩展已安装 ──────────────
check_pywalfox_extension() {
    header "③ 检测 pywalfox 浏览器扩展"

    # 检查 native messaging manifest
    local manifest="$HOME/.mozilla/native-messaging-hosts/pywalfox.json"
    if [ -f "$manifest" ]; then
        ok "pywalfox native messaging 已注册"
    else
        warn "pywalfox native messaging 未注册"
        info "正在注册..."
        pywalfox install 2>/dev/null && ok "注册成功" || warn "注册失败，请手动运行: pywalfox install"
    fi

    # 检查 pywalfox daemon 是否在运行
    if pgrep -f "pywalfox start" &>/dev/null; then
        ok "pywalfox daemon 运行中"
    else
        warn "pywalfox daemon 未运行，尝试启动..."
        pywalfox start &>/dev/null &
        sleep 1
        if pgrep -f "pywalfox start" &>/dev/null; then
            ok "pywalfox daemon 已启动"
        else
            warn "pywalfox daemon 启动失败，请手动运行: pywalfox start"
        fi
    fi

    echo ""
    info "请确保 Firefox 已安装 Pywalfox 扩展:"
    info "  https://addons.mozilla.org/firefox/addon/pywalfox/"
    echo ""
    read -rp "按回车继续… "
}

# ─── 第四步：配置 matugen 模板 ────────────────────
setup_matugen() {
    header "④ 配置 Matugen 模板和自动流程"

    local tmpl_dir="$HOME/.config/matugen/templates"
    local cfg_file="$HOME/.config/matugen/config.toml"
    mkdir -p "$tmpl_dir"

    # 4a. 写入 pywalfox-colors.json 模板
    if [ -f "$tmpl_dir/pywalfox-colors.json" ]; then
        info "pywalfox 模板已存在，跳过"
    else
        info "写入 pywalfox 模板..."
        cat > "$tmpl_dir/pywalfox-colors.json" << 'TMPL'
{
  "wallpaper": "{{image}}",
  "alpha": "100",
  "special": {
    "background": "{{colors.background.dark.hex}}",
    "foreground": "{{colors.on_background.dark.hex}}",
    "cursor": "{{colors.on_background.dark.hex}}"
  },
  "colors": {
    "color0":  "{{colors.background.dark.hex}}",
    "color1":  "{{colors.error.dark.hex}}",
    "color2":  "{{colors.tertiary.dark.hex}}",
    "color3":  "{{colors.primary.default.hex}}",
    "color4":  "{{colors.secondary.default.hex}}",
    "color5":  "{{colors.tertiary_container.default.hex}}",
    "color6":  "{{colors.surface_bright.dark.hex}}",
    "color7":  "{{colors.on_surface.dark.hex}}",
    "color8":  "{{colors.surface_dim.dark.hex}}",
    "color9":  "{{colors.error_container.default.hex}}",
    "color10": "{{colors.primary.default.hex}}",
    "color11": "{{colors.primary_container.default.hex}}",
    "color12": "{{colors.secondary_container.default.hex}}",
    "color13": "{{colors.surface_container_highest.default.hex}}",
    "color14": "{{colors.surface_container_low.default.hex}}",
    "color15": "{{colors.on_background.dark.hex}}"
  }
}
TMPL
        ok "pywalfox 模板已写入"
    fi

    # 4b. 追加 pywalfox 段到 matugen config
    # 只在没有这个段的时候追加
    if grep -q 'templates.pywalfox' "$cfg_file" 2>/dev/null; then
        info "matugen config 已包含 pywalfox 配置，跳过"
    else
        # 检查文件是否以换行结尾
        if [ -f "$cfg_file" ] && [ -s "$cfg_file" ]; then
            tail -c1 "$cfg_file" | read -r _ || echo "" >> "$cfg_file"
        fi
        cat >> "$cfg_file" << 'CFG'

[templates.pywalfox]
input_path = '~/.config/matugen/templates/pywalfox-colors.json'
output_path = '~/.cache/wal/colors.json'
post_hook = 'pywalfox update & kitty @ reload-kitty.conf & disown'
CFG
        ok "matugen config 已添加 pywalfox 配置"
    fi

    # 4c. 确认 DMS 内置 pywalfox/kitty 模板已启用
    info "DMS 内置模板状态（如有关闭请手动在设置中开启）:"
    dms matugen check 2>/dev/null | python3 -c "
import json,sys
by_name = {'pywalfox': 'pywalfox', 'kitty': 'kitty', 'firefox': 'firefox'}
found = {i['id']: i['detected'] for i in json.load(sys.stdin)}
for name, label in by_name.items():
    status = '✓ 已启用' if found.get(name) else '✗ 未检测到'
    print(f'  {label}: {status}')
" 2>/dev/null || echo "  (dms matugen check 不可用)"
}

# ─── 第五步：配置 kitty ──────────────────────────
setup_kitty() {
    header "⑤ 配置 Kitty 终端"

    local kitty_conf="$HOME/.config/kitty/kitty.conf"
    local dank_theme="$HOME/.config/kitty/dank-theme.conf"

    # 确保 kitty 配置目录存在
    mkdir -p "$(dirname "$kitty_conf")"

    # 先生成一次 dank-theme.conf（如果文件不存在）
    if [ ! -f "$dank_theme" ] && command -v dms &>/dev/null; then
        info "生成 DMS kitty 主题文件..."
        local wallpaper
        wallpaper=$(dms ipc call wallpaper get 2>/dev/null || echo "")
        if [ -n "$wallpaper" ] && [ -f "$wallpaper" ] && command -v matugen &>/dev/null; then
            info "  正在生成初始配色..."
            matugen image "$wallpaper" -c "$HOME/.config/matugen/config.toml" -m dark --prefer darkness 2>/dev/null || true
        fi
    fi

    # 如果 kitty.conf 不存在，创建最简单的
    if [ ! -f "$kitty_conf" ]; then
        info "创建 kitty.conf..."
        echo "# Kitty 配置文件（由 dms-matugen-setup 生成）" > "$kitty_conf"
    fi

    # 确保 include 顺序正确
    # 1. 去掉所有已有的 dank-theme.conf include
    sed -i '/^include.*dank-theme.conf/d' "$kitty_conf" 2>/dev/null || true
    # 2. 在文件末尾添加（优先级最高）
    echo 'include dank-theme.conf' >> "$kitty_conf"
    ok "kitty 配置已更新（matugen 配色优先）"
}

# ─── 第六步：验证 ─────────────────────────────────
verify() {
    header "⑥ 验证自动化流程"

    local ALL_OK=true

    # 检查 colors.json
    local colors_json="$HOME/.cache/wal/colors.json"
    if [ -f "$colors_json" ]; then
        local count
        count=$(python3 -c "import json; d=json.load(open('$colors_json')); print(len([v for v in d.get('colors',{}).values() if v]))" 2>/dev/null || echo "0")
        if [ "$count" -eq 16 ]; then
            ok "colors.json: $count/16 色填充"
        else
            warn "colors.json 不完整: $count/16 色"
            ALL_OK=false
        fi
    else
        warn "colors.json 不存在，触发一次生成..."
        local wallpaper
        wallpaper=$(dms ipc call wallpaper get 2>/dev/null || echo "")
        if [ -n "$wallpaper" ] && [ -f "$wallpaper" ] && command -v matugen &>/dev/null; then
            matugen image "$wallpaper" -c "$HOME/.config/matugen/config.toml" -m dark --prefer darkness 2>/dev/null || true
        fi
        if [ -f "$colors_json" ]; then
            ok "colors.json 已生成"
        else
            warn "colors.json 仍未能生成"
            ALL_OK=false
        fi
    fi

    # 检查 pywalfox daemon
    if pgrep -f "pywalfox start" &>/dev/null; then
        ok "pywalfox daemon 运行中"
    else
        warn "pywalfox daemon 未运行"
        ALL_OK=false
    fi

    # 检查 kitty 主题
    if [ -f "$HOME/.config/kitty/dank-theme.conf" ]; then
        ok "kitty 主题文件存在"
    else
        warn "kitty 主题文件不存在（DMS 需在下次壁纸变更时生成）"
    fi

    # 检查 DMS matugen 集成
    if command -v dms &>/dev/null && dms matugen check &>/dev/null; then
        ok "DMS matugen 集成正常"
    else
        warn "DMS matugen 集成异常"
        ALL_OK=false
    fi

    echo ""
    if $ALL_OK; then
        ok "${GREEN}全部验证通过！${NC}"
    else
        warn "部分验证未通过，但基本功能可能正常"
    fi
}

# ─── 第七步：打印总结 ─────────────────────────────
summary() {
    header "⑦ 完成！自动化流程如下"

    echo ""
    echo "  ┌──────────────────────────────────────────┐"
    echo "  │  DMS 换壁纸（GUI 或 dms ipc call wallpaper set）│"
    echo "  │         ↓ 自 动 ↓                        │"
    echo "  │  SessionData.setWallpaper()              │"
    echo "  │         ↓ 自 动 ↓                        │"
    echo "  │  dms matugen queue                       │"
    echo "  │    ├─→ ~/.cache/wal/colors.json          │"
    echo "  │    │    ↓ pywalfox update                │"
    echo "  │    │    ↓ Firefox → 变色 ✓               │"
    echo "  │    ├─→ ~/.config/kitty/dank-theme.conf    │"
    echo "  │    │    ↓ kitty reload                   │"
    echo "  │    │    ↓ Kitty → 变色 ✓                 │"
    echo "  │    ├─→ GTK/niri/VS Code … 全部自动更新    │"
	echo "  │    └─→ 你的 btop/cava/fastfetch 模板      │"
    echo "  └──────────────────────────────────────────┘"
    echo ""
    echo "  ${YELLOW}无需手动运行任何脚本！${NC}"
    echo ""
    echo "  Firefox 如果没立即变色:"
    echo "    ① 装好插件 https://addons.mozilla.org/firefox/addon/pywalfox/"
    echo "    ② 按 Ctrl+Alt+F 或在插件弹窗点 Fetch Colors"
    echo ""
    echo "  手动触发一次:  matugen image \"\$(dms ipc call wallpaper get)\" -c ~/.config/matugen/config.toml -m dark --prefer darkness"
    echo ""

    # 在非交互式运行时跳过 pause
    if [ -t 0 ]; then
        read -rp "按回车退出… "
    fi
}

# ─── 主入口 ────────────────────────────────────────
main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   DMS + Matugen + Pywalfox + Kitty           ║${NC}"
    echo -e "${CYAN}║   全自动配置脚本                              ║${NC}"
    echo -e "${CYAN}║   懒人全自动版                                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""

    detect_system
    install_missing
    check_pywalfox_extension
    setup_matugen
    setup_kitty
    verify
    summary
}

main "$@"
