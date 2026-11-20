@echo off
setlocal
cd /d "%~dp0"
echo [GIN Dock Wallpaper] Building v032...
set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe

if not exist "%CSC%" (
    echo [ERROR] csc.exe not found at %CSC%
    exit /b 1
)

echo [1/3] Compiling Uninstall.exe...
"%CSC%" /nologo /target:winexe /optimize+ /platform:anycpu /r:System.dll,System.Windows.Forms.dll /win32icon:app.ico /out:Uninstall.exe Uninstall.cs

echo [2/3] Compiling GIN-Dock-Wallpaper.exe...
"%CSC%" /nologo /target:winexe /optimize+ /platform:anycpu /r:System.dll,System.Drawing.dll,System.Windows.Forms.dll,System.Core.dll,Microsoft.CSharp.dll /win32icon:app.ico /out:GIN-Dock-Wallpaper.exe GIN-Dock-Wallpaper.cs

echo [3/3] Compiling GIN-Dock-Wallpaper_v032_Setup.exe...
"%CSC%" /nologo /target:winexe /optimize+ /platform:anycpu /r:System.dll,System.Windows.Forms.dll,System.Core.dll,Microsoft.CSharp.dll /win32icon:app.ico /out:..\GIN-Dock-Wallpaper_v032_Setup.exe installer_setup.cs

if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] Compilation complete!
    if exist "D:\MEGA\DOCS\desktop" (
        copy /y "..\GIN-Dock-Wallpaper_v032_Setup.exe" "D:\MEGA\DOCS\desktop\GIN-Dock-Wallpaper_v032_Setup.exe" >nul
        copy /y "..\GIN-Dock-Wallpaper_Setup_v032.cmd" "D:\MEGA\DOCS\desktop\GIN-Dock-Wallpaper_Setup_v032.cmd" >nul
        echo [DEPLOY] Mirrored to D:\MEGA\DOCS\desktop\
    )
) else (
    echo [ERROR] Build failed!
    exit /b %ERRORLEVEL%
)
endlocal
