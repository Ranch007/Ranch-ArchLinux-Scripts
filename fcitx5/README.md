# fcitx5 — 输入法失效自动恢复 & 候选框字体调大

## 问题

### 1. fcitx5 经常失效，需要手动重启

在 **niri (Wayland)** 下，fcitx5 有时会突然无法输入中文或候选框不弹出来，每次都要在终端执行 `fcitx5 -r` 或 `killall fcitx5 && fcitx5` 来恢复。

**原因：**
- 环境变量不完整：缺 `GTK_IM_MODULE` 和 `QT_IM_MODULE`，导致 GTK/QT 应用与 fcitx5 通信异常
- 无自动恢复机制：`spawn-at-startup "fcitx5"` 启动的进程崩溃后不会自动拉起

### 2. 候选框字体太小

在高分辨率屏幕上，fcitx5 的候选文字太小（默认 `Sans Serif 11`），且改不了。

**原因：**
- `classicui.conf` 中字体设得太小
- 使用了 `Theme=Matugen` 时可能在 Wayland 下不生效

---

## 解决方案

### 方案概览

```
fcitx5/
├── README.md                          ← 本文档
├── niri-config-env.kdl                ← 需添加到 niri 配置中的环境变量
├── fcitx5.service                     ← systemd user 服务单元文件
└── classicui.conf                     ← 候选框字体 / 主题配置
```

### 1️⃣ niri 环境变量配置

在 `~/.config/niri/config.kdl` 的 `environment {}` 块中添加：

```kdl
environment {
    LANGUAGE "zh_CN:en"
    LANG "zh_CN.UTF-8"
    XMODIFIERS "@im=fcitx"
    QT_IM_MODULES "wayland;fcitx"
    GTK_IM_MODULE "fcitx"
    QT_IM_MODULE  "fcitx"
    // ... 其他环境变量
}
```

> 参考文件：[`niri-config-env.kdl`](niri-config-env.kdl)

同时**删除** `spawn-at-startup "fcitx5"` 这一行，改用 systemd 管理。

### 2️⃣ systemd user 服务（自动重启）

创建 `~/.config/systemd/user/fcitx5.service`：

```ini
[Unit]
Description=fcitx5 input method
After=graphical-session-pre.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/fcitx5 --replace
Restart=always
RestartSec=3

[Install]
WantedBy=graphical-session.target
```

> 参考文件：[`fcitx5.service`](fcitx5.service)

启用并启动：

```bash
systemctl --user daemon-reload
systemctl --user enable --now fcitx5
```

> **`Restart=always`** 是关键：无论 fcitx5 因何退出（崩溃 / 正常退出 / 被杀），systemd 都会在 3 秒后自动拉起。

### 3️⃣ 候选框字体调大

编辑 `~/.config/fcitx5/conf/classicui.conf`，增大字体并可选去掉 Matugen 主题：

```ini
Font="Sans Serif 16"
MenuFont="Sans Serif 14"
TrayFont="Sans Serif 14"
# 如果 Matugen 主题不生效，换回 default
Theme=default
```

> 参考文件：[`classicui.conf`](classicui.conf)

修改后重启 fcitx5：

```bash
systemctl --user restart fcitx5
```

---

## 快速执行

一条命令全部搞定（在你的真实终端执行）：

```bash
# 1. 补全 niri 环境变量
sed -i '/QT_IM_MODULES.*wayland;fcitx/a\    GTK_IM_MODULE "fcitx"\n    QT_IM_MODULE  "fcitx"' ~/.config/niri/config.kdl

# 2. 删除旧的 spawn-at-startup
sed -i '/spawn-at-startup "fcitx5"/d' ~/.config/niri/config.kdl

# 3. 创建 systemd 服务
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/fcitx5.service << 'EOF'
[Unit]
Description=fcitx5 input method
After=graphical-session-pre.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/fcitx5 --replace
Restart=always
RestartSec=3

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now fcitx5

# 4. 调大候选框字体
sed -i 's/Font="Sans Serif 11"/Font="Sans Serif 16"/' ~/.config/fcitx5/conf/classicui.conf
sed -i 's/MenuFont="Sans Serif 10"/MenuFont="Sans Serif 14"/' ~/.config/fcitx5/conf/classicui.conf
sed -i 's/TrayFont="Sans Serif 10"/TrayFont="Sans Serif 14"/' ~/.config/fcitx5/conf/classicui.conf

systemctl --user restart fcitx5
```

> ⚠️ 执行前请确认 `~/.config/niri/config.kdl` 中的 `environment {}` 块包含 `QT_IM_MODULES` 这一行，sed 命令会在这行之后插入新的环境变量。
>
> ⚠️ 执行后需要**注销重新登录**或重启 niri 会话，新的环境变量才能生效。

---

## 验证

```bash
# 检查 systemd 服务是否在运行
systemctl --user status fcitx5 --no-pager -l | head -5
# 应显示 Active: active (running)

# 检查环境变量是否生效
echo $GTK_IM_MODULE  # 应输出 fcitx
echo $QT_IM_MODULE   # 应输出 fcitx
```
