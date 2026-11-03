# DeepSeek Harness 启动动画

双击桌面上的 **DeepSeek Harness** 快捷方式，会先全屏播放一段 ~3 秒的启动动画，
然后客户端窗口接管。动画使用官方鲸鱼标志和 Montserrat 品牌字体，深色深海底色 +
声呐扩散环 + 光扫字标。

**没有改动 `F:\deepseek\resources\app.asar`**，所以随时可以整段撤销。

## 播放效果

| 阶段 | 时间 | 内容 |
| --- | --- | --- |
| 入场 | 0–0.6 s | 深海蓝背景、光晕、上浮粒子淡入 |
| 徽标 | 0.1–0.9 s | 鲸鱼标志由模糊拉近、光晕呼吸 |
| 字标 | 0.5–1.6 s | "DeepSeek Harness" 逐字母浮现 |
| 光扫 | 1.5–2.7 s | 一道高光扫过字标，进度条走满 |
| 交接 | 2.9 s | 客户端窗口出现后动画窗口自动关闭 |

## 文件

| 文件 | 作用 |
| --- | --- |
| `index.html` | 动画本体（纯 HTML/CSS/JS，无依赖） |
| `emblem.svg` | 从品牌资源里裁出的鲸鱼标志 |
| `launch.ps1` | 全屏播放 → 定时启动客户端 → 收尾清理 |
| `start-silent.vbs` | 用隐藏窗口调 `launch.ps1`，避免黑框闪一下 |
| `install.ps1` | 创建桌面 / 开始菜单快捷方式（`-Uninstall` 撤销） |
| `build_assets.py` | 从 `brand/` 重新生成 `emblem.svg` 和字体副本 |
| `preview.gif` / `preview-final.png` | 效果预览 |

## 安装 / 卸载

```powershell
# 安装快捷方式（桌面 + 开始菜单）
powershell -ExecutionPolicy Bypass -File .\install.ps1

# 卸载快捷方式
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

卸载后把本文件夹删掉即可完全恢复原状。

## 常用调整

- **只预览动画、不启动客户端**：`powershell -File .\launch.ps1 -NoApp`
- **让动画停在屏幕上调试**：`powershell -File .\launch.ps1 -NoApp -KeepOpen`，
  之后用任务管理器结束 `msedge.exe`，或在本页按 `Esc`。
- **客户端的实际路径不同**：`.\launch.ps1 -AppPath "D:\...\DeepSeek Harness.exe"`，
  或改 `install.ps1` 里的 `-AppPath`。不传时会在 `F:\deepseek\` 和常见安装目录里自动找。
- **节奏太快 / 太慢**：`launch.ps1` 顶部三个常量
  `$AppStartMs`（何时启动客户端）、`$EarliestEnd`（动画最少放多久）、
  `$LatestEnd`（最多等客户端窗口多久）。
- **文案**：`index.html` 里 `.tagline` 的三个阶段文案在脚本末尾的 `stages` 数组。
- **配色**：`index.html` 里 `.stage` 的背景渐变和 `.progress i` 的蓝色渐变。
- **冻结某一帧看效果**：`index.html?t=1800`（毫秒），用于截图对比。

## 已知限制

- 动画由系统自带的 Edge（或 Chrome）渲染，首次播放要等浏览器冷启动，约多 0.6–1 s；
  之后用同一份临时配置（`%LOCALAPPDATA%\DSH-Splash\browser-profile`）会更快。
- 只有这个快捷方式会播放动画。开始菜单搜索、任务栏固定项如果指向
  `DeepSeek Harness.exe` 本体，仍然是原来的直接启动方式——想统一可以把那些快捷方式
  也指向 `start-silent.vbs`。
- 客户端升级不会影响动画（它不在 `app.asar` 里），但如果安装目录变了，
  用 `-AppPath` 或让 `launch.ps1` 自动探测。
