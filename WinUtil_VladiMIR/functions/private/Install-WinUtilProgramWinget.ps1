Function Install-WinUtilProgramWinget {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    foreach ($program in $Programs) {
        if ([string]::IsNullOrWhiteSpace($program) -or $program -eq "na") {
            continue
        }

        if ($program.StartsWith("installer:", [System.StringComparison]::OrdinalIgnoreCase) -or $program.StartsWith("custom:", [System.StringComparison]::OrdinalIgnoreCase)) {
            $fileName = $program -replace '^(installer:|custom:)', ''
            $localCandidates = @(
                "D:\AI\GitHub\Windows_scripts\WinUtil_VladiMIR\installers\$fileName",
                "$PSScriptRoot\installers\$fileName",
                "$PSScriptRoot\..\installers\$fileName",
                "$PSScriptRoot\..\..\installers\$fileName",
                "C:\UTIL\$fileName",
                "$env:TEMP\$fileName"
            )
            $targetExe = $localCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

            if (-not $targetExe) {
                $targetExe = Join-Path $env:TEMP $fileName
                $rawUrl = "https://raw.githubusercontent.com/GinCz/Windows_scripts/main/WinUtil_VladiMIR/installers/$fileName"
                Write-WinUtilLog -Component "Package" -Message "Downloading custom installer from GitHub: $rawUrl"
                try {
                    Invoke-WebRequest -Uri $rawUrl -OutFile $targetExe -UseBasicParsing -ErrorAction Stop
                } catch {
                    Write-WinUtilLog -Component "Package" -Level "ERROR" -Message "Failed to download $fileName : $($_.Exception.Message)"
                }
            }

            if (Test-Path $targetExe) {
                Write-WinUtilLog -Component "Package" -Message "Executing custom installer: $targetExe"
                try {
                    $proc = Start-Process -FilePath $targetExe -ArgumentList "/S", "/silent", "/VERYSILENT", "/quiet" -PassThru -ErrorAction SilentlyContinue
                    if ($proc) {
                        $exited = $proc.WaitForExit(300000)
                    }

                    # Custom configuration for Notepad++ 5.0.3 (match custom component tree)
                    if ($fileName -like "*NOTEPAD++*") {
                        $nppDirs = @(
                            "C:\Program Files (x86)\Notepad++",
                            "C:\Program Files\Notepad++"
                        )
                        $nppPath = $nppDirs | Where-Object { Test-Path $_ } | Select-Object -First 1
                        if ($nppPath) {
                            # 1. Don't use %APPDATA unchecked -> remove doLocalConf.xml so APPDATA is used
                            $doLocal = Join-Path $nppPath "doLocalConf.xml"
                            if (Test-Path $doLocal) { Remove-Item -Path $doLocal -Force -ErrorAction SilentlyContinue }

                            # 2. Plugins & Auto-completion unchecked -> clean plugins folder
                            $pluginsDir = Join-Path $nppPath "plugins"
                            if (Test-Path $pluginsDir) {
                                Get-ChildItem -Path $pluginsDir -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                                Get-ChildItem -Path $pluginsDir -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                            }

                            # 3. Auto-Updater unchecked -> remove updater folder
                            $updaterDir = Join-Path $nppPath "updater"
                            if (Test-Path $updaterDir) { Remove-Item -Path $updaterDir -Recurse -Force -ErrorAction SilentlyContinue }

                            # 4. Context Menu Entry checked -> register context menu in Registry & shell DLL
                            $nppExe = Join-Path $nppPath "notepad++.exe"
                            $nppDll = Join-Path $nppPath "nppcm.dll"
                            if (Test-Path $nppDll) {
                                Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s `"$nppDll`"" -Wait -ErrorAction SilentlyContinue
                            }

                            $regPaths = @(
                                "HKLM:\SOFTWARE\Classes\*\shell\Open with Notepad++",
                                "HKCU:\Software\Classes\*\shell\Open with Notepad++",
                                "HKLM:\SOFTWARE\Classes\Directory\shell\Open with Notepad++"
                            )
                            foreach ($rp in $regPaths) {
                                if (-not (Test-Path $rp)) { New-Item -Path $rp -Force -ErrorAction SilentlyContinue | Out-Null }
                                Set-ItemProperty -Path $rp -Name "(default)" -Value "Edit with Notepad++" -Force -ErrorAction SilentlyContinue | Out-Null
                                Set-ItemProperty -Path $rp -Name "Icon" -Value "`"$nppExe`"" -Force -ErrorAction SilentlyContinue | Out-Null
                                $cmdPath = Join-Path $rp "command"
                                if (-not (Test-Path $cmdPath)) { New-Item -Path $cmdPath -Force -ErrorAction SilentlyContinue | Out-Null }
                                Set-ItemProperty -Path $cmdPath -Name "(default)" -Value "`"$nppExe`" `"%1`"" -Force -ErrorAction SilentlyContinue | Out-Null
                            }
                            Write-WinUtilLog -Component "Package" -Message "Notepad++ 5.0.3 custom component setup and Context Menu registered."
                        }
                    }

                    Write-WinUtilLog -Component "Package" -Message "Custom installer finished: $fileName"
                } catch {
                    Start-Process -FilePath $targetExe
                }
            }
            continue
        }

        $source = "winget"
        if ($program.StartsWith("msstore:", [System.StringComparison]::OrdinalIgnoreCase)) {
            $source = "msstore"
            $program = $program.Substring("msstore:".Length)
        }

        if ($Action -eq 'Install') {
            $arguments = @("install", "--id", $program, "--accept-package-agreements", "--accept-source-agreements", "--source", $source, "--silent")
        } else {
            $arguments = @("uninstall", "--id", $program, "--source", $source, "--silent")
        }

        Write-WinUtilLog -Component "Package" -Message "$Action winget package: $program (source: $source)"

        $timeoutMs = if ($Action -eq 'Install') { 300000 } else { 60000 }
        $executedSuccessfully = $false
        try {
            $process = Start-Process -FilePath winget -ArgumentList $arguments -NoNewWindow -PassThru -ErrorAction Stop
            $exited = $process.WaitForExit($timeoutMs)
            if (-not $exited) {
                $process.Kill()
                Write-WinUtilLog -Component "Package" -Level "WARN" -Message "winget $Action timed out ($($timeoutMs/1000)s) for $program"
            } else {
                $executedSuccessfully = ($process.ExitCode -eq 0)
                Write-WinUtilLog -Component "Package" -Message "$Action winget package completed: $program (exit code: $($process.ExitCode))"
            }
        } catch {
            Write-WinUtilLog -Component "Package" -Level "WARN" -Message "winget execution failed: $($_.Exception.Message)"
        }

        # If Uninstall failed or timed out via winget, fallback to direct Registry uninstaller
        if ($Action -eq 'Uninstall' -and -not $executedSuccessfully) {
            Write-WinUtilLog -Component "Package" -Message "Attempting registry uninstallation for: $program"
            $uninstallPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
            )
            $target = Get-ItemProperty $uninstallPaths -ErrorAction SilentlyContinue | Where-Object { 
                ($_.DisplayName -and ($_.DisplayName -match [regex]::Escape($program) -or $program -match [regex]::Escape($_.DisplayName))) -or
                ($_.PSChildName -and $_.PSChildName -eq $program)
            } | Select-Object -First 1

            if ($target) {
                $cmd = if ($target.QuietUninstallString) { $target.QuietUninstallString } else { $target.UninstallString }
                if ($cmd) {
                    Write-WinUtilLog -Component "Package" -Message "Running registry uninstall command: $cmd"
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -NoNewWindow -Wait -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
