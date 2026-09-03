# ====================================================================
#  XRAY_VPN AUTOMATED ONLINE INSTALLER FOR WINDOWS 7 / 10 / 11
#  Repository: https://github.com/GinCz/Windows_scripts
# ====================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$dir = "C:\XRAY_VPN"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "       XRAY_VPN AUTOMATED INSTALLER (ONLINE RELEASES)              " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Elevation required. Restarting with Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

if (-not (Test-Path $dir)) {
    [System.IO.Directory]::CreateDirectory($dir) | Out-Null
    Write-Host "[+] Directory created: $dir" -ForegroundColor Green
}

# 1. Setup TLS 1.2
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]3072 -bor [System.Net.SecurityProtocolType]768 -bor [System.Net.SecurityProtocolType]192
} catch {}

# 2. Obtain xray.exe
if (-not (Test-Path "$dir\xray.exe")) {
    $is64 = [IntPtr]::Size -eq 8 -or [Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITEW6432") -ne $null -or $env:PROCESSOR_ARCHITECTURE -eq "AMD64"
    $zipName = if ($is64) { "Xray-windows-64.zip" } else { "Xray-windows-32.zip" }
    $zipUrl = "https://github.com/XTLS/Xray-core/releases/latest/download/$zipName"
    $zipPath = "$dir\xray_temp.zip"

    Write-Host "[*] Downloading $zipName from GitHub Releases..." -ForegroundColor Cyan
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 6.1; Win64; x64)")
    $downloadSuccess = $false
    try {
        $wc.DownloadFile($zipUrl, $zipPath)
        if ((Test-Path $zipPath) -and (Get-Item $zipPath).Length -gt 1000000) {
            $downloadSuccess = $true
            Write-Host "[+] Downloaded successfully: $((Get-Item $zipPath).Length) bytes" -ForegroundColor Green
        }
    } catch {
        Write-Host "[-] GitHub download failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    if ($downloadSuccess) {
        Write-Host "[*] Extracting xray.exe..." -ForegroundColor Cyan
        try {
            $shell = New-Object -ComObject Shell.Application
            $zip = $shell.Namespace((Resolve-Path $zipPath).Path)
            $item = $zip.Items() | Where-Object { $_.Name -eq "xray.exe" }
            if ($item) {
                $target = $shell.Namespace((Resolve-Path $dir).Path)
                $target.CopyHere($item, 16)
                Start-Sleep -Seconds 2
            }
        } catch {
            Write-Host "[-] COM extraction error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    }

    # Fallback to local copy if extraction or download failed
    if (-not (Test-Path "$dir\xray.exe")) {
        Write-Host "[*] Searching local drives for existing xray.exe..." -ForegroundColor Yellow
        $f = Get-ChildItem -Path "C:\","D:\" -Filter "xray.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f) {
            Copy-Item $f.FullName "$dir\xray.exe" -Force
            Write-Host "[+] Found and copied local xray.exe from $($f.FullName)" -ForegroundColor Green
        } else {
            Write-Host "[-] Warning: xray.exe not found. Please place xray.exe manually into $dir" -ForegroundColor Red
        }
    }
} else {
    Write-Host "[+] xray.exe already present in $dir" -ForegroundColor Green
}

# 3. Deploy Internal Scripts
Write-Host "[*] Deploying scripts: Start_VPN.ps1, Stop_VPN.ps1, TrayVPN.ps1..." -ForegroundColor Cyan
[System.IO.File]::WriteAllBytes("$dir\Start_VPN.ps1", [Convert]::FromBase64String("W0NvbnNvbGVdOjpPdXRwdXRFbmNvZGluZyA9IFtTeXN0ZW0uVGV4dC5FbmNvZGluZ106OlVURjgNCiRsb2dGaWxlID0gIkM6XFhSQVlfVlBOXHZwbi5sb2ciDQokbGlua0ZpbGUgPSAiQzpcWFJBWV9WUE5cbGluay50eHQiDQokY29uZmlnRmlsZSA9ICJDOlxYUkFZX1ZQTlxjb25maWcuanNvbiINCg0KZnVuY3Rpb24gV3JpdGUtTG9nKFtzdHJpbmddJG1zZykgew0KICAgICR0cyA9IChHZXQtRGF0ZSkuVG9TdHJpbmcoInl5eXktTU0tZGQgSEg6bW06c3MiKQ0KICAgIEFkZC1Db250ZW50IC1QYXRoICRsb2dGaWxlIC1WYWx1ZSAiWyR0c10gJG1zZyINCn0NCg0KIyAzMC1kYXkgTG9nIFBydW5pbmcNCmlmIChUZXN0LVBhdGggJGxvZ0ZpbGUpIHsNCiAgICAkbGltaXQgPSAoR2V0LURhdGUpLkFkZERheXMoLTMwKQ0KICAgICRsaW5lcyA9IEdldC1Db250ZW50ICRsb2dGaWxlIHwgV2hlcmUtT2JqZWN0IHsNCiAgICAgICAgaWYgKCRfIC1tYXRjaCAiXlxbKFxkezR9LVxkezJ9LVxkezJ9KSIpIHsNCiAgICAgICAgICAgIHRyeSB7IFtkYXRldGltZV0kbWF0Y2hlc1sxXSAtZ2UgJGxpbWl0IH0gY2F0Y2ggeyAkdHJ1ZSB9DQogICAgICAgIH0gZWxzZSB7ICR0cnVlIH0NCiAgICB9DQogICAgW1N5c3RlbS5JTy5GaWxlXTo6V3JpdGVBbGxMaW5lcygkbG9nRmlsZSwgJGxpbmVzLCAoTmV3LU9iamVjdCBTeXN0ZW0uVGV4dC5VVEY4RW5jb2RpbmcoJEZhbHNlKSkpDQp9DQoNCldyaXRlLUxvZyAiW1NUQVJUXSBJbml0aWFsaXppbmcgVlBOLi4uIg0KDQppZiAoLW5vdCAoVGVzdC1QYXRoICRsaW5rRmlsZSkpIHsNCiAgICBXcml0ZS1Mb2cgIltFUlJPUl0gbGluay50eHQgbm90IGZvdW5kISINCiAgICBleGl0IDENCn0NCg0KJGxpbmsgPSBbU3lzdGVtLklPLkZpbGVdOjpSZWFkQWxsVGV4dCgkbGlua0ZpbGUsIFtTeXN0ZW0uVGV4dC5FbmNvZGluZ106OlVURjgpLlRyaW0oKQ0KaWYgKCRsaW5rIC1ub3RtYXRjaCAiXnZsZXNzOi8vIikgew0KICAgIFdyaXRlLUxvZyAiW0VSUk9SXSBObyB2YWxpZCB2bGVzczovLyBsaW5rIGluIGxpbmsudHh0Ig0KICAgIGV4aXQgMQ0KfQ0KDQokcmVnZXggPSAidmxlc3M6Ly8oPzxpZD5bXkBdKylAKD88aXA+W146XSspOig/PHBvcnQ+XGQrKVw/KD88cGFyYW1zPlteI10rKSgjKD88bmFtZT4uKikpPyINCiR1cmlNYXRjaCA9ICRsaW5rIC1tYXRjaCAkcmVnZXgNCmlmICgtbm90ICR1cmlNYXRjaCkgew0KICAgIFdyaXRlLUxvZyAiW0VSUk9SXSBJbnZhbGlkIFZMRVNTIFVSSSBzeW50YXghIg0KICAgIGV4aXQgMQ0KfQ0KDQokaWQgPSAkbWF0Y2hlc1snaWQnXQ0KJGlwID0gJG1hdGNoZXNbJ2lwJ10NCiRwb3J0ID0gW2ludF0kbWF0Y2hlc1sncG9ydCddDQokcGFyYW1zID0gJG1hdGNoZXNbJ3BhcmFtcyddDQokbmFtZSA9IGlmICgkbWF0Y2hlcy5Db250YWluc0tleSgnbmFtZScpKSB7IFt1cmldOjpVbmVzY2FwZURhdGFTdHJpbmcoJG1hdGNoZXNbJ25hbWUnXSkgfSBlbHNlIHsgIlZQTiIgfQ0KDQokcGJrID0gaWYgKCRwYXJhbXMgLW1hdGNoICJwYms9KFteJl0rKSIpIHsgJG1hdGNoZXNbMV0gfSBlbHNlIHsgIiIgfQ0KJHNpZCA9IGlmICgkcGFyYW1zIC1tYXRjaCAic2lkPShbXiZdKykiKSB7ICRtYXRjaGVzWzFdIH0gZWxzZSB7ICIiIH0NCiRzbmkgPSBpZiAoJHBhcmFtcyAtbWF0Y2ggInNuaT0oW14mXSspIikgeyAkbWF0Y2hlc1sxXSB9IGVsc2UgeyAiIiB9DQokZnAgID0gaWYgKCRwYXJhbXMgLW1hdGNoICJmcD0oW14mXSspIikgIHsgJG1hdGNoZXNbMV0gfSBlbHNlIHsgImZpcmVmb3giIH0NCiRmbG93ID0gaWYgKCRwYXJhbXMgLW1hdGNoICJmbG93PShbXiZdKykiKSB7ICRtYXRjaGVzWzFdIH0gZWxzZSB7ICIiIH0NCiRzcHggPSBpZiAoJHBhcmFtcyAtbWF0Y2ggInNweD0oW14mXSspIikgeyBbdXJpXTo6VW5lc2NhcGVEYXRhU3RyaW5nKCRtYXRjaGVzWzFdKSB9IGVsc2UgeyAiLyIgfQ0KDQokanNvbiA9IEAiDQp7DQogICJpbmJvdW5kcyI6IFsNCiAgICB7InBvcnQiOiAxMDgwOCwgImxpc3RlbiI6ICIxMjcuMC4wLjEiLCAicHJvdG9jb2wiOiAic29ja3MiLCAic2V0dGluZ3MiOiB7InVkcCI6IHRydWV9fSwNCiAgICB7InBvcnQiOiAxMDgwOSwgImxpc3RlbiI6ICIxMjcuMC4wLjEiLCAicHJvdG9jb2wiOiAiaHR0cCIsICJzZXR0aW5ncyI6IHt9fQ0KICBdLA0KICAib3V0Ym91bmRzIjogWw0KICAgIHsNCiAgICAgICJwcm90b2NvbCI6ICJ2bGVzcyIsDQogICAgICAic2V0dGluZ3MiOiB7DQogICAgICAgICJ2bmV4dCI6IFt7ImFkZHJlc3MiOiAiJGlwIiwgInBvcnQiOiAkcG9ydCwgInVzZXJzIjogW3siaWQiOiAiJGlkIiwgImVuY3J5cHRpb24iOiAibm9uZSIsICJmbG93IjogIiRmbG93In1dfV0NCiAgICAgIH0sDQogICAgICAic3RyZWFtU2V0dGluZ3MiOiB7DQogICAgICAgICJuZXR3b3JrIjogInRjcCIsDQogICAgICAgICJzZWN1cml0eSI6ICJyZWFsaXR5IiwNCiAgICAgICAgInJlYWxpdHlTZXR0aW5ncyI6IHsNCiAgICAgICAgICAicHVibGljS2V5IjogIiRwYmsiLA0KICAgICAgICAgICJmaW5nZXJwcmludCI6ICIkZnAiLA0KICAgICAgICAgICJzZXJ2ZXJOYW1lIjogIiRzbmkiLA0KICAgICAgICAgICJzaG9ydElkIjogIiRzaWQiLA0KICAgICAgICAgICJzcGlkZXJYIjogIiRzcHgiDQogICAgICAgIH0NCiAgICAgIH0NCiAgICB9DQogIF0NCn0NCiJADQoNCiR1dGY4Tm9Cb20gPSBOZXctT2JqZWN0IFN5c3RlbS5UZXh0LlVURjhFbmNvZGluZygkRmFsc2UpDQpbU3lzdGVtLklPLkZpbGVdOjpXcml0ZUFsbFRleHQoJGNvbmZpZ0ZpbGUsICRqc29uLCAkdXRmOE5vQm9tKQ0KV3JpdGUtTG9nICJbQ09ORklHXSBHZW5lcmF0ZWQgZm9yIG5vZGUgJG5hbWUgKCRpcGA6JHBvcnQpIg0KDQojIFJlc3RhcnQgWHJheQ0KdGFza2tpbGwgL0YgL0lNIHhyYXkuZXhlIDI+JG51bGwNClN0YXJ0LVNsZWVwIC1NaWxsaXNlY29uZHMgNTAwDQpTdGFydC1Qcm9jZXNzIC1GaWxlUGF0aCAiQzpcWFJBWV9WUE5ceHJheS5leGUiIC1Bcmd1bWVudExpc3QgInJ1biAtYyBDOlxYUkFZX1ZQTlxjb25maWcuanNvbiIgLVdpbmRvd1N0eWxlIEhpZGRlbg0KDQojIEFwcGx5IFN5c3RlbSBQcm94eQ0KJHJvb3QgPSAiSEtDVTpcU29mdHdhcmVcTWljcm9zb2Z0XFdpbmRvd3NcQ3VycmVudFZlcnNpb25cSW50ZXJuZXQgU2V0dGluZ3MiDQpTZXQtSXRlbVByb3BlcnR5IC1QYXRoICRyb290IC1OYW1lIFByb3h5RW5hYmxlIC1WYWx1ZSAxDQpTZXQtSXRlbVByb3BlcnR5IC1QYXRoICRyb290IC1OYW1lIFByb3h5U2VydmVyIC1WYWx1ZSAiMTI3LjAuMC4xOjEwODA5Ig0KU2V0LUl0ZW1Qcm9wZXJ0eSAtUGF0aCAkcm9vdCAtTmFtZSBQcm94eU92ZXJyaWRlIC1WYWx1ZSAibG9jYWxob3N0OzEyNy4qOzxsb2NhbD4iDQoNCiMgV2luSU5ldCBCcm9hZGNhc3QNCiRjc2hhcnAgPSBAJw0KdXNpbmcgU3lzdGVtOw0KdXNpbmcgU3lzdGVtLlJ1bnRpbWUuSW50ZXJvcFNlcnZpY2VzOw0KcHVibGljIGNsYXNzIFdpbkluZXRTeW5jIHsNCiAgICBbRGxsSW1wb3J0KCJ3aW5pbmV0LmRsbCIsIFNldExhc3RFcnJvciA9IHRydWUpXQ0KICAgIHB1YmxpYyBzdGF0aWMgZXh0ZXJuIGJvb2wgSW50ZXJuZXRTZXRPcHRpb24oSW50UHRyIGhJbnRlcm5ldCwgaW50IGR3T3B0aW9uLCBJbnRQdHIgbHBCdWZmZXIsIGludCBkd0J1ZmZlckxlbmd0aCk7DQogICAgcHVibGljIHN0YXRpYyB2b2lkIFN5bmMoKSB7DQogICAgICAgIEludGVybmV0U2V0T3B0aW9uKEludFB0ci5aZXJvLCAzOSwgSW50UHRyLlplcm8sIDApOw0KICAgICAgICBJbnRlcm5ldFNldE9wdGlvbihJbnRQdHIuWmVybywgMzcsIEludFB0ci5aZXJvLCAwKTsNCiAgICB9DQp9DQonQA0KQWRkLVR5cGUgLVR5cGVEZWZpbml0aW9uICRjc2hhcnAgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCltXaW5JbmV0U3luY106OlN5bmMoKQ0KDQpXcml0ZS1Mb2cgIltPS10gVlBOIENvbm5lY3RlZCBhbmQgUHJveHkgQWN0aXZlLiINCg0KIyBMYXVuY2ggVHJheSBJY29uDQpTdGFydC1Qcm9jZXNzIC1GaWxlUGF0aCAicG93ZXJzaGVsbC5leGUiIC1Bcmd1bWVudExpc3QgIi1XaW5kb3dTdHlsZSBIaWRkZW4gLU5vUHJvZmlsZSAtRXhlY3V0aW9uUG9saWN5IEJ5cGFzcyAtRmlsZSBDOlxYUkFZX1ZQTlxUcmF5VlBOLnBzMSIgLVdpbmRvd1N0eWxlIEhpZGRlbg0K"))
[System.IO.File]::WriteAllBytes("$dir\Stop_VPN.ps1", [Convert]::FromBase64String("W0NvbnNvbGVdOjpPdXRwdXRFbmNvZGluZyA9IFtTeXN0ZW0uVGV4dC5FbmNvZGluZ106OlVURjgNCiRsb2dGaWxlID0gIkM6XFhSQVlfVlBOXHZwbi5sb2ciDQoNCmZ1bmN0aW9uIFdyaXRlLUxvZyhbc3RyaW5nXSRtc2cpIHsNCiAgICAkdHMgPSAoR2V0LURhdGUpLlRvU3RyaW5nKCJ5eXl5LU1NLWRkIEhIOm1tOnNzIikNCiAgICBBZGQtQ29udGVudCAtUGF0aCAkbG9nRmlsZSAtVmFsdWUgIlskdHNdICRtc2ciDQp9DQoNCiMgMS4gS2lsbCBYcmF5DQp0YXNra2lsbCAvRiAvSU0geHJheS5leGUgMj4kbnVsbA0KDQojIDIuIFJlc2V0IFByb3h5IGluIFJlZ2lzdHJ5DQokcm9vdCA9ICJIS0NVOlxTb2Z0d2FyZVxNaWNyb3NvZnRcV2luZG93c1xDdXJyZW50VmVyc2lvblxJbnRlcm5ldCBTZXR0aW5ncyINClNldC1JdGVtUHJvcGVydHkgLVBhdGggJHJvb3QgLU5hbWUgUHJveHlFbmFibGUgLVZhbHVlIDANClJlbW92ZS1JdGVtUHJvcGVydHkgLVBhdGggJHJvb3QgLU5hbWUgUHJveHlTZXJ2ZXIgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUNCg0KIyAzLiBCcm9hZGNhc3QgV2luSU5ldCBSZXNldA0KJGNzaGFycCA9IEAnDQp1c2luZyBTeXN0ZW07DQp1c2luZyBTeXN0ZW0uUnVudGltZS5JbnRlcm9wU2VydmljZXM7DQpwdWJsaWMgY2xhc3MgV2luSW5ldFN5bmMgew0KICAgIFtEbGxJbXBvcnQoIndpbmluZXQuZGxsIiwgU2V0TGFzdEVycm9yID0gdHJ1ZSldDQogICAgcHVibGljIHN0YXRpYyBleHRlcm4gYm9vbCBJbnRlcm5ldFNldE9wdGlvbihJbnRQdHIgaEludGVybmV0LCBpbnQgZHdPcHRpb24sIEludFB0ciBscEJ1ZmZlciwgaW50IGR3QnVmZmVyTGVuZ3RoKTsNCiAgICBwdWJsaWMgc3RhdGljIHZvaWQgU3luYygpIHsNCiAgICAgICAgSW50ZXJuZXRTZXRPcHRpb24oSW50UHRyLlplcm8sIDM5LCBJbnRQdHIuWmVybywgMCk7DQogICAgICAgIEludGVybmV0U2V0T3B0aW9uKEludFB0ci5aZXJvLCAzNywgSW50UHRyLlplcm8sIDApOw0KICAgIH0NCn0NCidADQpBZGQtVHlwZSAtVHlwZURlZmluaXRpb24gJGNzaGFycCAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZQ0KW1dpbkluZXRTeW5jXTo6U3luYygpDQoNCiMgNC4gVGVybWluYXRlIGFueSBUcmF5VlBOIHByb2Nlc3MNCkdldC1Qcm9jZXNzIHBvd2Vyc2hlbGwgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWUgfCBXaGVyZS1PYmplY3QgeyAkXy5NYWluV2luZG93VGl0bGUgLWVxICcnIH0gfCBTdG9wLVByb2Nlc3MgLUZvcmNlIDI+JG51bGwNCg0KV3JpdGUtTG9nICJbU1RPUF0gVlBOIERpc2Nvbm5lY3RlZC4gRGlyZWN0IEludGVybmV0IFJlc3RvcmVkLiINCg=="))
[System.IO.File]::WriteAllBytes("$dir\TrayVPN.ps1", [Convert]::FromBase64String("W3ZvaWRdW1N5c3RlbS5SZWZsZWN0aW9uLkFzc2VtYmx5XTo6TG9hZFdpdGhQYXJ0aWFsTmFtZSgiU3lzdGVtLldpbmRvd3MuRm9ybXMiKQ0KW3ZvaWRdW1N5c3RlbS5SZWZsZWN0aW9uLkFzc2VtYmx5XTo6TG9hZFdpdGhQYXJ0aWFsTmFtZSgiU3lzdGVtLkRyYXdpbmciKQ0KDQokYm1wID0gTmV3LU9iamVjdCBTeXN0ZW0uRHJhd2luZy5CaXRtYXAgMTYsIDE2DQokZyA9IFtTeXN0ZW0uRHJhd2luZy5HcmFwaGljc106OkZyb21JbWFnZSgkYm1wKQ0KJGcuU21vb3RoaW5nTW9kZSA9IFtTeXN0ZW0uRHJhd2luZy5EcmF3aW5nMkQuU21vb3RoaW5nTW9kZV06OkFudGlBbGlhcw0KJGJydXNoID0gTmV3LU9iamVjdCBTeXN0ZW0uRHJhd2luZy5Tb2xpZEJydXNoIChbU3lzdGVtLkRyYXdpbmcuQ29sb3JdOjpGcm9tQXJnYig0NiwgMjA0LCAxMTMpKQ0KJGcuRmlsbEVsbGlwc2UoJGJydXNoLCAxLCAxLCAxNCwgMTQpDQokcGVuID0gTmV3LU9iamVjdCBTeXN0ZW0uRHJhd2luZy5QZW4gKFtTeXN0ZW0uRHJhd2luZy5Db2xvcl06OkZyb21BcmdiKDM5LCAxNzQsIDk2KSwgMSkNCiRnLkRyYXdFbGxpcHNlKCRwZW4sIDEsIDEsIDEzLCAxMykNCiRoSWNvbiA9ICRibXAuR2V0SGljb24oKQ0KJGljb24gPSBbU3lzdGVtLkRyYXdpbmcuSWNvbl06OkZyb21IYW5kbGUoJGhJY29uKQ0KDQokbm90aWZ5ID0gTmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5Ob3RpZnlJY29uDQokbm90aWZ5Lkljb24gPSAkaWNvbg0KJG5vdGlmeS5UZXh0ID0gIlhyYXkgVlBOOiBDb25uZWN0ZWQiDQokbm90aWZ5LlZpc2libGUgPSAkdHJ1ZQ0KDQokbWVudSA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuQ29udGV4dE1lbnUNCiRpdGVtU3RhdHVzID0gTmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5NZW51SXRlbSAiWHJheSBWUE46IENvbm5lY3RlZCINCiRpdGVtU3RhdHVzLkVuYWJsZWQgPSAkZmFsc2UNCiRpdGVtU2VwID0gTmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5NZW51SXRlbSAiLSINCiRpdGVtU3RvcCA9IE5ldy1PYmplY3QgU3lzdGVtLldpbmRvd3MuRm9ybXMuTWVudUl0ZW0gIkRpc2Nvbm5lY3QgJiBFeGl0Ig0KDQokaXRlbVN0b3AuYWRkX0NsaWNrKHsNCiAgICAkbm90aWZ5LlZpc2libGUgPSAkZmFsc2UNCiAgICAkbm90aWZ5LkRpc3Bvc2UoKQ0KICAgIFN0YXJ0LVByb2Nlc3MgIndzY3JpcHQuZXhlIiAtQXJndW1lbnRMaXN0ICciQzpcWFJBWV9WUE5cU3RvcF9WUE4udmJzIicgLVdpbmRvd1N0eWxlIEhpZGRlbg0KICAgIFtTeXN0ZW0uV2luZG93cy5Gb3Jtcy5BcHBsaWNhdGlvbl06OkV4aXQoKQ0KfSkNCg0KW3ZvaWRdJG1lbnUuTWVudUl0ZW1zLkFkZCgkaXRlbVN0YXR1cykNClt2b2lkXSRtZW51Lk1lbnVJdGVtcy5BZGQoJGl0ZW1TZXApDQpbdm9pZF0kbWVudS5NZW51SXRlbXMuQWRkKCRpdGVtU3RvcCkNCiRub3RpZnkuQ29udGV4dE1lbnUgPSAkbWVudQ0KDQojIFdhdGNoZG9nIGZvciB4cmF5LmV4ZS4gSWYgeHJheSBzdG9wcywgdHJheSBpY29uIGNsb3NlcyBhdXRvbWF0aWNhbGx5IQ0KJHRpbWVyID0gTmV3LU9iamVjdCBTeXN0ZW0uV2luZG93cy5Gb3Jtcy5UaW1lcg0KJHRpbWVyLkludGVydmFsID0gMTAwMAsNCiR0aW1lci5hZGRfVGljayh7DQogICAgJHByb2MgPSBHZXQtUHJvY2VzcyB4cmF5IC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlDQogICAgaWYgKC1ub3QgJHByb2MpIHsNCiAgICAgICAgJHRpbWVyLlN0b3AoKQ0KICAgICAgICAkbm90aWZ5LlZpc2libGUgPSAkZmFsc2UNCiAgICAgICAgJG5vdGlmeS5EaXNwb3NlKCkNCiAgICAgICAgW1N5c3RlbS5XaW5kb3dzLkZvcm1zLkFwcGxpY2F0aW9uXTo6RXhpdCgpDQogICAgfQ0KfSkNCiR0aW1lci5TdGFydCgpDQoNCiRub3RpZnkuU2hvd0JhbGxvb25UaXAoMzAwMCwgIlhyYXkgVlBOIiwgIkNvbm5lY3RlZCEgUmlnaHQtY2xpY2sgaWNvbiB0byBkaXNjb25uZWN0LiIsIFtTeXN0ZW0uV2luZG93cy5Gb3Jtcy5Ub29sVGlwSWNvbl06OkluZm8pDQpbU3lzdGVtLldpbmRvd3MuRm9ybXMuQXBwbGljYXRpb25dOjpSdW4oKQ0K"))

# 4. Deploy link.txt
if (-not (Test-Path "$dir\link.txt")) {
    [System.IO.File]::WriteAllText("$dir\link.txt", "", [System.Text.Encoding]::UTF8)
}

# 5. Deploy Silent VBS Launchers
$v1 = 'Set WshShell = CreateObject("WScript.Shell")' + "`r`n" + 'WshShell.Run "powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""C:\XRAY_VPN\Start_VPN.ps1""", 0, False'
$v2 = 'Set WshShell = CreateObject("WScript.Shell")' + "`r`n" + 'WshShell.Run "powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""C:\XRAY_VPN\Stop_VPN.ps1""", 0, False'
[System.IO.File]::WriteAllText("$dir\Start_VPN.vbs", $v1, [System.Text.Encoding]::ASCII)
[System.IO.File]::WriteAllText("$dir\Stop_VPN.vbs", $v2, [System.Text.Encoding]::ASCII)

# 6. Create Shortcuts inside C:\XRAY_VPN
Write-Host "[*] Creating shortcuts (Start, Stop, Check_IP)..." -ForegroundColor Cyan
$w = New-Object -ComObject WScript.Shell
$s1 = $w.CreateShortcut("$dir\Start_VPN.lnk")
$s1.TargetPath = "wscript.exe"
$s1.Arguments = '""C:\XRAY_VPN\Start_VPN.vbs""'
$s1.WorkingDirectory = $dir
$s1.IconLocation = "shell32.dll,137"
$s1.Description = "Start XRAY VPN"
$s1.Save()

$s2 = $w.CreateShortcut("$dir\Stop_VPN.lnk")
$s2.TargetPath = "wscript.exe"
$s2.Arguments = '""C:\XRAY_VPN\Stop_VPN.vbs""'
$s2.WorkingDirectory = $dir
$s2.IconLocation = "shell32.dll,27"
$s2.Description = "Stop XRAY VPN"
$s2.Save()

$u = "[InternetShortcut]`r`nURL=https://prodvig-saita.ru/ip/`r`nIconFile=C:\Windows\System32\shell32.dll`r`nIconIndex=14`r`n"
[System.IO.File]::WriteAllText("$dir\Check_IP.url", $u, [System.Text.Encoding]::ASCII)

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host " [SUCCESS] XRAY_VPN 100% INSTALLED AND READY IN $dir!" -ForegroundColor Green
Write-Host " 1. Paste your VLESS key into Notepad (link.txt) and Save (Ctrl+S)." -ForegroundColor Green
Write-Host " 2. Double-click 'Start_VPN' to connect." -ForegroundColor Green
Write-Host " 3. Click 'Check_IP' to verify your new IP address." -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green
Write-Host ""

Start-Process "explorer.exe" -ArgumentList $dir
Start-Process "notepad.exe" -ArgumentList "$dir\link.txt"
