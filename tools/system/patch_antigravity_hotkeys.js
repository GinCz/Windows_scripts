// ==========================================================================================
//  Patch Antigravity Hotkeys (F4, Alt+M, Ctrl+M, Ctrl+D) for Safe Microphone Toggle
// ==========================================================================================
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

process.noAsar = true;

const LOCALAPPDATA = process.env.LOCALAPPDATA || path.join(process.env.USERPROFILE, 'AppData', 'Local');
const NODE_EXE = path.join(LOCALAPPDATA, 'Programs', 'antigravity', 'Antigravity.exe');
const WORK_DIR = path.join(process.env.TEMP || 'C:\\Windows\\Temp', 'patch_antigravity_asar');
const PRIMARY_ASAR = path.join(LOCALAPPDATA, 'Programs', 'antigravity', 'resources', 'app.asar');

const ASAR_TOOL_CANDIDATES = [
  path.join(LOCALAPPDATA, 'npm-cache', '_npx', '4b0e2640fe917ac8', 'node_modules', '@electron', 'asar', 'bin', 'asar.mjs'),
  path.join(process.env.APPDATA || '', 'npm', 'node_modules', '@electron', 'asar', 'bin', 'asar.mjs')
];

function findAsarTool() {
  for (const p of ASAR_TOOL_CANDIDATES) {
    if (fs.existsSync(p)) return p;
  }
  return null;
}

async function main() {
  console.log('=== Patching Antigravity Keybindings ===');
  if (!fs.existsSync(PRIMARY_ASAR)) {
    throw new Error('No app.asar found at: ' + PRIMARY_ASAR);
  }

  if (fs.existsSync(WORK_DIR)) {
    fs.rmSync(WORK_DIR, { recursive: true, force: true });
  }
  fs.mkdirSync(WORK_DIR, { recursive: true });

  const bakPath = PRIMARY_ASAR + '.bak';
  if (!fs.existsSync(bakPath)) {
    fs.copyFileSync(PRIMARY_ASAR, bakPath);
    console.log('Backup created: ' + bakPath);
  }

  const asarTool = findAsarTool();
  const unpackedDir = path.join(WORK_DIR, 'unpacked');

  if (asarTool) {
    execSync(`"${NODE_EXE}" "${asarTool}" extract "${PRIMARY_ASAR}" "${unpackedDir}"`, {
      env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }
    });
  } else {
    execSync(`npx @electron/asar extract "${PRIMARY_ASAR}" "${unpackedDir}"`, {
      env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }
    });
  }

  const keybindingsPath = path.join(unpackedDir, 'dist', 'keybindings.js');
  const fixedCode = `"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.registerKeybindings = registerKeybindings;
const utils_1 = require("./utils");
function registerKeybindings(win, actions) {
    win.webContents.on('before-input-event', (event, input) => {
        if (input.type === 'keyDown') {
            const isCmdOrCtrl = (0, utils_1.isMacOS)() ? input.meta : input.control;
            const isAlt = input.alt && !input.control && !input.meta;
            const isD = input.code === 'KeyD' || (input.key && input.key.toLowerCase() === 'd') || (input.key && input.key.toLowerCase() === 'в');
            const isM = input.code === 'KeyM' || (input.key && input.key.toLowerCase() === 'm') || (input.key && input.key.toLowerCase() === 'ь');
            const isF4 = input.code === 'F4' || input.key === 'F4';

            // Hotkeys: F4, Alt+M, Ctrl+M, Ctrl+D
            if (isF4 || (isCmdOrCtrl && (isD || isM)) || (isAlt && isM)) {
                event.preventDefault();
                win.webContents.executeJavaScript(\`(() => {
                    let btn = document.querySelector('button[data-tooltip-id="input-send-button-record-tooltip"]');
                    if (!btn) {
                        const strictSelectors = [
                            'button[aria-label="Stop recording"]',
                            'button[aria-label="Record voice memo"]',
                            'button[aria-label="Record voice"]',
                            'button[aria-label="Остановить запись"]',
                            'button[aria-label="Начать запись"]',
                            'button[aria-label="Диктовка"]',
                            'button[aria-label="Микрофон"]',
                            'button[data-testid="mic-button"]',
                            'button[data-testid="record-button"]'
                        ];
                        btn = document.querySelector(strictSelectors.join(','));
                    }
                    if (!btn) {
                        const allButtons = Array.from(document.querySelectorAll('button'));
                        btn = allButtons.find(b => {
                            const aria = (b.getAttribute('aria-label') || '').toLowerCase();
                            const title = (b.getAttribute('title') || '').toLowerCase();
                            const testid = (b.getAttribute('data-testid') || '').toLowerCase();
                            const isTaskControl = aria.includes('generation') || aria.includes('task') ||
                                                  aria.includes('process') || aria.includes('command') ||
                                                  aria.includes('cancel') || aria.includes('abort') ||
                                                  testid.includes('stop') || (aria === 'stop' && !aria.includes('record'));
                            if (isTaskControl) return false;
                            return aria.includes('record') || aria.includes('voice') || aria.includes('mic') ||
                                   title.includes('record') || title.includes('voice') || title.includes('mic') ||
                                   testid.includes('record') || testid.includes('voice') || testid.includes('mic') ||
                                   aria.includes('запись') || aria.includes('диктовка') || aria.includes('микрофон');
                        });
                    }
                    if (btn) btn.click();
                })()\`).catch(() => {});
                return;
            }

            if (isCmdOrCtrl && input.shift && input.key.toLowerCase() === 'n') {
                actions.createNewWindow();
                event.preventDefault();
            }
            if (isCmdOrCtrl && input.key.toLowerCase() === 'q') {
                actions.onQuitRequested();
                event.preventDefault();
            }
        }
    });
}
`;
  fs.writeFileSync(keybindingsPath, fixedCode, 'utf8');

  const newAsarPath = path.join(WORK_DIR, 'app.asar');
  if (asarTool) {
    execSync(`"${NODE_EXE}" "${asarTool}" pack "${unpackedDir}" "${newAsarPath}"`, {
      env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }
    });
  } else {
    execSync(`npx @electron/asar pack "${unpackedDir}" "${newAsarPath}"`, {
      env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }
    });
  }

  fs.copyFileSync(newAsarPath, PRIMARY_ASAR);
  console.log('Updated: ' + PRIMARY_ASAR);

  fs.rmSync(WORK_DIR, { recursive: true, force: true });
  console.log('Patch complete and verified.');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
