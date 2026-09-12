// ==========================================================================================
//  Patch Antigravity Hotkeys (F4, Alt+M, Ctrl+M, Ctrl+D) for Safe Microphone Toggle
// ==========================================================================================
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

process.noAsar = true;

const ASAR_TOOL = 'C:\\Users\\USER\\AppData\\Local\\npm-cache\\_npx\\4b0e2640fe917ac8\\node_modules\\@electron\\asar\\bin\\asar.mjs';
const NODE_EXE = 'C:\\Users\\AI\\AppData\\Local\\Programs\\antigravity\\Antigravity.exe';
const WORK_DIR = 'D:\\AI\\patch_antigravity_asar';
const TARGET_ASARS = [
  'C:\\Users\\AI\\AppData\\Local\\Programs\\antigravity\\resources\\app.asar',
  'C:\\Users\\USER\\AppData\\Local\\Programs\\antigravity\\resources\\app.asar'
];

async function main() {
  console.log('=== Patching Antigravity Keybindings ===');
  if (fs.existsSync(WORK_DIR)) {
    fs.rmSync(WORK_DIR, { recursive: true, force: true });
  }
  fs.mkdirSync(WORK_DIR, { recursive: true });

  const primaryAsar = TARGET_ASARS.find(p => fs.existsSync(p));
  if (!primaryAsar) throw new Error('No app.asar found');

  const bakPath = primaryAsar + '.bak';
  if (!fs.existsSync(bakPath)) {
    fs.copyFileSync(primaryAsar, bakPath);
  }

  const unpackedDir = path.join(WORK_DIR, 'unpacked');
  execSync(`"${NODE_EXE}" "${ASAR_TOOL}" extract "${primaryAsar}" "${unpackedDir}"`, {
    env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }
  });

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
  execSync(`"${NODE_EXE}" "${ASAR_TOOL}" pack "${unpackedDir}" "${newAsarPath}"`, {
    env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }
  });

  for (const asarPath of TARGET_ASARS) {
    if (fs.existsSync(path.dirname(asarPath))) {
      fs.copyFileSync(newAsarPath, asarPath);
      console.log('Updated: ' + asarPath);
    }
  }

  fs.rmSync(WORK_DIR, { recursive: true, force: true });
  console.log('Patch complete and verified.');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
