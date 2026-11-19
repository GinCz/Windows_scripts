#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <stdio.h>

BOOL IsAdmin(void) {
    HANDLE h = CreateFileW(L"\\\\.\\PHYSICALDRIVE0", GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if (h != INVALID_HANDLE_VALUE) {
        CloseHandle(h);
        return TRUE;
    }
    return FALSE;
}

void RunSelfAsAdmin(LPCWSTR args) {
    WCHAR exe[MAX_PATH];
    GetModuleFileNameW(NULL, exe, MAX_PATH);
    ShellExecuteW(NULL, L"runas", exe, args, NULL, SW_SHOWNORMAL);
}

void RemoveDirectoryRecursive(LPCWSTR sPath) {
    WCHAR sDir[MAX_PATH];
    WIN32_FIND_DATAW fd;
    swprintf(sDir, MAX_PATH, L"%s\\*.*", sPath);
    HANDLE hFind = FindFirstFileW(sDir, &fd);
    if (hFind != INVALID_HANDLE_VALUE) {
        do {
            if (wcscmp(fd.cFileName, L".") != 0 && wcscmp(fd.cFileName, L"..") != 0) {
                WCHAR sFile[MAX_PATH];
                swprintf(sFile, MAX_PATH, L"%s\\%s", sPath, fd.cFileName);
                if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                    RemoveDirectoryRecursive(sFile);
                } else {
                    SetFileAttributesW(sFile, FILE_ATTRIBUTE_NORMAL);
                    DeleteFileW(sFile);
                }
            }
        } while (FindNextFileW(hFind, &fd));
        FindClose(hFind);
    }
    RemoveDirectoryW(sPath);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow) {
    if (!IsAdmin()) {
        RunSelfAsAdmin(lpCmdLine);
        return 0;
    }

    int argc = 0;
    LPWSTR *argv = CommandLineToArgvW(GetCommandLineW(), &argc);

    // Phase 2: Running from %TEMP% as external cleanup agent
    if (argc >= 3 && wcscmp(argv[1], L"--cleanup") == 0) {
        LPCWSTR targetDir = argv[2];
        Sleep(800);

        // Terminate any lingering wallpaper processes
        system("taskkill /F /IM GIN-Wallpaper-Calend.exe >nul 2>&1");

        // Wipe target directory
        for (int i = 0; i < 15; i++) {
            RemoveDirectoryRecursive(targetDir);
            DWORD dwAttr = GetFileAttributesW(targetDir);
            if (dwAttr == INVALID_FILE_ATTRIBUTES) break;
            Sleep(300);
        }

        // Clean AppData cache
        WCHAR appData[MAX_PATH];
        if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_APPDATA, NULL, 0, appData))) {
            WCHAR targetAppData[MAX_PATH];
            swprintf(targetAppData, MAX_PATH, L"%s\\GIN-Wallpaper-Calend", appData);
            RemoveDirectoryRecursive(targetAppData);
        }

        // Schedule self-delete of this temp executable
        WCHAR selfExe[MAX_PATH];
        GetModuleFileNameW(NULL, selfExe, MAX_PATH);
        WCHAR cmd[MAX_PATH * 2];
        swprintf(cmd, sizeof(cmd)/sizeof(WCHAR), L"/C ping 127.0.0.1 -n 3 >nul & del /F /Q \"%s\"", selfExe);
        ShellExecuteW(NULL, L"open", L"cmd.exe", cmd, NULL, SW_HIDE);
        return 0;
    }

    // Phase 1: User launched Uninstall.exe
    system("taskkill /F /IM GIN-Wallpaper-Calend.exe >nul 2>&1");
    Sleep(400);

    // Remove registry keys
    system("reg delete HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\GIN-Wallpaper-Calend /f >nul 2>&1");
    system("reg delete HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\GIN-Wallpaper-Calend /f >nul 2>&1");
    system("reg delete HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v GIN-Wallpaper-Calend /f >nul 2>&1");

    // Remove shortcuts
    DeleteFileW(L"D:\\MEGA\\DOCS\\desktop\\GIN-Wallpaper-Calend.lnk");
    DeleteFileW(L"D:\\mega\\docs\\desktop\\GIN-Wallpaper-Calend.lnk");

    WCHAR path[MAX_PATH];
    if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_DESKTOPDIRECTORY, NULL, 0, path))) {
        WCHAR lnk[MAX_PATH];
        swprintf(lnk, MAX_PATH, L"%s\\GIN-Wallpaper-Calend.lnk", path);
        DeleteFileW(lnk);
    }
    if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_COMMON_DESKTOPDIRECTORY, NULL, 0, path))) {
        WCHAR lnk[MAX_PATH];
        swprintf(lnk, MAX_PATH, L"%s\\GIN-Wallpaper-Calend.lnk", path);
        DeleteFileW(lnk);
    }
    if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_PROGRAMS, NULL, 0, path))) {
        WCHAR lnk[MAX_PATH];
        swprintf(lnk, MAX_PATH, L"%s\\GIN-Wallpaper-Calend.lnk", path);
        DeleteFileW(lnk);
    }

    // Copy self to %TEMP% to unlock installation directory and wipe it
    WCHAR selfExe[MAX_PATH];
    GetModuleFileNameW(NULL, selfExe, MAX_PATH);

    WCHAR instDir[MAX_PATH];
    wcscpy(instDir, selfExe);
    WCHAR *pSlash = wcsrchr(instDir, L'\\');
    if (pSlash) *pSlash = L'\0';

    WCHAR tempDir[MAX_PATH];
    GetTempPathW(MAX_PATH, tempDir);
    WCHAR tempUninst[MAX_PATH];
    swprintf(tempUninst, MAX_PATH, L"%sGIN-Wallpaper_Uninstall_%lu.exe", tempDir, GetTickCount());

    if (CopyFileW(selfExe, tempUninst, FALSE)) {
        WCHAR args[MAX_PATH * 2];
        swprintf(args, sizeof(args)/sizeof(WCHAR), L"--cleanup \"%s\"", instDir);
        ShellExecuteW(NULL, L"open", tempUninst, args, tempDir, SW_HIDE);
        return 0;
    }

    return 0;
}
