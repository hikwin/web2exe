[CmdletBinding()]
param(
    [string]$Version = "",
    [switch]$WinOnly,
    [switch]$AllPlatforms,
    [switch]$ForceMirror
)

# 确保在 UTF-8 (65001) 下中文字符输出正常无重影
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# 控制台格式化输出
function Write-Info([string]$msg) {
    Write-Host "[信息] $msg" -ForegroundColor Cyan
}
function Write-Success([string]$msg) {
    Write-Host "[成功] $msg" -ForegroundColor Green
}
function Write-Warn([string]$msg) {
    Write-Host "[提示] $msg" -ForegroundColor Yellow
}
function Write-Err([string]$msg) {
    Write-Host "[错误] $msg" -ForegroundColor Red
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      NeutralinoJS bin 核心运行文件更新工具       " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 1. 检测当前本地版本
$currentVersion = "未知"
$localNeuJs = Join-Path $ScriptDir "resources\js\neutralino.js"
if (Test-Path $localNeuJs) {
    $content = Get-Content $localNeuJs -Raw -ErrorAction SilentlyContinue
    if ($content -match 'NL_CVERSION\s*=\s*"([^"]+)"') {
        $currentVersion = "v" + $matches[1]
    }
}
Write-Info "当前本地运行时版本: $currentVersion"

# 2. 获取最新版本号
function Get-LatestReleaseTag() {
    $apiUrl = "https://api.github.com/repos/neutralinojs/neutralinojs/releases/latest"
    $headers = @{ "User-Agent" = "Neutralino-Updater-Script" }
    
    # 尝试直连 GitHub API
    try {
        $resp = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 6 -ErrorAction Stop
        if ($resp.tag_name) {
            return $resp.tag_name.Trim()
        }
    } catch {}

    # 备用源: 从国内镜像获取 GitHub 最新 release
    $mirrors = @("https://ghproxy.net/", "https://gh-proxy.com/")
    foreach ($m in $mirrors) {
        try {
            $mirrorApi = "$m$apiUrl"
            $resp = Invoke-RestMethod -Uri $mirrorApi -Headers $headers -TimeoutSec 6 -ErrorAction Stop
            if ($resp.tag_name) {
                return $resp.tag_name.Trim()
            }
        } catch {}
    }

    return ""
}

$targetTag = $Version
if ([string]::IsNullOrWhiteSpace($targetTag)) {
    Write-Host "正在查询 GitHub 最新可用版本..." -ForegroundColor Gray
    $latestTag = Get-LatestReleaseTag
    if ($latestTag) {
        Write-Success "检测到 GitHub 最新版本: $latestTag"
        Write-Host ""
        $userChoice = Read-Host "按回车(Enter)直接更新到最新版本 $latestTag，或输入指定版本号(例如 v6.9.0)"
        if ([string]::IsNullOrWhiteSpace($userChoice)) {
            $targetTag = $latestTag
        } else {
            $targetTag = $userChoice.Trim()
            if (-not $targetTag.StartsWith("v")) { $targetTag = "v" + $targetTag }
        }
    } else {
        Write-Warn "未能从 GitHub 自动获取最新版本号（网络受限）。"
        $targetTag = Read-Host "请输入要下载的版本号 [默认: v6.9.0]"
        if ([string]::IsNullOrWhiteSpace($targetTag)) {
            $targetTag = "v6.9.0"
        }
        if (-not $targetTag.StartsWith("v")) { $targetTag = "v" + $targetTag }
    }
} else {
    if (-not $targetTag.StartsWith("v")) { $targetTag = "v" + $targetTag }
}

Write-Info "即将更新的目标版本: $targetTag"

# 3. 平台选择（仅 Windows 还是全平台）
$keepWinOnly = $false
if ($WinOnly) {
    $keepWinOnly = $true
} elseif ($AllPlatforms) {
    $keepWinOnly = $false
} else {
    Write-Host ""
    Write-Host "请选择需要更新的文件类型:" -ForegroundColor White
    Write-Host "  [1] 仅更新 Windows 运行文件 (推荐: 仅保留 neutralino-win_x64.exe，体积最小约 2.4MB)" -ForegroundColor Green
    Write-Host "  [2] 更新全部平台运行文件 (包含 Windows、Mac、Linux 全部 7 个运行核心)" -ForegroundColor White
    $platChoice = Read-Host "请输入序号 [默认 1]"
    if ($platChoice -eq "2") {
        $keepWinOnly = $false
    } else {
        $keepWinOnly = $true
    }
}

# 4. 下载逻辑（支持直连与镜像无缝降级）
function Download-FileWithFallback([string]$rawUrl, [string]$destination) {
    $urls = @($rawUrl)
    if ($ForceMirror) {
        $urls = @(
            "https://ghproxy.net/$rawUrl",
            "https://gh-proxy.com/$rawUrl",
            $rawUrl
        )
    } else {
        $urls = @(
            $rawUrl,
            "https://ghproxy.net/$rawUrl",
            "https://gh-proxy.com/$rawUrl"
        )
    }

    $downloaded = $false
    foreach ($u in $urls) {
        try {
            Write-Host "  正在下载: $u" -ForegroundColor Gray
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $u -OutFile $destination -TimeoutSec 30 -ErrorAction Stop
            if ((Test-Path $destination) -and ((Get-Item $destination).Length -gt 1024)) {
                $downloaded = $true
                break
            }
        } catch {
            Write-Warn "  当前下载节点超时或失败，正在切换下一镜像加速节点..."
        }
    }

    if (-not $downloaded) {
        throw "无法从任何节点下载 $rawUrl，请检查网络连接。"
    }
}

# 5. 准备临时目录
$tmpDir = Join-Path $ScriptDir ".tmp_neu_update"
if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
New-Item -Path $tmpDir -ItemType Directory | Out-Null

try {
    # 下载核心二进制 zip
    $binZipName = "neutralinojs-$targetTag.zip"
    $binZipUrl = "https://github.com/neutralinojs/neutralinojs/releases/download/$targetTag/$binZipName"
    $binZipLocal = Join-Path $tmpDir $binZipName

    Write-Info "开始下载 Neutralinojs 核心运行包 ($binZipName)..."
    Download-FileWithFallback $binZipUrl $binZipLocal
    $zipSize = [math]::Round((Get-Item $binZipLocal).Length / 1MB, 2)
    Write-Success "核心运行包下载完成 ($zipSize MB)"

    # 解压二进制包
    Write-Info "正在解压二进制文件..."
    $unzipDir = Join-Path $tmpDir "extracted"
    Expand-Archive -Path $binZipLocal -DestinationPath $unzipDir -Force

    # 下载配套客户端 neutralino.js 和 neutralino.d.ts
    Write-Info "正在下载配套客户端脚本 neutralino.js..."
    $jsUrl = "https://github.com/neutralinojs/neutralino.js/releases/download/$targetTag/neutralino.js"
    $jsLocal = Join-Path $tmpDir "neutralino.js"
    Download-FileWithFallback $jsUrl $jsLocal

    Write-Info "正在下载配套 TypeScript 定义文件 neutralino.d.ts..."
    $dtsUrl = "https://github.com/neutralinojs/neutralino.js/releases/download/$targetTag/neutralino.d.ts"
    $dtsLocal = Join-Path $tmpDir "neutralino.d.ts"
    try {
        Download-FileWithFallback $dtsUrl $dtsLocal
    } catch {
        Write-Warn "TypeScript 声明文件未找到或下载失败，跳过。"
    }

    # 6. 备份与替换 bin/ 目录
    $binDir = Join-Path $ScriptDir "bin"
    if (-not (Test-Path $binDir)) {
        New-Item -Path $binDir -ItemType Directory | Out-Null
    } else {
        $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $backupDir = Join-Path $ScriptDir "bin_backup_$timestamp"
        Write-Info "正在备份原 bin 目录到: bin_backup_$timestamp"
        Copy-Item -Path $binDir -Destination $backupDir -Recurse -Force
    }

    # 写入新 bin 文件
    Write-Info "正在更新 bin 目录..."
    $extractedFiles = Get-ChildItem -Path $unzipDir -File

    if ($keepWinOnly) {
        # 清空原 bin，仅保留 Windows
        Get-ChildItem -Path $binDir -File | Remove-Item -Force
        $winBin = $extractedFiles | Where-Object { $_.Name -like "*win_x64.exe" }
        if ($winBin) {
            Copy-Item -Path $winBin.FullName -Destination $binDir -Force
            Write-Success "已成功安装 Windows 64位核心: $($winBin.Name)"
        } else {
            throw "解压文件中未找到 Windows 运行程序 neutralino-win_x64.exe！"
        }
    } else {
        # 保留全平台
        foreach ($f in $extractedFiles) {
            Copy-Item -Path $f.FullName -Destination $binDir -Force
        }
        Write-Success "已成功安装全平台 (Win, Linux, Mac) 共 $($extractedFiles.Count) 个运行核心！"
    }

    # 7. 更新 client library (resources/js/neutralino.js)
    $resJsDir = Join-Path $ScriptDir "resources\js"
    if (-not (Test-Path $resJsDir)) { New-Item -Path $resJsDir -ItemType Directory -Force | Out-Null }
    if (Test-Path $jsLocal) {
        Copy-Item -Path $jsLocal -Destination $resJsDir -Force
        Write-Success "已更新根目录: resources\js\neutralino.js"
    }
    if (Test-Path $dtsLocal) {
        Copy-Item -Path $dtsLocal -Destination $resJsDir -Force
        Write-Success "已更新根目录: resources\js\neutralino.d.ts"
    }

    # 同步更新子项目（例如“图搜”目录）
    $subProjJs = Join-Path $ScriptDir "图搜\resources\js\neutralino.js"
    if (Test-Path $subProjJs) {
        Copy-Item -Path $jsLocal -Destination $subProjJs -Force
        Write-Success "已同步更新子项目: 图搜\resources\js\neutralino.js"
    }
    $subProjDts = Join-Path $ScriptDir "图搜\resources\js\neutralino.d.ts"
    if ((Test-Path $subProjDts) -and (Test-Path $dtsLocal)) {
        Copy-Item -Path $dtsLocal -Destination $subProjDts -Force
        Write-Success "已同步更新子项目: 图搜\resources\js\neutralino.d.ts"
    }

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host "            ★ 全部文件更新成功！★               " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    Write-Info "当前 bin 目录列表:"
    Get-ChildItem -Path $binDir -File | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  - $($_.Name) ($sizeMB MB)" -ForegroundColor White
    }
    Write-Host ""

} catch {
    Write-Err "更新过程中发生错误: $_"
} finally {
    if (Test-Path $tmpDir) {
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
