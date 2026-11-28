# Windows Networking, SMB & VPN Tools

> Repository: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Directory: `tools/network/`

Automated network diagnostic scripts, SMB3 persistent mount managers, and VPN protocol launchers for Windows 10/11.

---

## ⚡ Tool Catalog

| Script | Purpose | Key Architecture |
| :--- | :--- | :--- |
| `SMB_Connect.bat` | Samba Mount | Mounts network shares with automatic credential resolution and reconnect triggers |
| `SMB3_Connect.bat` | SMB3 High-Security | Enforces SMB 3.1.1 encryption and dialect negotiation with fallback handling |
| `SMB_Test.bat` | Diagnostics | Tests network latency, port 445 availability, and SMB protocol negotiation |
| `Install_XRAY_VPN.cmd` / `.ps1` | VLESS Reality | Deploys Xray core client with Reality anti-censorship routing configuration |
| `Hiddify__INSTALL_&&&.bat` | Proxy Client | Installs Hiddify Next client with TUN mode network adapter routing |
| `Hiddify__SAVE_(admin).bat` | Backup | Exports active Hiddify subscription and routing profiles |
| `Hiddify__LOAD_(admin).bat` | Restore | Restores Hiddify profiles onto fresh workstation |

---

## 🚀 Execution

All network scripts should be executed with Administrator privileges to permit mounting network drives and binding tunnel adapters.
