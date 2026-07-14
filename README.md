# Ranch Arch Linux Scripts 🐧

我在 Arch Linux 日常使用中遇到的问题，以及对应的脚本和处理方法。

每个问题都有独立的子目录，内含详细说明、脚本内容和使用方式。

---

## 📂 目录

| 问题 | 描述 | 文档 |
|------|------|------|
| **DMS + Matugen 配色同步** | 换壁纸时自动将 Material You 配色推送到 Firefox、Kitty、GTK 等应用 | [`dms-matugen-setup/`](dms-matugen-setup/) |
| **fcitx5 输入法** | 输入法失效自动恢复 + 候选框字体调大 | [`fcitx5/`](fcitx5/) |
| **cmus-auto-lyrics** | AUR 包 Python 3.14 兼容修复 + 编译方法 | [`cmus-auto-lyrics/`](cmus-auto-lyrics/) |

> 📌 持续更新中 — 遇到新问题就会加进来。

---

## 🏗 仓库结构

```
Ranch-ArchLinux-Scripts/
├── README.md              ← 你现在看到的导航页
├── LICENSE                ← MIT 许可证
└── <problem-name>/        ← 每个问题一个子目录
    ├── README.md          ← 问题描述、解决思路、使用方式
    ├── <script>.sh        ← 脚本（如果有）
    └── ...                ← 其他相关文件
```

当前仓库：

```
Ranch-ArchLinux-Scripts/
├── README.md
├── LICENSE
├── dms-matugen-setup/
│   ├── README.md
│   └── dms-matugen-setup.sh
└── fcitx5/
    ├── README.md
    ├── niri-config-env.kdl
    ├── fcitx5.service
    └── classicui.conf
└── cmus-auto-lyrics/
    └── README.md
```

---

## 📄 License

[MIT](LICENSE) © 2026 Ranch
