@echo off
chcp 65001 > nul
cd /d "%~dp0"
echo ==============================================================================
echo 正在启动 EXE 管理员提权清单注入向导 (PowerShell GUI)...
echo ==============================================================================
powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch_manifest.ps1"
