@echo off
rem 解决控制台编码问题
chcp 65001 >nul
title NeutralinoJS 运行文件更新工具

echo.
echo ==================================================
echo         NeutralinoJS 运行文件更新向导
echo ==================================================
echo.
echo 正在启动更新程序，请稍候...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_bin.ps1"

echo.
echo ==================================================
echo   更新程序执行完毕，按任意键退出...
echo ==================================================
pause >nul
