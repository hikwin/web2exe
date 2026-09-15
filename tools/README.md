# 🛠️ 辅助工具箱说明 (Tools Guide)

本目录包含用于对打包后的 EXE 进行**提权配置**和**版本检测**的实用辅助脚本。

---

## 📑 脚本目录与功能概览

| 脚本文件 | 核心作用 | 交互方式 |
| :--- | :--- | :--- |
| **`一键注入管理员权限.bat`** | 为 EXE 注入 UAC 管理员提权清单（requireAdministrator） | 双击弹出文件选择器 / 命令行静默调用 |
| **`查版本.bat`** | 快速检测 EXE 的 PE 属性与 NeutralinoJS 内核版本/Commit | 支持拖拽 EXE / 弹窗选择 / 路径批量查询 |

---

## 1. 🛡️ 一键注入管理员权限 (`一键注入管理员权限.bat`)

### 📌 作用说明
默认情况下，打包出的桌面程序以普通用户权限运行。如果你的应用需要：
- 读写系统受限目录（如 `C:\Program Files`、`C:\Windows` 等）
- 修改 Windows 注册表（Registry）
- 调用系统管理员级命令或底层驱动服务
- 访问特权硬件设备或网络端口

使用此工具可以**在不破坏原程序结构的前提下**，向目标 `.exe` 文件安全写入 Windows 应用程序清单（Manifest），声明 `requireAdministrator` 权限。

### 🚀 使用方法

#### 方式 A：图形化交互（推荐）
1. 双击运行 `一键注入管理员权限.bat`；
2. 在自动弹出的 Windows 文件选择窗口中，选中需要提权的 `.exe` 文件（如 `dist/xxx.exe`）；
3. 点击“打开”，工具会自动完成资源更新并弹出成功提示。

#### 方式 B：命令行/脚本静默调用
```powershell
# 语法：powershell -File patch_manifest.ps1 "目标EXE路径"
powershell -ExecutionPolicy Bypass -File .\patch_manifest.ps1 "..\dist\我的应用.exe"
```

### 💡 效果说明
- 注入完成后，该 EXE 图标右下角会自动出现 Windows **UAC 安全盾牌**标志。
- 用户双击运行时，系统会自动弹出“用户账户控制 (UAC)”窗口请求管理员授权。

---

## 2. 🔍 查版本工具 (`查版本.bat`)

### 📌 作用说明
用于快速查看任何可执行文件（`.exe`）的：
1. **标准 Windows PE 文件版本**（FileVersion / ProductVersion）；
2. **NeutralinoJS 嵌入式内核版本**（如 `v5.5.0`）及源码 Commit 提交哈希。

可用于确认当前打包软件使用的运行核心是否为最新版本、排查不同版本运行时的兼容性问题。

### 🚀 使用方法

#### 方式 A：鼠标拖拽（最快捷）
- 直接把一个或多个 `.exe` 文件**拖拽**到 `查版本.bat` 图标上松开，即可直接在终端窗口中输出详细版本信息。

#### 方式 B：双击交互运行
1. 双击运行 `查版本.bat`；
2. 直接**按回车键**，会弹出 Windows 文件选择器，多选或单选 EXE 文件；
3. 或直接在控制台中粘贴/输入文件路径、文件夹路径（自动扫描目录下所有 exe）。

---

## ⚙️ 底层实现原理与技术细节

1. **`patch_manifest.ps1`**
   - 通过 P/Invoke 动态调用 Windows 核心库 `kernel32.dll` 的 `BeginUpdateResourceW` / `UpdateResourceW` / `EndUpdateResourceW` 原生 API；
   - 将 XML 格式的 `<requestedExecutionLevel level='requireAdministrator' uiAccess='false' />` 清单精准写入 PE 资源的 `RT_MANIFEST (24)` 资源段；
   - 避免使用第三方笨重的重打包工具，原生、安全、极速。

2. **`查版本.ps1`**
   - 读取 PE 文件的 VersionInfo 结构；
   - 对二进制流进行正则匹配检索 `var NL_VERSION` 和 `var NL_COMMIT` 核心标记。

---

## ⚠️ 注意事项
- **文件占用**：注入管理员清单前，请确保目标 EXE 未在运行中，否则会导致写入失败；
- **数字签名**：如果在注入清单之前 EXE 已经签名，注入 Manifest 会导致原数字签名失效，需在注入提权清单**之后**再进行数字签名。
