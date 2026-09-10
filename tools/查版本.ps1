# ============================================================
#  NeutralinoJS 运行时版本查看器
#  用法: 把 exe 拖到「查版本.bat」图标上 (支持多个)
#  查询后: 空回车 = 弹出文件选择框继续查, 输入 q = 退出
# ============================================================
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Files
)

function Pick-Files {
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "可执行文件 (*.exe)|*.exe|所有文件 (*.*)|*.*"
    $dlg.Title = "选择要查看版本的文件"
    $dlg.Multiselect = $true
    if ($dlg.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
    return @($dlg.FileNames)
}

function Show-Usage {
    Write-Host ""
    Write-Host "  未检测到拖入的文件" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  使用方法: 把要查看的 exe 文件直接拖到「查版本.bat」图标上"
    Write-Host "  支持一次拖入多个文件"
}

function Show-Version {
    param([string[]]$Targets)
    foreach ($f in $Targets) {
        Write-Host ""
        Write-Host ("=" * 60)
        Write-Host "文件: $f"
        if (-not (Test-Path -LiteralPath $f)) {
            Write-Host "  [错误] 文件不存在" -ForegroundColor Red
            continue
        }
        try {
            $bytes = [IO.File]::ReadAllBytes($f)
        } catch {
            Write-Host "  [错误] 无法读取: $($_.Exception.Message)" -ForegroundColor Red
            continue
        }

        # 1) 标准 PE 版本资源 (一般 Neutralino 运行时没有)
        $vi = (Get-Item -LiteralPath $f).VersionInfo
        if ($vi.FileVersion) {
            Write-Host ("  PE 版本资源   : " + $vi.FileVersion)
        } else {
            Write-Host "  PE 版本资源   : (无)"
        }

        # 2) 二进制内嵌的 NeutralinoJS 版本
        $text = [Text.Encoding]::ASCII.GetString($bytes)
        $ver = $null
        $commit = $null

        # 布局一: 版本号紧跟在 var NL_VERSION 模板之前
        $m = [regex]::Match($text, "([0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?)\x00+var NL_VERSION")
        if ($m.Success) { $ver = $m.Groups[1].Value }
        if (-not $ver) {
            # 布局二: 版本号在 var NL_VERSION=' 之后
            $m2 = [regex]::Match($text, "var NL_VERSION='\x00*([0-9]+\.[0-9]+\.[0-9]+)")
            if ($m2.Success) { $ver = $m2.Groups[1].Value }
        }
        $mc = [regex]::Match($text, "([0-9a-f]{40})\x00+var NL_COMMIT")
        if ($mc.Success) { $commit = $mc.Groups[1].Value }

        if ($ver) {
            Write-Host ("  NeutralinoJS  : " + $ver) -ForegroundColor Green
            if ($commit) { Write-Host ("  Commit        : " + $commit) }
        } elseif ($text.Contains("var NL_VERSION")) {
            Write-Host "  NeutralinoJS  : 检测到标记但未能解析版本号" -ForegroundColor Yellow
        } else {
            Write-Host "  NeutralinoJS  : 未检测到 (可能不是 NeutralinoJS 运行时)" -ForegroundColor Yellow
        }
    }
}

# ---------------- 主流程 ----------------
if ($env:VERCHECK_NOPAUSE -eq "1") {
    # 自动化模式: 只处理传入的文件后直接退出
    if ($Files -and $Files.Count -gt 0) { Show-Version $Files }
    exit 0
}

$pending = $Files
while ($true) {
    if (-not $pending -or $pending.Count -eq 0) {
        Show-Usage
    } else {
        Show-Version $pending
    }

    $ans = Read-Host "按回车选择文件继续 (可输入文件路径, 输入 q 退出)"
    if ($ans -match '^\s*q\s*$') { exit 0 }
    $ans = $ans.Trim()
    if ($ans -eq '') {
        # 空回车: 弹出文件选择框
        $picked = Pick-Files
        if ($picked) { $pending = $picked } else { $pending = @() }
    } elseif (Test-Path -LiteralPath $ans) {
        # 输入的是存在的路径: 直接当作要查的文件
        if ((Get-Item -LiteralPath $ans).PSIsContainer) {
            # 是目录: 列出其中的 exe
            $exes = @(Get-ChildItem -LiteralPath $ans -Filter *.exe | ForEach-Object { $_.FullName })
            if ($exes.Count -gt 0) {
                $pending = $exes
            } else {
                Write-Host "  目录下没有 exe 文件" -ForegroundColor Yellow
                $pending = @()
            }
        } else {
            $pending = @($ans)
        }
    } else {
        Write-Host "  路径不存在: $ans" -ForegroundColor Red
        $pending = @()
    }
}
