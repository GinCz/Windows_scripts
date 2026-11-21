@echo off
setlocal
cd /d "%~dp0"
echo [GIN Desktop] Building v049...
set CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe

if not exist "%CSC%" (
    echo [ERROR] csc.exe not found at %CSC%
    exit /b 1
)

echo [1/4] Compiling Uninstall.exe...
"%CSC%" /nologo /target:winexe /optimize+ /platform:anycpu /r:System.dll,System.Windows.Forms.dll /win32icon:app.ico /out:Uninstall.exe Uninstall.cs

echo [2/4] Compiling GIN-Desktop.exe...
"%CSC%" /nologo /target:winexe /optimize+ /platform:anycpu /r:System.dll,System.Drawing.dll,System.Windows.Forms.dll,System.Core.dll,Microsoft.CSharp.dll /win32icon:app.ico /out:GIN-Desktop.exe GIN-Desktop.cs

echo [3/4] Updating base64 payload via python...
python build_release.py

if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] Compilation complete!
    if exist "D:\MEGA\DOCS\desktop" (
        copy /y "..\GIN-Desktop_v049_Setup.exe" "D:\MEGA\DOCS\desktop\GIN-Desktop_v049_Setup.exe" >nul
        echo [DEPLOY] Mirrored to D:\MEGA\DOCS\desktop\
    )
) else (
    echo [ERROR] Build failed!
    exit /b %ERRORLEVEL%
)
endlocal
