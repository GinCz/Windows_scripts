#!/bin/bash
set -e
cd /root/AI/GitHub/Secret_Privat/Windows/GIN-NetSpeed
rm -f GIN-NetSpeed_v0*.exe GIN-NetSpeed.exe
x86_64-w64-mingw32-windres app.rc -O coff -o rsrc_windows_amd64.syso
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-NetSpeed_v003.exe .
cp GIN-NetSpeed_v003.exe GIN-NetSpeed.exe
chmod +x GIN-NetSpeed_v003.exe GIN-NetSpeed.exe
ls -lh GIN-NetSpeed_v003.exe GIN-NetSpeed.exe
