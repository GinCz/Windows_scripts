# Remote Support & Unattended Access Utilities

> Repository: [GinCz/Windows_scripts](https://github.com/GinCz/Windows_scripts)  
> Author: [Vladimir Bulantsev (@GinCz)](https://github.com/GinCz)  
> Directory: `tools/remote/`

Enterprise scripts for deploying, backing up, and restoring remote desktop configuration profiles across client workstations.

---

## ⚡ Tool Catalog

| Script | Protocol / App | Description | Mode |
| :--- | :--- | :--- | :--- |
| `RustDesk_Setup_x64_&&&.bat` | RustDesk | Unattended 1-click RustDesk deployment with pre-configured server keys | Automated |
| `RustDesk_peers___SAVE_(S+Mega).bat` | RustDesk | Exports address book, trusted peers, and ID tokens to secure backup shares | Automated Backup |
| `RustDesk_peers___LOAD.bat` | RustDesk | Restores peers and settings on a newly provisioned workstation | Automated Restore |
| `AnyDesk_SAVE_USERS.bat` | AnyDesk | Backs up `user.conf`, whitelist ID history, and security settings | Backup |
| `AnyDesk_LOAD_USERS.bat` | AnyDesk | Deploys saved AnyDesk user configuration to new machine | Restore |
| `SupRemo_Setup_&&&.bat` | Supremo Remote | Fast portable unattended setup for quick remote troubleshooting | On-demand |

---

## 🔒 Security Best Practice

These scripts handle client ID and configuration tokens. Sensitive connection tokens and private address books must remain in encrypted personal storage and should never be committed into public repositories.
