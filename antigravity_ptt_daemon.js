// ==========================================================================================
//  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  Antigravity Push-to-Talk Daemon | [v2026-08-15_a]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
// ==========================================================================================
// Safe, zero-modification Push-to-Talk (Ctrl+D) for Google Antigravity
// Injects via local DevTools debugging port without altering any program files.

const fs = require('fs');
const path = require('path');

const PORT_FILE = path.join(process.env.APPDATA, 'Antigravity', 'DevToolsActivePort');

const PTT_CODE = `
(() => {
  if (window.__pushToTalkInstalled) return;
  window.__pushToTalkInstalled = true;
  window.__isPTTActive = false;

  function getMicButton() {
    return document.querySelector('button[data-tooltip-id="input-send-button-record-tooltip"], button[aria-label*="Record voice"], button[aria-label*="Record"]');
  }

  function getStopOrSendButton() {
    return document.querySelector('button[aria-label*="Stop"], button[data-tooltip-id="input-send-button-record-tooltip"], button[aria-label*="Record voice"]') || getMicButton();
  }

  window.addEventListener('keydown', (e) => {
    const isCtrl = e.ctrlKey || e.metaKey;
    if (isCtrl && (e.key.toLowerCase() === 'd' || e.code === 'KeyD')) {
      e.preventDefault();
      e.stopPropagation();
      e.stopImmediatePropagation();

      if (!window.__isPTTActive) {
        const mic = getMicButton();
        if (mic) {
          window.__isPTTActive = true;
          mic.click();
        }
      }
      return false;
    }
  }, true);

  window.addEventListener('keyup', (e) => {
    if (e.key.toLowerCase() === 'd' || e.code === 'KeyD' || e.key === 'Control' || e.key === 'Meta') {
      if (window.__isPTTActive) {
        window.__isPTTActive = false;
        setTimeout(() => {
          const stopBtn = getStopOrSendButton();
          if (stopBtn) stopBtn.click();
        }, 150);
      }
    }
  }, true);

  console.log('[PTT] Push-to-Talk (Ctrl+D) activated.');
})()
`;

async function tryInject() {
  if (!fs.existsSync(PORT_FILE)) return false;
  try {
    const lines = fs.readFileSync(PORT_FILE, 'utf8').split('\n');
    const port = lines[0].trim();
    if (!port) return false;

    const res = await fetch(`http://127.0.0.1:${port}/json`);
    const pages = await res.json();
    const page = pages.find(p => p.type === 'page');
    if (!page || !page.webSocketDebuggerUrl) return false;

    const ws = new WebSocket(page.webSocketDebuggerUrl);
    ws.onopen = () => {
      ws.send(JSON.stringify({
        id: 1,
        method: 'Runtime.evaluate',
        params: { expression: PTT_CODE, returnByValue: true }
      }));
      setTimeout(() => ws.close(), 1000);
    };
    return true;
  } catch {
    return false;
  }
}

// Check every 3 seconds in the background
console.log('Antigravity PTT Daemon running...');
setInterval(tryInject, 3000);
tryInject();

// # = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz
