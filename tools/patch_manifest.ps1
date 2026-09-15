# ==============================================================================
# Windows EXE 应用程序清单 (Manifest) 管理员提权注入工具 (PowerShell 独立图形界面版)
# 功能：运行后自动弹出文件选择框选择 EXE 文件；亦可作为命令行参数传入直接处理
# ==============================================================================

param (
    [string]$TargetExe = ""
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 引入 Windows kernel32 资源更新底层 API
$Win32Definition = @"
using System;
using System.Runtime.InteropServices;

public class ManifestPatcher {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr BeginUpdateResourceW(string pFileName, bool bDeleteExistingResources);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool UpdateResourceW(IntPtr hUpdate, IntPtr lpType, IntPtr lpName, ushort wLanguage, byte[] lpData, uint cbData);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool EndUpdateResourceW(IntPtr hUpdate, bool fDiscard);
}
"@

try {
    Add-Type -TypeDefinition $Win32Definition -Language CSharp
} catch {
    # 避免重复加载时报错
}

function Patch-ExeManifest {
    param (
        [string]$ExePath,
        [bool]$Silent = $false
    )

    if (-not (Test-Path $ExePath)) {
        if (-not $Silent) {
            [System.Windows.Forms.MessageBox]::Show("找不到指定的 EXE 文件：`n$ExePath", "文件错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        } else {
            Write-Error "找不到指定的 EXE 文件: $ExePath"
        }
        return $false
    }

    # requireAdministrator 应用程序清单 XML
    $ManifestXml = @"
<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<assembly xmlns='urn:schemas-microsoft-com:asm.v1' manifestVersion='1.0'>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level='requireAdministrator' uiAccess='false' />
      </requestedPrivileges>
    </security>
  </trustInfo>
</assembly>
"@

    $Utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($ManifestXml)
    $FullExePath = (Resolve-Path $ExePath).Path

    # 1. 打开 PE 文件资源区
    $hUpdate = [ManifestPatcher]::BeginUpdateResourceW($FullExePath, $false)
    if ($hUpdate -eq [IntPtr]::Zero) {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        $msg = "无法打开文件进行资源更新 (错误代码: $err)`n请检查文件是否被占用或缺少写入权限！`n`n目标文件: $FullExePath"
        if (-not $Silent) {
            [System.Windows.Forms.MessageBox]::Show($msg, "注入失败", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        } else {
            Write-Error $msg
        }
        return $false
    }

    # RT_MANIFEST = 24, Resource ID = 1, Language ID = 1033 (0x0409 英语/通用)
    $RT_MANIFEST = [IntPtr]24
    $ResId = [IntPtr]1
    $LangId = [ushort]1033

    # 2. 写入新的 Manifest 数据
    $ret = [ManifestPatcher]::UpdateResourceW($hUpdate, $RT_MANIFEST, $ResId, $LangId, $Utf8Bytes, [uint32]$Utf8Bytes.Length)
    if (-not $ret) {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        [ManifestPatcher]::EndUpdateResourceW($hUpdate, $true) | Out-Null
        $msg = "写入清单数据失败 (错误代码: $err)"
        if (-not $Silent) {
            [System.Windows.Forms.MessageBox]::Show($msg, "注入失败", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        } else {
            Write-Error $msg
        }
        return $false
    }

    # 3. 提交并保存更改
    $retEnd = [ManifestPatcher]::EndUpdateResourceW($hUpdate, $false)
    if (-not $retEnd) {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        $msg = "保存资源更新失败 (错误代码: $err)"
        if (-not $Silent) {
            [System.Windows.Forms.MessageBox]::Show($msg, "注入失败", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        } else {
            Write-Error $msg
        }
        return $false
    }

    $successMsg = "🎉 提权清单注入成功！`n`n目标文件：$FullExePath`n`n已写入：<requestedExecutionLevel level='requireAdministrator'/>`n双击该 EXE 时 Windows 将自动弹出 UAC 盾牌请求管理员权限！"
    if (-not $Silent) {
        [System.Windows.Forms.MessageBox]::Show($successMsg, "注入成功", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        Write-Host "Successfully patched manifest for $FullExePath to requireAdministrator!"
    }
    return $true
}

# ================= 流程入口 =================
if ($TargetExe -and (Test-Path $TargetExe)) {
    # 命令行直接处理模式
    Patch-ExeManifest -ExePath $TargetExe -Silent $true
} else {
    # 弹出图形化文件选择对话框
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Title = "请选择需要注入管理员提权 (requireAdministrator) 的 EXE 文件"
    $OpenFileDialog.Filter = "可执行文件 (*.exe)|*.exe|所有文件 (*.*)|*.*"
    $OpenFileDialog.InitialDirectory = [System.AppDomain]::CurrentDomain.BaseDirectory
    $OpenFileDialog.RestoreDirectory = $true

    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $SelectedFile = $OpenFileDialog.FileName
        Patch-ExeManifest -ExePath $SelectedFile -Silent $false
    } else {
        Write-Host "用户已取消选择。"
    }
}
