# Windows SMB3 Connection

## Purpose

This guide connects Windows 10 and Windows 11 to a Samba share after the server has been hardened to SMB3 with signing and encryption.

## Important behavior

The Windows client keeps the same server name, share name, username, password, and UNC path. The server negotiates the secure SMB dialect automatically. No SMB1 feature or NetBIOS name resolution is required.

## Drive-letter connection

Run `SMB3_Connect.bat` from a normal Windows command prompt. Enter the server address, share name, drive letter, and SMB username. Windows will prompt for the password.

Manual example:

```cmd
net use T: "\\server.example\storage" /user:vlad * /persistent:yes
```

Do not put passwords into batch files, command history, GitHub, or screenshots.

## Direct Explorer access

Use the existing UNC path in the File Explorer address bar:

```text
\\server.example\storage
```

## Troubleshooting

```cmd
net use
net use T: /delete /y
net view \\server.example
```

If the connection fails, verify TCP 445, the SMB username, the share name, and that the server still permits the client source network.

= Rooted by VladiMIR + AI | v.2026.08.08 | github.com/GinCz =