Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
localAppData = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")
progFiles = WshShell.ExpandEnvironmentStrings("%ProgramFiles%")

nodePath = ""
If fso.FileExists(localAppData & "\OpenClaw\deps\portable-node\node.exe") Then
    nodePath = localAppData & "\OpenClaw\deps\portable-node\node.exe"
ElseIf fso.FileExists(localAppData & "\OpenAI\Codex\runtimes\cua_node\1b25664590014d28\bin\node.exe") Then
    nodePath = localAppData & "\OpenAI\Codex\runtimes\cua_node\1b25664590014d28\bin\node.exe"
ElseIf fso.FileExists("C:\UTIL\node\node.exe") Then
    nodePath = "C:\UTIL\node\node.exe"
ElseIf fso.FileExists(progFiles & "\nodejs\node.exe") Then
    nodePath = progFiles & "\nodejs\node.exe"
ElseIf fso.FileExists(localAppData & "\Programs\node\node.exe") Then
    nodePath = localAppData & "\Programs\node\node.exe"
Else
    nodePath = "node.exe"
End If

scriptPath = ""
If fso.FileExists("D:\AI\GitHub\Windows_scripts\antigravity_ptt_daemon.js") Then
    scriptPath = "D:\AI\GitHub\Windows_scripts\antigravity_ptt_daemon.js"
ElseIf fso.FileExists("C:\UTIL\Antigravity_AI\GitHub\Windows_scripts\antigravity_ptt_daemon.js") Then
    scriptPath = "C:\UTIL\Antigravity_AI\GitHub\Windows_scripts\antigravity_ptt_daemon.js"
Else
    scriptPath = userProfile & "\.gemini\antigravity\scripts\antigravity_ptt_daemon.js"
End If

If fso.FileExists(scriptPath) Then
    WshShell.Run """" & nodePath & """ """ & scriptPath & """", 0, False
End If
