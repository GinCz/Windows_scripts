@echo off
cls
setlocal

echo Secure SMB3 network share connection
set /p SERVER=Server name or IP: 
set /p SHARE=Share name: 
set /p DRIVE=Drive letter (for example T): 
set /p USER=SMB username: 

if "%SERVER%"=="" exit /b 1
if "%SHARE%"=="" exit /b 1
if "%DRIVE%"=="" exit /b 1
if "%USER%"=="" exit /b 1

net use %DRIVE%: /delete /y >nul 2>&1
net use %DRIVE%: "\\%SERVER%\%SHARE%" /user:%USER% * /persistent:yes

if errorlevel 1 (
    echo Connection failed.
    exit /b 1
)

echo Connection completed: %DRIVE%:
net use %DRIVE%:
endlocal

= Rooted by VladiMIR + AI | v.2026.08.08 | github.com/GinCz =