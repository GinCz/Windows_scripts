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
