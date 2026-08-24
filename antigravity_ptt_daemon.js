// ==========================================================================================
//  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  Antigravity Helper Daemon | [v2026-08-24]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
// ==========================================================================================
// Features:
// 1. Microphone Toggle (F4): 1st press = START RECORDING, 2nd press = STOP / SEND.
// 2. Custom Favorites Menu in Antigravity Sidebar (GitHub links & Server Info).
// 3. Persistent background loop: automatically reconnects whenever Antigravity is reopened.

const fs = require('fs');
const path = require('path');

// Ignore stdio write errors when running in background
if (process.stdout && process.stdout.on) process.stdout.on('error', () => {});
if (process.stderr && process.stderr.on) process.stderr.on('error', () => {});

const LOG_FILE = path.join(__dirname, 'antigravity_ptt_daemon.log');
const PORT_FILE = path.join(process.env.APPDATA, 'Antigravity', 'DevToolsActivePort');

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}\n`;
  try {
    fs.appendFileSync(LOG_FILE, line, 'utf8');
  } catch {}
}

process.on('uncaughtException', (err) => {
  log('Uncaught Exception: ' + (err?.stack || err));
});

process.on('unhandledRejection', (reason) => {
  log('Unhandled Rejection: ' + (reason?.stack || reason));
});

const INJECTION_CODE = `
(() => {
  // 1. Microphone Toggle Setup (F4)
  function setupMicToggle() {
    function getMicButton() {
      return document.querySelector('button[aria-label*="Record voice memo"], button[data-tooltip-id="input-send-button-record-tooltip"], button[aria-label*="Stop recording"], button[aria-label*="Record voice"], button[aria-label*="micro"], button[aria-label*="Micro"]');
    }

    function handleKey(e) {
      const isF4 = (e.key === 'F4' || e.code === 'F4' || e.keyCode === 115) && !e.ctrlKey && !e.altKey && !e.shiftKey && !e.metaKey;
      if (isF4) {
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();

        const btn = getMicButton();
        if (btn) {
          btn.click();
        }
        return false;
      }
    }

    if (!window.__antigravityF4Installed) {
      window.__antigravityF4Installed = true;
      window.addEventListener('keydown', handleKey, true);
      document.addEventListener('keydown', handleKey, true);
    }
  }

  // 2. Favorites Sidebar Menu setup
  function setupFavorites() {
    if (document.getElementById('antigravity-custom-favorites')) return;

    const scheduledTasksBtn = Array.from(document.querySelectorAll('span')).find(s => s.innerText && s.innerText.includes('Scheduled Tasks'))?.closest('button') || Array.from(document.querySelectorAll('button')).find(b => b.innerText && b.innerText.includes('Scheduled Tasks'));
    if (scheduledTasksBtn && scheduledTasksBtn.parentElement) {
      const parentContainer = scheduledTasksBtn.parentElement;

      const favContainer = document.createElement('div');
      favContainer.id = 'antigravity-custom-favorites';
      favContainer.className = 'flex flex-col gap-1 mt-2 pt-2 border-t border-border/30 select-none';

      const titleHeader = document.createElement('div');
      titleHeader.className = 'flex items-center justify-between px-2 py-1 text-xs font-semibold text-muted-foreground uppercase tracking-wider opacity-70';
      titleHeader.innerHTML = '<span>⭐ Favorites</span><span class="text-[10px] lowercase opacity-60">github</span>';
      favContainer.appendChild(titleHeader);

      const links = [
        {
          iconHtml: '<span class="text-base leading-none group-hover:scale-110 transition-transform">🖥️</span>',
          label: 'New Server Info',
          desc: 'Secret_Privat/README.md',
          url: 'https://github.com/GinCz/Secret_Privat/blob/main/README.md'
        },
        {
          iconHtml: '<span class="text-base leading-none group-hover:scale-110 transition-transform">🐧</span>',
          label: 'Linux Servers',
          desc: 'Linux_Server_Public',
          url: 'https://github.com/GinCz/Linux_Server_Public'
        },
        {
          iconHtml: '<svg class="w-4 h-4 text-[#0078D4] shrink-0 group-hover:scale-110 transition-transform" viewBox="0 0 88 88" fill="currentColor"><path d="M0 12.402l35.687-4.86.016 34.423-35.67.203zm35.67 33.529l.028 34.453L.028 75.48.016 45.728zm4.326-39.027L87.914 0v41.527l-47.918.376zm47.918 43.934v41.527l-47.918-6.736V46.607z"/></svg>',
          label: 'Windows Scripts',
          desc: 'Windows_scripts',
          url: 'https://github.com/GinCz/Windows_scripts'
        },
        {
          iconHtml: '<span class="text-base leading-none group-hover:scale-110 transition-transform">🐙</span>',
          label: 'GitHub Profile',
          desc: 'github.com/GinCz',
          url: 'https://github.com/GinCz'
        }
      ];

      links.forEach(item => {
        const btn = document.createElement('a');
        btn.href = item.url;
        btn.target = '_blank';
        btn.rel = 'noreferrer noopener';
        btn.title = item.desc;
        btn.className = 'flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-secondary-foreground hover:bg-secondary/70 hover:text-foreground transition-all duration-150 cursor-pointer no-underline group';
        btn.innerHTML = item.iconHtml +
          '<span class="truncate font-medium flex-1 text-xs">' + item.label + '</span>' +
          '<svg class="w-3 h-3 opacity-0 group-hover:opacity-60 transition-opacity" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>';
        
        btn.addEventListener('click', (e) => {
          e.preventDefault();
          window.open(item.url, '_blank');
        });

        favContainer.appendChild(btn);
      });

      parentContainer.appendChild(favContainer);
    }
  }

  setupMicToggle();
  setupFavorites();
  if (!window.__antigravityInterval) {
    window.__antigravityInterval = setInterval(() => {
      setupMicToggle();
      setupFavorites();
    }, 2000);
  }
})()
`;

let activeSockets = new Map();
let isConnected = false;

async function checkAndInject() {
  if (!fs.existsSync(PORT_FILE)) {
    if (isConnected) {
      log('Antigravity closed. Waiting for next start...');
      isConnected = false;
      activeSockets.clear();
    }
    return;
  }

  try {
    const lines = fs.readFileSync(PORT_FILE, 'utf8').split('\n');
    const port = lines[0].trim();
    if (!port) return;

    const res = await fetch('http://127.0.0.1:' + port + '/json');
    const pages = await res.json();
    const pageTargets = pages.filter(p => p.type === 'page' && p.webSocketDebuggerUrl);

    if (pageTargets.length === 0) {
      if (isConnected) {
        log('No active Antigravity pages found. Waiting...');
        isConnected = false;
        activeSockets.clear();
      }
      return;
    }

    if (!isConnected) {
      log('Antigravity detected (port ' + port + '). Injecting handlers...');
      isConnected = true;
    }

    for (const page of pageTargets) {
      const url = page.webSocketDebuggerUrl;
      let ws = activeSockets.get(url);

      if (!ws || ws.readyState === WebSocket.CLOSED || ws.readyState === WebSocket.CLOSING) {
        try {
          ws = new WebSocket(url);
          activeSockets.set(url, ws);

          ws.addEventListener('error', () => {
            activeSockets.delete(url);
          });

          ws.addEventListener('close', () => {
            activeSockets.delete(url);
          });

          ws.addEventListener('open', () => {
            try {
              ws.send(JSON.stringify({ id: 1, method: 'Page.enable' }));
              ws.send(JSON.stringify({ id: 2, method: 'Runtime.enable' }));
              ws.send(JSON.stringify({
                id: 3,
                method: 'Page.addScriptToEvaluateOnNewDocument',
                params: { source: INJECTION_CODE }
              }));
              ws.send(JSON.stringify({
                id: 4,
                method: 'Runtime.evaluate',
                params: { expression: INJECTION_CODE, returnByValue: true }
              }));
              log('Injected hotkey & favorites into page: ' + (page.title || page.url));
            } catch {}
          });
        } catch {}
      } else if (ws.readyState === WebSocket.OPEN) {
        try {
          ws.send(JSON.stringify({
            id: Date.now(),
            method: 'Runtime.evaluate',
            params: { expression: INJECTION_CODE, returnByValue: true }
          }));
        } catch {}
      }
    }
  } catch (err) {
    if (isConnected) {
      log('Connection lost to Antigravity. Waiting for restart...');
      isConnected = false;
      activeSockets.clear();
    }
  }
}

log('Antigravity Persistent Helper Daemon started...');
checkAndInject();
setInterval(checkAndInject, 2500);

// # = Rooted by VladiMIR | AI = v2026-08-24 = github.com/GinCz
