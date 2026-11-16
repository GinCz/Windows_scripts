# 🌐 GIN-DNS-Switch — Project Directives & Build Rules (`RULES.md`)
> **Standard for Development, Building, Versioning, and Release Delivery of GIN-DNS-Switch.**  
> *Author:* Vladimir Bulantsev (@GinCz) | *Repository:* `Windows_scripts/GIN-DNS-Switch` | *Version:* v2026-11

---

## 🎯 MANDATORY RELEASE DELIVERY TARGETS (DEFAULT PATHS)

Every new release, build, or version increment of `GIN-DNS-Switch` (`GIN-DNS-Switch_vXXX_Setup.exe`) MUST be saved strictly and exclusively to the following two default cloud locations:

1. **Primary Utility Storage (Flash & Archive):**
   - **Local Windows Path:** `D:\MEGA\WIN-FLASH\Util-WINDOWS\N E T\GIN-DNS-Switch_vXXX_Setup.exe`
   - **MEGA Cloud Path:** `/MEGA/WIN-FLASH/Util-WINDOWS/N E T/` (`mega-put -c <installer> "/MEGA/WIN-FLASH/Util-WINDOWS/N E T/"`)

2. **Vladimir's Cloud Desktop:**
   - **Local Windows Path:** `D:\MEGA\DOCS\desktop\GIN-DNS-Switch_vXXX_Setup.exe`
   - **MEGA Cloud Path:** `/MEGA/DOCS/desktop/` (`mega-put -c <installer> "/MEGA/DOCS/desktop/"`)

> [!IMPORTANT]
> **Strict Retention & Location Ban:**
> - Categorically forbidden to save releases to standard unmonitored Windows desktop, `/tmp`, or server shares.
> - Only these two locations (`WIN-FLASH/Util-WINDOWS/N E T` and `DOCS/desktop`) are authorized.
> - Retain strictly the 2 latest versions in deployment mirrors (purge older via `mega-rm`).

---

## ⚡ BUILD & VERSIONING PROTOCOL

1. **Version Format:** Strictly lowercase `v` followed by 3 digits (`v012`, `v013`, `v014`).
2. **Synchronized Metadata:**
   - Increment `version.json` (both root and `src/`).
   - Update `app.rc` and recompile resources with `windres`.
   - Update `README.md` download links and badges.
   - Record changes in `src/WORKLOG.md`.
3. **Automated Build & Delivery Script:**
   - Run `src/build_release.sh`.
   - The script builds `Uninstall.exe` and `GIN-DNS-Switch_vXXX_Setup.exe`, then automatically delivers them to both MEGA targets via `mega-put`.
