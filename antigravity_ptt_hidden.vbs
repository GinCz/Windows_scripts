Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
localAppData = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")
progFiles = WshShell.ExpandEnvironmentStrings("%ProgramFiles%")

nodePath = ""
If fso.FileExists(localAppData & "\OpenClaw\deps\portable-node\node.exe") Then
    nodePath = localAppData & "\OpenClaw\deps\portable-node\node.exe"
ElseIf fso.FileExists(progFiles & "\nodejs\node.exe") Then
    nodePath = progFiles & "\nodejs\node.exe"
ElseIf fso.FileExists(localAppData & "\Programs\node\node.exe") Then
    nodePath = localAppData & "\Programs\node\node.exe"
Else
    nodePath = "node.exe"
End If

scriptPath = "D:\AI\GitHub\Windows_scripts\antigravity_ptt_daemon.js"

WshShell.Run """" & nodePath & """ """ & scriptPath & """", 0, False
