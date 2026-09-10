@echo off
rem 本文件为 GBK(ANSI) 编码, 在中文代码页下解析
rem 先切到中文代码页(936)再重启自身, 保证整个文件在同一代码页下解析
if defined WIZ_CP goto MAIN
setlocal
set "WIZ_CP=1"
chcp 936 >nul
"%~f0" %*
endlocal & exit /b %errorlevel%
:MAIN
setlocal EnableDelayedExpansion
title NeutralinoJS 打包向导

echo.
echo  ==================================================
echo        NeutralinoJS 打包向导  -  HTML 转 EXE
echo  ==================================================
echo.
echo   本向导将引导你把 HTML 网页打包成 Windows 桌面程序。
echo   全程离线: 运行库取自本目录 bin\, 构建工具取自 node_modules\
echo   前提: 本机已安装 Node.js (https://nodejs.org)
echo.

where node >nul 2>nul
if errorlevel 1 goto NOENV
where npx >nul 2>nul
if errorlevel 1 goto NOENV

rem ================= 输入应用名称 =================
:ASKNAME
set "AppName="
set /p AppName=请输入应用名称(将作为项目文件夹和程序名, 例如: 图片搜索): 
if not defined AppName goto ASKNAME
set "ProjDir=%~dp0%AppName%"
if not exist "!ProjDir!" mkdir "!ProjDir!"
pushd "!ProjDir!"
if not exist "resources" mkdir "resources"

if exist "neutralino.config.json" goto EXISTMENU

rem ================= 第 1 步: 放入网页文件 =================
echo.
echo  --------------------------------------------------
echo  [第 1 步] 放入网页文件
echo  --------------------------------------------------
echo.
echo   即将打开文件夹, 请把你的网页文件放进去:
echo       !ProjDir!\resources
echo.
echo   注意:
echo     1. 入口文件必须命名为 index.html
echo     2. css / js / 图片等所有依赖文件也要一并放入
echo     3. 如需调用系统功能, index.html 中请引入客户端库:
echo        ^<script src="js/neutralino.js"^>^</script^>
echo     4. 可选: 放入 favicon.ico 可消除日志中的图标警告
echo.
start "" "explorer" "!ProjDir!\resources"
pause

:INDEXCHECK
if exist "resources\index.html" goto WIZARD
echo.
echo  [!] 未找到 index.html, 无法继续。
echo      请将入口网页放入: !ProjDir!\resources
echo.
pause
goto INDEXCHECK

rem ================= 第 2 步: 填写应用信息 =================
:WIZARD
echo.
echo  --------------------------------------------------
echo  [第 2 步] 填写应用信息 (直接回车 = 使用中括号里的默认值)
echo  --------------------------------------------------
echo.
set "AppTitle=!AppName!"
set /p AppTitle=  1. 窗口标题 [!AppTitle!]: 

call :Sanitize AppName SanName
if defined SanName goto HAVEBINNAME
echo   提示: 应用名称不含英文字符, 需输入一个英文程序名 (用于内部文件命名)。
:ASKENGNAME
set "EngName="
set /p EngName=  英文程序名 (仅限英文字母/数字/短横线, 回车 = app): 
if not defined EngName set "EngName=app"
call :Sanitize EngName SanName
if not defined SanName (echo   [!] 名称无效, 请重新输入 & goto ASKENGNAME)
:HAVEBINNAME
set "BinaryName=!SanName!"
set "AppId=com.!SanName!.app"
set /p AppId=  2. 应用ID [!AppId!]: 

set "AppVersion=1.0.0"
set /p AppVersion= 3. 版本号 [!AppVersion!]: 

echo.
echo   4. 启动模式:
echo        1 - window  桌面窗口程序 (推荐)
echo        2 - browser 用系统默认浏览器打开
echo        3 - cloud   云模式
set "ModeNum=1"
set /p ModeNum=      选择 [1]: 
set "AppMode=window"
if "!ModeNum!"=="2" set "AppMode=browser"
if "!ModeNum!"=="3" set "AppMode=cloud"

echo.
echo   5. 窗口尺寸 (默认 900 x 760):
set "W=900"
set /p W=      宽度 [!W!]: 
call :CheckNum W 900
set "H=760"
set /p H=      高度 [!H!]: 
call :CheckNum H 760
echo   6. 最小尺寸限制 (0 = 不限制):
set "MW=0"
set /p MW=      最小宽度 [0]: 
call :CheckNum MW 0
set "MH=0"
set /p MH=      最小高度 [0]: 
call :CheckNum MH 0

echo.
echo   7. 窗口行为 (输入 y 或 n, 回车 = 默认值):
call :AskYN Resizable  "     可调整窗口大小" y
call :AskYN FullScreen "     全屏启动" n
call :AskYN Borderless "     无边框窗口" n
call :AskYN AlwaysOnTop "     窗口置顶" n
call :AskYN EnableAPI  "     启用系统API(剪贴板/存储/文件等)" y

echo.
echo   8. 应用图标 (PNG 格式, 建议 512x512 正方形):
if not exist "resources\icons" mkdir "resources\icons"
set "IconPath="
set "IconDisp=使用默认图标"
set /p IconPath=      图标文件完整路径 [使用默认图标]: 
if defined IconPath for /f "delims=" %%a in ("!IconPath!") do set "IconPath=%%~a"
if defined IconPath if not exist "!IconPath!" set "IconPath="
if defined IconPath copy /y "!IconPath!" "resources\icons\appIcon.png" >nul 2>nul
if not exist "resources\icons\appIcon.png" copy /y "%~dp0resources\icons\default.png" "resources\icons\appIcon.png" >nul
if defined IconPath if exist "resources\icons\appIcon.png" set "IconDisp=自定义图标"

echo.
echo  --------------------------------------------------
echo   配置汇总:
echo     应用名称 : !AppName!
echo     窗口标题 : !AppTitle!
echo     应用ID   : !AppId!
echo     版本     : !AppVersion!
echo     启动模式 : !AppMode!
echo     窗口尺寸 : !W! x !H!   (最小 !MW! x !MH!)
echo     行为选项 : 可调整=!Resizable!  全屏=!FullScreen!  无边框=!Borderless!  置顶=!AlwaysOnTop!
echo     系统API  : !EnableAPI!
echo     图标     : !IconDisp!
echo  --------------------------------------------------
call :AskYN Confirmed "  确认以上配置并继续" y
if "!Confirmed!"=="false" goto WIZARD

rem ================= 第 3 步: 生成配置文件 =================
echo.
echo  [第 3 步] 生成 neutralino.config.json ...
set "CFG=neutralino.config.json"
> "!CFG!" echo({
>>"!CFG!" echo(  "applicationId": "!AppId!",
>>"!CFG!" echo(  "version": "!AppVersion!",
>>"!CFG!" echo(  "defaultMode": "!AppMode!",
>>"!CFG!" echo(  "port": 0,
>>"!CFG!" echo(  "documentRoot": "/resources/",
>>"!CFG!" echo(  "url": "/",
>>"!CFG!" echo(  "enableServer": !EnableAPI!,
>>"!CFG!" echo(  "enableNativeAPI": !EnableAPI!,
>>"!CFG!" echo(  "tokenSecurity": "one-time",
>>"!CFG!" echo(  "logging": {
>>"!CFG!" echo(    "enabled": true,
>>"!CFG!" echo(    "writeToLogFile": true
>>"!CFG!" echo(  },
>>"!CFG!" echo(  "nativeAllowList": [
>>"!CFG!" echo(    "app.*",
>>"!CFG!" echo(    "os.*",
>>"!CFG!" echo(    "clipboard.*",
>>"!CFG!" echo(    "storage.*",
>>"!CFG!" echo(    "window.*",
>>"!CFG!" echo(    "events.*",
>>"!CFG!" echo(    "debug.*",
>>"!CFG!" echo(    "computer.*",
>>"!CFG!" echo(    "filesystem.*"
>>"!CFG!" echo(  ],
>>"!CFG!" echo(  "modes": {
>>"!CFG!" echo(    "window": {
>>"!CFG!" echo(      "title": "!AppTitle!",
>>"!CFG!" echo(      "width": !W!,
>>"!CFG!" echo(      "height": !H!,
if !MW! GTR 0 >>"!CFG!" echo(      "minWidth": !MW!,
if !MH! GTR 0 >>"!CFG!" echo(      "minHeight": !MH!,
>>"!CFG!" echo(      "center": true,
>>"!CFG!" echo(      "fullScreen": !FullScreen!,
>>"!CFG!" echo(      "alwaysOnTop": !AlwaysOnTop!,
>>"!CFG!" echo(      "enableInspector": false,
>>"!CFG!" echo(      "borderless": !Borderless!,
>>"!CFG!" echo(      "maximize": false,
>>"!CFG!" echo(      "hidden": false,
>>"!CFG!" echo(      "resizable": !Resizable!,
>>"!CFG!" echo(      "exitProcessOnClose": true,
>>"!CFG!" echo(      "icon": "/resources/icons/appIcon.png"
>>"!CFG!" echo(    },
>>"!CFG!" echo(    "browser": {},
>>"!CFG!" echo(    "cloud": {}
>>"!CFG!" echo(  },
>>"!CFG!" echo(  "cli": {
>>"!CFG!" echo(    "binaryName": "!BinaryName!",
>>"!CFG!" echo(    "resourcesPath": "/resources/",
>>"!CFG!" echo(    "extensionsPath": "/extensions/",
>>"!CFG!" echo(    "clientLibrary": "/resources/js/neutralino.js",
>>"!CFG!" echo(    "binaryVersion": "latest",
>>"!CFG!" echo(    "clientVersion": "latest"
>>"!CFG!" echo(  }
>>"!CFG!" echo(}
rem 配置文件须为 UTF-8 编码 (bat 为 GBK, 生成后转换编码)
powershell -NoProfile -Command "$p='neutralino.config.json';$t=[IO.File]::ReadAllText($p,[Text.Encoding]::GetEncoding(936));[IO.File]::WriteAllText($p,$t,(New-Object Text.UTF8Encoding($false)))" >nul 2>&1
if errorlevel 1 echo   [!] 警告: 配置文件编码转换失败, 中文内容可能异常
echo   配置文件已生成。

rem ================= 选择打包类型 =================
:ASKREL
echo.
echo  打包类型:
echo     1 - Release 正式版 (资源内嵌进EXE, 单文件即可分发, 推荐)
echo     2 - Debug   调试版 (可用开发者工具排查问题)
set "RelType=1"
set /p RelType=请选择 [1]: 

rem ================= 第 4 步: 复制本地运行库 =================
:DOBUILD
if exist "bin" if exist "resources\js\neutralino.js" goto BUILDGO
echo.
echo  [第 4 步] 复制本地运行库 (bin 运行文件 + 客户端库) ...
if not exist "%~dp0bin" goto NOLOCALBIN
xcopy /e /i /y "%~dp0bin" "bin" >nul
if not exist "resources\js" mkdir "resources\js"
if exist "%~dp0resources\js\neutralino.js" copy /y "%~dp0resources\js\neutralino.js" "resources\js\neutralino.js" >nul
if exist "%~dp0resources\js\neutralino.d.ts" copy /y "%~dp0resources\js\neutralino.d.ts" "resources\js\neutralino.d.ts" >nul
if not exist "bin\neutralino-win_x64.exe" goto NOLOCALBIN
echo   运行库复制完成 (bin 目录 + 客户端库)。

rem ================= 第 5 步: 打包 =================
:BUILDGO
echo.
echo  [第 5 步] 正在打包, 请稍候 ...
rem Release 版使用 --embed-resources: 网页资源内嵌进 EXE, 生成单文件程序
set "BUILDARGS=--release --embed-resources"
if "!RelType!"=="2" set "BUILDARGS="
set "NEUBIN=%~dp0node_modules\@neutralinojs\neu\bin\neu.js"
if not exist "!NEUBIN!" goto BUILDNPX
call node "!NEUBIN!" build !BUILDARGS!
goto BUILDCHECK
:BUILDNPX
call npx --yes @neutralinojs/neu build !BUILDARGS!
:BUILDCHECK
rem 个别情况下 CLI 结尾清理文件时可能误报非零退出码, 以产物是否存在为准
if exist "dist\!BinaryName!\!BinaryName!-win_x64.exe" goto BUILDOK
if errorlevel 1 goto BUILDFAIL
if not exist "dist\!BinaryName!" goto BUILDFAIL
:BUILDOK

rem ================= 第 6 步: 整理输出 =================
echo.
echo  [第 6 步] 整理输出文件 ...
set "FinalExe="
if exist "dist\!BinaryName!\!BinaryName!-win_x64.exe" copy /y "dist\!BinaryName!\!BinaryName!-win_x64.exe" "dist\!AppName!.exe" >nul
if exist "dist\!AppName!.exe" set "FinalExe=dist\!AppName!.exe"
if not defined FinalExe for /f "delims=" %%f in ('dir /b /s "dist\*-win_x64.exe" 2^>nul') do set "FinalExe=%%f"
if not defined FinalExe goto BUILDFAIL
if "!RelType!"=="2" if exist "dist\!BinaryName!\resources.neu" copy /y "dist\!BinaryName!\resources.neu" "dist\resources.neu" >nul
rem Release 版: 确保内嵌模式下残留的 resources.neu 被清除 (单文件 EXE 已内嵌全部资源)
if not "!RelType!"=="2" (
  if exist "dist\resources.neu" del /q "dist\resources.neu" >nul 2>&1
  if exist "dist\!BinaryName!\resources.neu" del /q "dist\!BinaryName!\resources.neu" >nul 2>&1
)
rem 清理构建/运行缓存目录, 减少输出目录杂物
if exist "dist\.tmp" rd /s /q "dist\.tmp"
if exist "dist\!BinaryName!\.tmp" rd /s /q "dist\!BinaryName!\.tmp"

echo.
echo  ==================================================
echo   打包成功!
echo  ==================================================
echo   单文件程序 (推荐, 已内嵌全部资源, 可直接分发):
echo       !ProjDir!\!FinalExe!
echo.
echo   全平台原始输出 (内容与上面相同, 文件夹为内部英文名):
echo       !ProjDir!\dist\!BinaryName!\  (含 Windows / Linux / Mac 版)
echo   发布压缩包: dist\!BinaryName!-release.zip
echo.
if "!RelType!"=="2" echo   注意: Debug 版运行时需同目录的 resources.neu 文件。
if not "!RelType!"=="2" echo   说明: 上面那个单文件 EXE 与 dist\!BinaryName!\!BinaryName!-win_x64.exe 是同一程序的副本。
echo.
call :AskYN RunIt "  立即运行测试" y
if "!RunIt!"=="true" if defined FinalExe start "" "!FinalExe!"
start "" "explorer" "!ProjDir!\dist"
goto END

rem ================= 已有项目菜单 =================
:EXISTMENU
echo.
echo  检测到该项目已有配置文件:
echo     1 - 直接重新打包 (沿用现有配置)
echo     2 - 重新填写应用信息
set "Pick=1"
set /p Pick=请选择 [1]: 
if "!Pick!"=="2" goto INDEXCHECK
goto ASKREL

rem ================= 错误处理 =================
:NOENV
echo.
echo  [X] 未检测到 Node.js / npx。
echo      请先安装 Node.js LTS 版: https://nodejs.org
echo      安装完成后重新运行本向导。
goto END

:NOLOCALBIN
echo.
echo  [X] 未找到本地运行库。
echo      请把完整的 bin 文件夹 (含 neutralino-win_x64.exe 等运行文件)
echo      放到与本向导相同的目录下再运行。
goto END

:BUILDFAIL
echo.
echo  [X] 打包失败, 输出文件未生成。请检查:
echo      1. resources\index.html 是否存在且完整
echo      2. resources\icons\appIcon.png 是否存在
echo      3. 可手动执行查看详细报错:
echo         node node_modules\@neutralinojs\neu\bin\neu.js build --release --embed-resources
goto END

:END
popd 2>nul
echo.
echo  按任意键退出向导...
pause >nul
exit /b 0

rem ================= 子过程 =================
:Sanitize
set "SANIN=!%~1!"
set "SANOUT="
:SanLoop
if not defined SANIN goto SanDone
set "SANC=!SANIN:~0,1!"
for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 _ -) do if /i "!SANC!"=="%%a" set "SANOUT=!SANOUT!!SANC!"
set "SANIN=!SANIN:~1!"
goto SanLoop
:SanDone
set "%~2=!SANOUT!"
goto :eof

:CheckNum
echo(!%~1!|findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 set "%~1=%~2"
goto :eof

:AskYN
set "YNDEF=%~3"
if /i "!YNDEF!"=="y" set "%~1=true"
if /i "!YNDEF!"=="n" set "%~1=false"
:AskYNLoop
set "YN="
set /p YN=%~2 [y/n, 回车=!YNDEF!]: 
if not defined YN goto :eof
set "YNC=!YN:~0,1!"
if /i "!YNC!"=="y" set "%~1=true" & goto :eof
if /i "!YNC!"=="n" set "%~1=false" & goto :eof
echo      请输入 y 或 n
goto AskYNLoop
