let currentUser = null;
let token = localStorage.getItem('gin_chat_token') || null;
let socket = null;
let activeChat = null;
let allChats = [];
let currentFilter = 'all';
let replyMessage = null;
let editingMessage = null;
let currentUploadXhr = null;

// Multi-message selection state
let isSelectionMode = false;
let selectedMessageIds = new Set();

// Voice recording state
let mediaRecorder = null;
let audioChunks = [];
let voiceTimerInterval = null;
let voiceStartTime = null;

// Emoji sets (Curated 25 standard emojis per category, 5x5 grid)
const emojis = {
  smileys: ['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','😉','😌','😍','🥰','😘','😋','😛','😜','🤪','😎','🥳','😏','🥺','😭'],
  gestures: ['👍','👎','👌','✌️','🤞','🤟','🤘','🤙','👈','👉','👆','👇','✋','🤚','🖐️','👋','🤝','👏','🙌','👐','🤲','🙏','💪','✍️','💅'],
  hearts: ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝','💟','💋','💌','💐','🌹','✨','⭐'],
  animals: ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🐔','🐧','🐦','🦆','🦅','🦉','🐺','🦄','🐝','🦋'],
  objects: ['🔥','🎉','🎊','💡','⚡','💥','🚀','🛡️','🎯','👑','🏆','🎁','🎈','🔔','📱','💻','⌨️','📷','🎥','🎧','🎵','🔑','🔒','⚙️','💎']
};

// Initialize Theme immediately
try {
  const savedTheme = localStorage.getItem('gin_chat_theme') || 'dark';
  if (savedTheme === 'light') {
    document.body.classList.add('light-theme');
    document.body.classList.remove('dark-theme');
  }
} catch(e) {}

// View Mode Handler (Mobile / Desktop View)
function setViewMode(mode, save = true) {
  const metaViewport = document.querySelector('meta[name="viewport"]');
  const btnMobile = document.getElementById('btnModeMobile');
  const btnDesktop = document.getElementById('btnModeDesktop');
  const menuModeText = document.getElementById('menuModeText');

  if (mode === 'desktop') {
    document.documentElement.classList.add('desktop-mode-forced');
    document.documentElement.classList.remove('mobile-mode');
    document.body.classList.add('desktop-mode-forced');
    document.body.classList.remove('mobile-mode');
    if (metaViewport) {
      metaViewport.setAttribute('content', 'width=1100, initial-scale=0.35, user-scalable=yes');
    }
    if (btnMobile) btnMobile.classList.remove('active');
    if (btnDesktop) btnDesktop.classList.add('active');
    if (menuModeText) menuModeText.textContent = 'Режим: ПК версия (Активен)';
    if (save) localStorage.setItem('gin_view_mode', 'desktop');
  } else {
    document.documentElement.classList.add('mobile-mode');
    document.documentElement.classList.remove('desktop-mode-forced');
    document.body.classList.add('mobile-mode');
    document.body.classList.remove('desktop-mode-forced');
    if (metaViewport) {
      metaViewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=5.0, viewport-fit=cover');
    }
    if (btnMobile) btnMobile.classList.add('active');
    if (btnDesktop) btnDesktop.classList.remove('active');
    if (menuModeText) menuModeText.textContent = 'Режим: Мобильный (Активен)';
    if (save) localStorage.setItem('gin_view_mode', 'mobile');
  }
}

function toggleDisplayMode() {
  const isCurrentlyMobile = document.body.classList.contains('mobile-mode') || !document.body.classList.contains('desktop-mode-forced');
  setViewMode(isCurrentlyMobile ? 'desktop' : 'mobile', true);
}

function initViewMode() {
  const isMobileDevice = window.innerWidth <= 840 || /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  const saved = localStorage.getItem('gin_view_mode');
  if (saved === 'desktop' && !isMobileDevice) {
    setViewMode('desktop', false);
  } else {
    setViewMode('mobile', false);
  }
}

try {
  initViewMode();
} catch(e) {}

document.addEventListener('DOMContentLoaded', () => {
  initTheme();
  initViewMode();
  if (token) {
    fetchMe();
  } else {
    showAuthScreen();
  }
  loadEmojiCategory('smileys');

  const msgInput = document.getElementById('messageInput');
  msgInput?.addEventListener('input', () => {
    msgInput.style.height = 'auto';
    msgInput.style.height = Math.min(msgInput.scrollHeight, 150) + 'px';
    const hasText = msgInput.value.trim().length > 0;
    document.getElementById('sendBtn').classList.toggle('hidden', !hasText);
    document.getElementById('voiceBtn').classList.toggle('hidden', hasText);
    if (activeChat) scrollToBottom();
  });
});

// ----------------------------------------------------
// PASSWORD VISIBILITY TOGGLE
// ----------------------------------------------------

function togglePasswordVisibility(inputId, btn) {
  const input = document.getElementById(inputId);
  if (!input) return;
  const isPass = input.type === 'password';
  input.type = isPass ? 'text' : 'password';
  const icon = btn.querySelector('i');
  if (icon) {
    icon.className = isPass ? 'fa-solid fa-eye-slash' : 'fa-solid fa-eye';
  }
}

// ----------------------------------------------------
// AUTHENTICATION
// ----------------------------------------------------

function switchAuthTab(tab) {
  document.getElementById('tabLoginBtn').classList.toggle('active', tab === 'login');
  document.getElementById('tabRegisterBtn').classList.toggle('active', tab === 'register');
  document.getElementById('loginForm').classList.toggle('hidden', tab !== 'login');
  document.getElementById('registerForm').classList.toggle('hidden', tab !== 'register');
}

function autoSuggestUsername(email) {
  const userField = document.getElementById('regUsername');
  if (email && email.includes('@') && !userField.dataset.customEdited) {
    const suggested = email.split('@')[0].toLowerCase().replace(/[^a-z0-9_]/g, '');
    userField.value = suggested;
  }
}

document.getElementById('regUsername')?.addEventListener('input', () => {
  document.getElementById('regUsername').dataset.customEdited = 'true';
});

async function handleLogin(e) {
  e.preventDefault();
  const alertBox = document.getElementById('loginAlert');
  alertBox.className = 'alert-box';

  const login = document.getElementById('loginInput').value.trim();
  const password = document.getElementById('loginPassword').value;

  try {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login, password })
    });
    const data = await res.json();

    if (!res.ok) {
      alertBox.className = 'alert-box error show';
      alertBox.innerText = data.error || 'Ошибка входа';
      return;
    }

    token = data.token;
    currentUser = data.user;
    localStorage.setItem('gin_chat_token', token);
    initApp();
  } catch (err) {
    alertBox.className = 'alert-box error show';
    alertBox.innerText = 'Сетевая ошибка при подключении к серверу';
  }
}

async function handleRegister(e) {
  e.preventDefault();
  const alertBox = document.getElementById('regAlert');
  alertBox.className = 'alert-box';

  const name = document.getElementById('regName').value.trim();
  const email = document.getElementById('regEmail').value.trim();
  const phone = document.getElementById('regPhone').value.trim();
  const username = document.getElementById('regUsername').value.trim();
  const password = document.getElementById('regPassword').value;

  try {
    const res = await fetch('/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, phone, username, password })
    });
    const data = await res.json();

    if (!res.ok) {
      alertBox.className = 'alert-box error show';
      alertBox.innerText = data.error || 'Ошибка регистрации';
      return;
    }

    alertBox.className = 'alert-box success show';
    alertBox.innerHTML = `<strong>Заявка успешно отправлена!</strong><br>${data.message}<br>Логин для входа после одобрения: <b>@${data.username}</b>`;
    document.getElementById('registerForm').reset();
  } catch (err) {
    alertBox.className = 'alert-box error show';
    alertBox.innerText = 'Сетевая ошибка при отправке заявки';
  }
}

async function fetchMe() {
  try {
    const res = await fetch('/api/auth/me', {
      headers: { Authorization: `Bearer ${token}` }
    });
    if (!res.ok) {
      logout();
      return;
    }
    const data = await res.json();
    currentUser = data.user;
    initApp();
  } catch (err) {
    logout();
  }
}

function showAuthScreen() {
  document.getElementById('authScreen').classList.remove('hidden');
  document.getElementById('mainScreen').classList.add('hidden');
}

function logout() {
  localStorage.removeItem('gin_chat_token');
  token = null;
  currentUser = null;
  if (socket) socket.disconnect();
  showAuthScreen();
}

// ----------------------------------------------------
// AVATAR & INITIALS HELPERS (Pure Black Background)
// ----------------------------------------------------

function getInitials(name) {
  if (!name || name === '??') return 'ВБ';
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

function renderAvatar(avatarUrl, name, sizeClass = 'avatar-md') {
  const initials = getInitials(name);
  if (avatarUrl) {
    return `<div class="avatar ${sizeClass}"><img src="${escapeHtml(avatarUrl)}" alt="${escapeHtml(name)}" class="avatar-img" onerror="this.onerror=null;this.parentElement.innerText='${escapeHtml(initials)}'"></div>`;
  }
  return `<div class="avatar ${sizeClass}">${escapeHtml(initials)}</div>`;
}

function updateAvatarElement(elementId, avatarUrl, name, sizeClass = 'avatar-md') {
  const el = document.getElementById(elementId);
  if (!el) return;
  const initials = getInitials(name);
  if (avatarUrl) {
    el.innerHTML = `<img src="${escapeHtml(avatarUrl)}" alt="${escapeHtml(name)}" class="avatar-img" onerror="this.onerror=null;this.parentElement.innerText='${escapeHtml(initials)}'">`;
  } else {
    el.innerHTML = escapeHtml(initials);
  }
}

// ----------------------------------------------------
// INITIALIZE MAIN APP
// ----------------------------------------------------

function initApp() {
  document.getElementById('authScreen').classList.add('hidden');
  document.getElementById('mainScreen').classList.remove('hidden');

  document.getElementById('menuUserName').innerText = currentUser.name;
  document.getElementById('menuUserHandle').innerText = '@' + currentUser.username;
  updateAvatarElement('menuUserAvatar', currentUser.avatar, currentUser.name, 'avatar-md');

  if (currentUser.role === 'superadmin' || currentUser.role === 'admin') {
    document.getElementById('adminPanelMenuBtn').classList.remove('hidden');
    checkPendingUsersCount();
  } else {
    document.getElementById('adminPanelMenuBtn').classList.add('hidden');
  }

  connectSocket();
  loadChats().then(() => {
    handleUrlRouting();
  });
  checkPushStatus();
  autoSyncPushSubscription();
}

// ----------------------------------------------------
// REAL-TIME SOCKET.IO
// ----------------------------------------------------

function connectSocket() {
  if (socket) socket.disconnect();
  socket = io({
    auth: { token }
  });

  socket.on('connect', () => {
    console.log('⚡ Connected to GIN-Chat socket server');
  });

  socket.on('new_message', (msg) => {
    const isCurrentActiveChat = activeChat && Number(activeChat.id) === Number(msg.chat_id);
    if (isCurrentActiveChat) {
      if (!document.getElementById(`msg-${msg.id}`)) {
        appendMessageToView(msg);
        scrollToBottom();
      }
      socket.emit('mark_read', { chatId: msg.chat_id, messageIds: [msg.id] });
    }
    playMessageSound();
    loadChats();

    // Show system notification if window/tab is not active or chat is not active
    if (document.hidden || !document.hasFocus() || !isCurrentActiveChat) {
      showLocalSystemNotification(msg);
    }
  });

  socket.on('message_edited', ({ chatId, messageId, text }) => {
    if (activeChat && activeChat.id === chatId) {
      const msgRow = document.getElementById(`msg-${messageId}`);
      if (msgRow) {
        const textEl = msgRow.querySelector('.msg-text-content');
        if (textEl) {
          textEl.innerHTML = formatMessageText(text);
        }
        let editedBadge = msgRow.querySelector('.msg-edited-badge');
        if (!editedBadge) {
          const meta = msgRow.querySelector('.msg-meta');
          if (meta) {
            editedBadge = document.createElement('span');
            editedBadge.className = 'msg-edited-badge';
            editedBadge.innerText = 'изм.';
            meta.insertBefore(editedBadge, meta.firstChild);
          }
        }
      }
    }
    loadChats();
  });

  socket.on('message_deleted', ({ chatId, messageId }) => {
    if (activeChat && activeChat.id === chatId) {
      const msgRow = document.getElementById(`msg-${messageId}`);
      if (msgRow) {
        msgRow.style.opacity = '0';
        msgRow.style.transform = 'scale(0.8)';
        setTimeout(() => msgRow.remove(), 250);
      }
      if (selectedMessageIds.has(messageId)) {
        selectedMessageIds.delete(messageId);
        updateSelectionUI();
      }
    }
    loadChats();
  });

  socket.on('messages_deleted', ({ chatId, messageIds }) => {
    if (activeChat && activeChat.id === chatId && Array.isArray(messageIds)) {
      messageIds.forEach(id => {
        const msgRow = document.getElementById(`msg-${id}`);
        if (msgRow) {
          msgRow.style.opacity = '0';
          msgRow.style.transform = 'scale(0.8)';
          setTimeout(() => msgRow.remove(), 250);
        }
        selectedMessageIds.delete(id);
      });
      updateSelectionUI();
    }
    loadChats();
  });

  socket.on('chat_info_updated', ({ chatId, name, description, avatar }) => {
    if (activeChat && activeChat.id === chatId) {
      if (name) activeChat.name = name;
      if (description !== undefined) activeChat.description = description;
      if (avatar !== undefined) activeChat.avatar = avatar;
      document.getElementById('chatHeaderTitle').innerText = activeChat.name;
      updateAvatarElement('chatHeaderAvatar', activeChat.avatar, activeChat.name, 'avatar-md');
      updateChatHeaderSubtitle();
    }
    loadChats();
  });

  socket.on('new_chat_created', ({ chatId }) => {
    if (socket && chatId) socket.emit('join_chat', { chatId });
    loadChats();
  });

  socket.on('members_added', ({ chatId }) => {
    if (activeChat && activeChat.id === chatId) {
      selectChat(chatId);
    }
    loadChats();
  });

  socket.on('group_join_notification', ({ chatId, chatName, joinedUser }) => {
    showToast(`🔔 ${joinedUser.name} (@${joinedUser.username}) вступил в группу «${chatName}»`);
    loadChats();
    if (activeChat && activeChat.id === chatId) {
      selectChat(chatId);
    }
  });

  socket.on('new_report_alert', (report) => {
    showToast(`🚨 Поступила жалоба на @${report.reported_user.username} (${report.reasons[0] || 'нарушение'})`);
    if (currentUser && (currentUser.role === 'superadmin' || currentUser.role === 'admin')) {
      loadAdminData();
    }
  });

  socket.on('user_banned', () => {
    alert('Ваш аккаунт был заблокирован администратором.');
    logout();
  });

  socket.on('member_removed', ({ chatId, userId }) => {
    if (activeChat && activeChat.id === chatId) {
      if (userId === currentUser.id) {
        document.getElementById('activeChatContainer').classList.add('hidden');
        document.getElementById('emptyChatState').classList.remove('hidden');
        activeChat = null;
      } else {
        selectChat(chatId);
      }
    }
    loadChats();
  });

  socket.on('user_typing', ({ chatId, name, isTyping }) => {
    if (activeChat && activeChat.id === chatId) {
      const subtitle = document.getElementById('chatHeaderSubtitle');
      if (isTyping) {
        subtitle.innerHTML = `<span class="text-primary"><i class="fa-solid fa-pen-nib"></i> ${escapeHtml(name)} печатает...</span>`;
      } else {
        updateChatHeaderSubtitle();
      }
    }
  });

  socket.on('reaction_updated', ({ messageId, reactions }) => {
    renderReactions(messageId, reactions);
  });

  socket.on('new_pending_user', () => {
    if (currentUser && (currentUser.role === 'superadmin' || currentUser.role === 'admin')) {
      checkPendingUsersCount();
      playMessageSound();
    }
  });

  socket.on('user_approved', () => {
    loadChats();
    if (currentUser && (currentUser.role === 'superadmin' || currentUser.role === 'admin')) {
      checkPendingUsersCount();
      loadAdminData();
    }
  });

  socket.on('user_status', ({ userId, status, last_seen }) => {
    const isOnline = status === 'online';

    // Update activeChat partner
    if (activeChat && activeChat.partner && activeChat.partner.id === Number(userId)) {
      activeChat.partner.is_online = isOnline;
      if (last_seen) activeChat.partner.last_seen = last_seen;
      updateChatHeaderSubtitle();

      // If contact profile modal is currently open, live update its status
      const detailsModal = document.getElementById('chatDetailsModal');
      if (detailsModal && !detailsModal.classList.contains('hidden')) {
        const statusEl = document.getElementById('directDetailsStatus');
        if (statusEl) {
          statusEl.innerHTML = formatUserStatus(isOnline, activeChat.partner.last_seen);
        }
      }
    }

    // Update allChats partner state
    let chatUpdated = false;
    allChats.forEach(c => {
      if (c.type === 'direct' && c.partner && c.partner.id === Number(userId)) {
        c.partner.is_online = isOnline;
        if (last_seen) c.partner.last_seen = last_seen;
        chatUpdated = true;
      }
    });
    if (chatUpdated) {
      renderChatsList();
    }
  });

  // WebRTC P2P Call Listeners
  socket.on('incoming_call', handleIncomingCall);
  socket.on('call_accepted', handleCallAccepted);
  socket.on('call_rejected', handleCallRejected);
  socket.on('call_ended', handleCallEnded);
  socket.on('call_failed', handleCallFailed);
  socket.on('call_ice_candidate', handleCallIceCandidate);
}

let globalAudioCtx = null;
function getSharedAudioContext() {
  if (!globalAudioCtx) {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (AudioCtx) globalAudioCtx = new AudioCtx();
  }
  if (globalAudioCtx && globalAudioCtx.state === 'suspended') {
    globalAudioCtx.resume().catch(() => {});
  }
  return globalAudioCtx;
}

if (typeof window !== 'undefined') {
  ['click', 'touchstart', 'touchend', 'keydown'].forEach((eventName) => {
    window.addEventListener(eventName, () => {
      getSharedAudioContext();
    }, { passive: true });
  });
}

function playMessageSound() {
  try {
    // 1. Mobile Vibration (Android / Chrome PWA)
    if ('vibrate' in navigator) {
      try {
        navigator.vibrate([200, 100, 200]);
      } catch (ve) {}
    }

    // 2. Audible tone via HTML5 Audio file
    try {
      const msgAudio = new Audio('/sounds/message.wav');
      msgAudio.volume = 0.85;
      msgAudio.play().catch(() => {});
    } catch (ae) {}

    // 3. Web Audio API synthesized backup
    const ctx = getSharedAudioContext();
    if (ctx) {
      if (ctx.state === 'suspended') {
        ctx.resume().catch(() => {});
      }
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(659.25, ctx.currentTime);
      osc.frequency.setValueAtTime(880.00, ctx.currentTime + 0.08);
      gain.gain.setValueAtTime(0.35, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.25);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.25);
    }
  } catch (e) {
    console.warn('playMessageSound error:', e);
  }
}

function showLocalSystemNotification(msg) {
  if (typeof Notification === 'undefined' || Notification.permission !== 'granted') return;
  try {
    const senderName = msg.sender_name || (msg.user ? msg.user.name : 'GIN-Chat');
    let body = msg.text || '';
    if (msg.type === 'voice') body = '🎤 Голосовое сообщение';
    else if (msg.type === 'image') body = '📷 Фотография';
    else if (msg.type === 'file') body = `📎 Файл: ${msg.file_name || 'документ'}`;

    const options = {
      body: body || 'Новое входящее сообщение',
      icon: '/icons/icon-192-v30.png',
      badge: '/icons/badge-monochrome.png',
      tag: 'chat_' + (msg.chat_id || 'direct'),
      renotify: true,
      vibrate: [300, 100, 300],
      data: { url: '/?chat=' + (msg.chat_id || ''), chatId: msg.chat_id }
    };

    getSwRegistration().then((reg) => {
      if (reg && reg.showNotification) {
        reg.showNotification(senderName, options);
      } else {
        new Notification(senderName, options);
      }
    }).catch(() => {
      try { new Notification(senderName, options); } catch (e) {}
    });
  } catch (err) {
    console.warn('showLocalSystemNotification non-fatal:', err);
  }
}

// ----------------------------------------------------
// CHATS LIST & ACTIVE CHAT SELECTION
// ----------------------------------------------------

async function loadChats() {
  try {
    const res = await fetch('/api/chats', {
      headers: { Authorization: `Bearer ${token}` }
    });
    if (!res.ok) {
      if (res.status === 401) logout();
      return;
    }
    const data = await res.json();
    allChats = data.chats || [];
    renderChatsList();
  } catch (err) {
    console.error('Error loading chats:', err);
  }
}

function filterChats(filter) {
  currentFilter = filter;
  document.querySelectorAll('.chat-tab').forEach(t => {
    t.classList.toggle('active', t.dataset.filter === filter);
  });
  renderChatsList();
}

function renderChatsList() {
  const container = document.getElementById('chatsList');
  let filtered = allChats;
  if (currentFilter === 'direct') filtered = allChats.filter(c => c.type === 'direct');
  if (currentFilter === 'group') filtered = allChats.filter(c => c.type === 'group');

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="empty-chat-state" style="padding: 40px 20px;">
        <i class="fa-regular fa-comment-dots text-muted" style="font-size: 36px; margin-bottom: 10px;"></i>
        <p class="text-muted" style="font-size: 13px; margin-bottom: 14px;">Диалогов пока нет.</p>
        <button class="btn btn-sm btn-primary" onclick="openNewDirectModal()"><i class="fa-solid fa-address-book"></i> Написать пользователю</button>
      </div>`;
    return;
  }

  container.innerHTML = filtered.map(chat => {
    const isActive = activeChat && activeChat.id === chat.id;
    const timeStr = chat.lastMessage ? formatTime(chat.lastMessage.created_at) : '';
    const isDirect = chat.type === 'direct';
    let preview = 'Нет сообщений';
    if (chat.lastMessage) {
      preview = escapeHtml(chat.lastMessage.text);
    } else if (isDirect && chat.partner && chat.partner.username) {
      preview = `@${escapeHtml(chat.partner.username)}`;
    }
    const unreadBadge = chat.unreadCount > 0 ? `<div class="unread-badge">${chat.unreadCount}</div>` : '';
    const displayName = chat.name || (chat.partner ? chat.partner.name : 'Личный диалог');

    return `
      <div class="chat-item ${isActive ? 'active' : ''}" onclick="selectChat(${chat.id})">
        ${renderAvatar(chat.avatar, displayName, 'avatar-md')}
        <div class="chat-item-info">
          <div class="chat-item-top">
            <div class="chat-item-name">${escapeHtml(displayName)}</div>
            <div class="chat-item-time">${timeStr}</div>
          </div>
          <div class="chat-item-bottom">
            <div class="chat-item-preview">${preview}</div>
            ${unreadBadge}
          </div>
        </div>
      </div>
    `;
  }).join('');
}

async function selectChat(chatId) {
  try {
    exitSelectionMode();
    const res = await fetch(`/api/chats/${chatId}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (!res.ok) return;

    activeChat = { 
      ...data.chat, 
      members: data.members, 
      myRole: data.myRole, 
      pinnedMessage: data.pinnedMessage,
      commonGroups: data.commonGroups || []
    };

    if (socket) {
      socket.emit('join_chat', { chatId });
    }

    document.getElementById('emptyChatState').classList.add('hidden');
    const activeChatEl = document.getElementById('activeChatContainer');
    activeChatEl.classList.remove('hidden');
    activeChatEl.className = activeChatEl.className.replace(/chat-theme-\d/g, '').trim();
    const themeIdx = Math.abs(Number(chatId) || 0) % 8;
    activeChatEl.classList.add(`chat-theme-${themeIdx}`);
    applyWallpaper();

    document.body.classList.add('mobile-chat-open');

    const displayName = activeChat.name || (activeChat.partner ? activeChat.partner.name : 'Личный диалог');
    document.getElementById('chatHeaderTitle').innerText = displayName;
    updateAvatarElement('chatHeaderAvatar', activeChat.avatar, displayName, 'avatar-md');
    updateChatHeaderSubtitle();

    // Toggle Call Buttons (Only in Direct 1-on-1 chats)
    const audioCallBtn = document.getElementById('headerAudioCallBtn');
    const videoCallBtn = document.getElementById('headerVideoCallBtn');
    if (audioCallBtn) audioCallBtn.classList.toggle('hidden', activeChat.type === 'group');
    if (videoCallBtn) videoCallBtn.classList.toggle('hidden', activeChat.type === 'group');

    // Toggle Group Bronze Invite Button
    const groupInviteBtn = document.getElementById('chatHeaderGroupInviteBtn');
    if (groupInviteBtn) {
      if (activeChat.type === 'group') {
        groupInviteBtn.classList.remove('hidden');
      } else {
        groupInviteBtn.classList.add('hidden');
      }
    }

    if (activeChat.pinnedMessage) {
      document.getElementById('pinnedBar').classList.remove('hidden');
      document.getElementById('pinnedText').innerText = activeChat.pinnedMessage.text;
    } else {
      document.getElementById('pinnedBar').classList.add('hidden');
    }

    const targetHash = activeChat.type === 'group'
      ? `#/group/${activeChat.invite_code || activeChat.id}/${encodeURIComponent((activeChat.name || 'group').trim().replace(/[\s\/]+/g, '_'))}`
      : `#/c/${chatId}`;

    if (window.location.hash !== targetHash) {
      history.pushState({ view: 'chat', chatId }, '', targetHash);
    }

    renderChatsList();
    loadMessages(chatId);
  } catch (err) {
    console.error('Error opening chat:', err);
  }
}

function updateChatHeaderSubtitle() {
  const sub = document.getElementById('chatHeaderSubtitle');
  if (!sub || !activeChat) return;
  if (activeChat.type === 'group') {
    sub.innerText = `${activeChat.members ? activeChat.members.length : 0} участников`;
  } else {
    const partner = activeChat.partner || {};
    const isOnline = partner.is_online === true;
    const lastSeen = partner.last_seen;
    const handle = partner.username ? `@${partner.username} • ` : '';

    if (isOnline) {
      sub.innerHTML = `${handle}<span class="status-dot online"></span> <span class="text-success" style="font-weight:600;">в сети</span>`;
    } else {
      sub.innerHTML = `${handle}${formatUserStatus(false, lastSeen)}`;
    }
  }
}

async function loadMessages(chatId) {
  const container = document.getElementById('messagesScroll');
  container.innerHTML = '<div class="text-center text-muted" style="padding: 20px;"><i class="fa-solid fa-spinner fa-spin"></i> Загрузка сообщений...</div>';

  try {
    const res = await fetch(`/api/chats/${chatId}/messages`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (!res.ok) {
      container.innerHTML = `<div class="text-center text-danger" style="padding: 20px;">${escapeHtml(data.error || 'Ошибка загрузки сообщений')}</div>`;
      return;
    }
    container.innerHTML = '';
    (data.messages || []).forEach(msg => appendMessageToView(msg));
    scrollToBottom();
  } catch (err) {
    container.innerHTML = '<div class="text-center text-danger" style="padding: 20px;">Ошибка загрузки сообщений</div>';
  }
}

function appendMessageToView(msg) {
  const container = document.getElementById('messagesScroll');
  const isOut = msg.sender_id === currentUser.id;
  const isAdmin = currentUser && (currentUser.role === 'superadmin' || currentUser.role === 'admin');
  const canModify = isOut || isAdmin;

  const row = document.createElement('div');
  row.className = `msg-row ${isOut ? 'out' : 'in'}`;
  row.id = `msg-${msg.id}`;

  let contentHtml = '';

  // Message Action Bar (Hover on bubble with 2x bigger reaction emojis)
  contentHtml += `
    <div class="msg-action-bar">
      <button class="msg-act-btn msg-act-emoji" onclick="toggleReaction(${msg.id}, '👍')" title="Нравится 👍">👍</button>
      <button class="msg-act-btn msg-act-emoji" onclick="toggleReaction(${msg.id}, '❤️')" title="Любовь ❤️">❤️</button>
      <button class="msg-act-btn msg-act-emoji" onclick="toggleReaction(${msg.id}, '🔥')" title="Огонь 🔥">🔥</button>
      <button class="msg-act-btn msg-act-emoji" onclick="toggleReaction(${msg.id}, '😂')" title="Смех 😂">😂</button>
      <button class="msg-act-btn reaction-more" onclick="openReactionPicker(event, ${msg.id})" title="Все 25 реакций"><i class="fa-regular fa-face-smile"></i></button>
      <button class="msg-act-btn" onclick="toggleSelectMessage(${msg.id}, event)" title="Выбрать"><i class="fa-regular fa-square-check"></i></button>
      <button class="msg-act-btn forward" onclick="openForwardModal(${msg.id})" title="Переслать"><i class="fa-solid fa-share"></i></button>
      <button class="msg-act-btn" onclick="setReplyMessageById(${msg.id})" title="Ответить"><i class="fa-solid fa-reply"></i></button>
      ${(canModify && msg.type === 'text') ? `<button class="msg-act-btn" onclick="startEditMessage(${msg.id}, '${escapeForJs(msg.text)}')" title="Редактировать"><i class="fa-solid fa-pencil"></i></button>` : ''}
      ${canModify ? `<button class="msg-act-btn delete" onclick="deleteMessageById(${msg.id})" title="Удалить"><i class="fa-solid fa-trash"></i></button>` : ''}
    </div>
  `;

  if (msg.reply_to) {
    contentHtml += `
      <div class="msg-reply-box" onclick="scrollToMessage(${msg.reply_to.id})">
        <div class="msg-reply-sender">${escapeHtml(msg.reply_to.sender_name)}</div>
        <div class="msg-reply-snippet">${escapeHtml(msg.reply_to.text)}</div>
      </div>
    `;
  }

  if (!isOut && activeChat && activeChat.type === 'group') {
    contentHtml += `
      <div class="msg-sender-name" style="display: flex; align-items: center; gap: 6px; margin-bottom: 4px;">
        ${renderAvatar(msg.sender.avatar, msg.sender.name, 'avatar-xs')}
        <span>@${escapeHtml(msg.sender.username)} (${escapeHtml(msg.sender.name)})</span>
      </div>
    `;
  }

  if (msg.type === 'text') {
    contentHtml += `<div class="msg-text-content">${formatMessageText(msg.text)}</div>`;
  } else if (msg.type === 'image') {
    contentHtml += `<img src="${msg.file_url}" class="msg-media-img" onclick="openLightbox('${msg.file_url}')" alt="Photo">`;
  } else if (msg.type === 'gif') {
    contentHtml += `
      <div class="msg-gif-wrapper">
        <img src="${escapeHtml(msg.file_url)}" class="msg-media-gif" onclick="openLightbox('${escapeHtml(msg.file_url)}')" alt="GIF" loading="lazy">
        <span class="gif-badge">GIF</span>
      </div>
    `;
  } else if (msg.type === 'voice' || (msg.type === 'file' && ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac', 'opus', 'webm'].includes(((msg.file_name || '').split('.').pop() || '').toLowerCase()))) {
    const isVoice = msg.type === 'voice';
    const title = isVoice ? 'Голосовое сообщение' : escapeHtml(msg.file_name || 'Аудиозапись');
    const audioUrl = escapeHtml(msg.file_url || '');
    const audioIcon = isVoice ? 'fa-solid fa-microphone' : 'fa-solid fa-music';

    contentHtml += `
      <div class="msg-audio-card ${isVoice ? 'is-voice' : 'is-music'}" data-audio-url="${audioUrl}">
        <div class="audio-main-row">
          <button type="button" class="audio-play-btn" onclick="togglePlayAudio(this, '${audioUrl}')" title="Воспроизвести / Пауза">
            <i class="fa-solid fa-play"></i>
          </button>
          <div class="audio-info-col">
            <div class="audio-header-row">
              <span class="audio-title"><i class="${audioIcon}" style="opacity: 0.7; margin-right: 4px; font-size: 11px;"></i>${title}</span>
              <button type="button" class="audio-speed-btn" onclick="cycleAudioSpeed(this)" title="Скорость воспроизведения">1x</button>
            </div>
            <div class="audio-seek-track" onclick="handleAudioSeekClick(event, this, '${audioUrl}')" title="Нажмите для перемотки">
              <div class="audio-seek-fill"></div>
              <div class="audio-seek-thumb"></div>
            </div>
            <div class="audio-meta-row">
              <span class="audio-current-time">0:00</span>
              <div class="audio-rewind-controls">
                <button type="button" class="audio-seek-step-btn" onclick="seekAudioRelative(this, -5)" title="Назад на 5 секунд">
                  <i class="fa-solid fa-rotate-left"></i> 5с
                </button>
                <button type="button" class="audio-seek-step-btn" onclick="seekAudioRelative(this, 5)" title="Вперёд на 5 секунд">
                  5с <i class="fa-solid fa-rotate-right"></i>
                </button>
              </div>
              <span class="audio-total-time">${msg.file_size ? formatFileSize(msg.file_size) : '0:00'}</span>
            </div>
          </div>
        </div>
      </div>
    `;
  } else if (msg.type === 'file') {
    const fileMeta = getFileInfo(msg.file_name);
    const safeUrl = escapeHtml(msg.file_url || '');
    const safeName = escapeHtml(msg.file_name || 'Файл');
    contentHtml += `
      <div class="msg-file-card">
        <div class="msg-file-badge" style="background: ${fileMeta.bg}; color: ${fileMeta.color}; border: 1px solid ${fileMeta.color}50;">
          <i class="${fileMeta.icon}"></i>
          <span class="msg-file-ext-tag">${fileMeta.label}</span>
        </div>
        <div class="msg-file-details">
          <div class="msg-file-title" title="${safeName}">${safeName}</div>
          <div class="msg-file-meta-row">
            <span class="msg-file-size-badge">${formatFileSize(msg.file_size)}</span>
            <span class="msg-file-ext-pill" style="color: ${fileMeta.color};">${fileMeta.label}</span>
          </div>
        </div>
        <div class="msg-file-actions">
          <a href="${safeUrl}" target="_blank" download="${safeName}" class="btn-file-download" title="Скачать файл">
            <i class="fa-solid fa-download"></i> Скачать
          </a>
          <a href="${safeUrl}" target="_blank" rel="noopener noreferrer" class="btn-file-open" title="Открыть файл">
            <i class="fa-solid fa-arrow-up-right-from-square"></i> Открыть
          </a>
        </div>
      </div>
    `;
  }

  contentHtml += `
    <div class="msg-meta">
      ${msg.is_edited ? '<span class="msg-edited-badge">изм.</span>' : ''}
      <span class="msg-time">${formatTime(msg.created_at)}</span>
      ${isOut ? '<i class="fa-solid fa-check-double text-primary" style="font-size: 11px;"></i>' : ''}
    </div>
    <div class="msg-reactions" id="reactions-${msg.id}"></div>
  `;

  const bubble = document.createElement('div');
  bubble.className = 'msg-bubble';
  bubble.innerHTML = contentHtml;

  // Selection Checkmark Element
  const checkEl = document.createElement('div');
  checkEl.className = 'msg-select-check';
  checkEl.innerHTML = '<i class="fa-solid fa-check"></i>';
  checkEl.title = 'Выбрать';
  checkEl.addEventListener('click', (e) => {
    e.stopPropagation();
    toggleSelectMessage(msg.id, e);
  });

  bubble.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    setReplyMessage(msg);
  });
  bubble.addEventListener('dblclick', (e) => {
    if (isSelectionMode) return;
    toggleReaction(msg.id, '👍');
  });
  bubble.addEventListener('click', (e) => {
    if (isSelectionMode) {
      // If clicking interactive controls inside bubble, ignore
      if (e.target.closest('button, a, input, audio, video, .msg-action-bar, .audio-seek-track')) return;
      e.preventDefault();
      toggleSelectMessage(msg.id, e);
    }
  });

  row.appendChild(checkEl);
  row.appendChild(bubble);

  // Restore selection state if message was already selected
  if (selectedMessageIds.has(msg.id)) {
    row.classList.add('selected');
  }

  container.appendChild(row);

  renderReactions(msg.id, msg.reactions);
}

function getFileInfo(fileName) {
  const name = fileName || 'Файл';
  const parts = name.split('.');
  const ext = parts.length > 1 ? parts.pop().toLowerCase() : '';

  if (['exe', 'msi', 'bat', 'cmd'].includes(ext)) {
    return { icon: 'fa-brands fa-windows', color: '#00a4ef', label: ext ? ext.toUpperCase() : 'EXE', bg: 'linear-gradient(135deg, rgba(0, 164, 239, 0.25), rgba(0, 120, 215, 0.15))' };
  }
  if (['apk', 'xapk'].includes(ext)) {
    return { icon: 'fa-brands fa-android', color: '#10b981', label: 'APK', bg: 'linear-gradient(135deg, rgba(16, 185, 129, 0.25), rgba(5, 150, 105, 0.15))' };
  }
  if (['iso', 'img', 'dmg'].includes(ext)) {
    return { icon: 'fa-solid fa-compact-disc', color: '#8b5cf6', label: ext.toUpperCase(), bg: 'linear-gradient(135deg, rgba(139, 92, 246, 0.25), rgba(124, 58, 237, 0.15))' };
  }
  if (['pdf'].includes(ext)) {
    return { icon: 'fa-solid fa-file-pdf', color: '#ef4444', label: 'PDF', bg: 'linear-gradient(135deg, rgba(239, 68, 68, 0.25), rgba(185, 28, 28, 0.15))' };
  }
  if (['doc', 'docx', 'rtf', 'odt', 'txt'].includes(ext)) {
    return { icon: 'fa-solid fa-file-word', color: '#3b82f6', label: ext ? ext.toUpperCase() : 'DOC', bg: 'linear-gradient(135deg, rgba(59, 130, 246, 0.25), rgba(29, 78, 216, 0.15))' };
  }
  if (['xls', 'xlsx', 'csv'].includes(ext)) {
    return { icon: 'fa-solid fa-file-excel', color: '#10b981', label: ext.toUpperCase(), bg: 'linear-gradient(135deg, rgba(16, 185, 129, 0.25), rgba(4, 120, 87, 0.15))' };
  }
  if (['ppt', 'pptx'].includes(ext)) {
    return { icon: 'fa-solid fa-file-powerpoint', color: '#f97316', label: ext.toUpperCase(), bg: 'linear-gradient(135deg, rgba(249, 115, 22, 0.25), rgba(194, 65, 12, 0.15))' };
  }
  if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].includes(ext)) {
    return { icon: 'fa-solid fa-file-zipper', color: '#f59e0b', label: ext.toUpperCase(), bg: 'linear-gradient(135deg, rgba(245, 158, 11, 0.25), rgba(180, 83, 9, 0.15))' };
  }
  if (['js', 'ts', 'py', 'json', 'html', 'css', 'php', 'sh', 'sql', 'cpp', 'c', 'yml', 'yaml'].includes(ext)) {
    return { icon: 'fa-solid fa-file-code', color: '#a855f7', label: ext.toUpperCase(), bg: 'linear-gradient(135deg, rgba(168, 85, 247, 0.25), rgba(126, 34, 206, 0.15))' };
  }
  if (['mp4', 'mkv', 'avi', 'mov', 'webm'].includes(ext)) {
    return { icon: 'fa-solid fa-file-video', color: '#ec4899', label: ext.toUpperCase(), bg: 'linear-gradient(135deg, rgba(236, 72, 153, 0.25), rgba(190, 24, 93, 0.15))' };
  }
  if (['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac', 'opus'].includes(ext)) {
    return { icon: 'fa-solid fa-file-audio', color: '#06b6d4', label: ext.toUpperCase(), bg: 'linear-gradient(135deg, rgba(6, 182, 212, 0.25), rgba(14, 116, 144, 0.15))' };
  }
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].includes(ext)) {
    return { icon: 'fa-solid fa-file-image', color: '#38bdf8', label: ext.toUpperCase(), bg: 'linear-gradient(135deg, rgba(56, 189, 248, 0.25), rgba(2, 132, 199, 0.15))' };
  }
  return { icon: 'fa-solid fa-file-lines', color: '#94a3b8', label: ext ? ext.toUpperCase() : 'FILE', bg: 'linear-gradient(135deg, rgba(148, 163, 184, 0.25), rgba(71, 85, 105, 0.15))' };
}

function formatMessageText(text) {
  if (!text) return '';
  let clean = escapeHtml(text);
  clean = clean.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>');
  clean = clean.replace(/\*(.*?)\*/g, '<i>$1</i>');
  clean = clean.replace(/`(.*?)`/g, '<code>$1</code>');
  clean = clean.replace(/(https?:\/\/[^\s]+)/g, '<a href="$1" target="_blank" rel="noopener">$1</a>');
  return clean.replace(/\n/g, '<br>');
}

function formatFileSize(bytes) {
  if (!bytes) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

function formatTime(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function formatUserStatus(isOnline, lastSeenIso) {
  if (isOnline) {
    return '<span class="status-dot online"></span> <span class="text-success" style="font-weight:600;">в сети</span>';
  }
  if (!lastSeenIso) {
    return '<span class="status-dot offline"></span> <span class="text-muted">не в сети</span>';
  }
  try {
    const d = new Date(lastSeenIso);
    const now = new Date();
    const diffMs = now - d;
    const diffMins = Math.floor(diffMs / 60000);
    const timeStr = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    if (diffMins < 1) {
      return '<span class="status-dot offline"></span> <span class="text-muted">был(а) только что</span>';
    }
    if (diffMins < 60) {
      return `<span class="status-dot offline"></span> <span class="text-muted">был(а) ${diffMins} мин. назад</span>`;
    }
    const isToday = d.toDateString() === now.toDateString();
    if (isToday) {
      return `<span class="status-dot offline"></span> <span class="text-muted">был(а) сегодня в ${timeStr}</span>`;
    }
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    if (d.toDateString() === yesterday.toDateString()) {
      return `<span class="status-dot offline"></span> <span class="text-muted">был(а) вчера в ${timeStr}</span>`;
    }
    return `<span class="status-dot offline"></span> <span class="text-muted">был(а) ${d.toLocaleDateString([], { day: 'numeric', month: 'short' })} в ${timeStr}</span>`;
  } catch (e) {
    return '<span class="status-dot offline"></span> <span class="text-muted">не в сети</span>';
  }
}

function scrollToBottom() {
  const el = document.getElementById('messagesContainer');
  el.scrollTop = el.scrollHeight;
}

function backToChatsList(triggerHistory = true) {
  document.body.classList.remove('mobile-chat-open');
  activeChat = null;
  const activeChatEl = document.getElementById('activeChatContainer');
  if (activeChatEl) activeChatEl.classList.add('hidden');
  const emptyChatEl = document.getElementById('emptyChatState');
  if (emptyChatEl) emptyChatEl.classList.remove('hidden');
  
  if (triggerHistory && window.location.hash && window.location.hash !== '#/' && window.location.hash !== '') {
    history.pushState({ view: 'list' }, '', '#/');
  }
  renderChatsList();
}

// ----------------------------------------------------
// SEND MESSAGE, EDIT & DELETE ACTIONS
// ----------------------------------------------------

function handleInputKeydown(e) {
  if (e.key === 'Escape') {
    closeGifPicker();
    const emojiPicker = document.getElementById('emojiPicker');
    if (emojiPicker) emojiPicker.classList.add('hidden');
    return;
  }
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    sendMessage();
  }
}

let typingTimeout = null;
function handleTypingEvent() {
  const input = document.getElementById('messageInput');
  const val = input ? input.value : '';
  
  // Real-time Telegram-style /gif and /gif <keyword> detection
  if (val.startsWith('/gif') || val.startsWith('@gif')) {
    let query = val.replace(/^(\/gif\/|\/gif\s*|@gif\s*)/i, '').trim();
    openGifPicker(query);
  }

  if (!socket || !activeChat) return;
  socket.emit('typing', { chatId: activeChat.id, isTyping: true });
  clearTimeout(typingTimeout);
  typingTimeout = setTimeout(() => {
    socket.emit('typing', { chatId: activeChat.id, isTyping: false });
  }, 1500);
}

function sendMessage() {
  const input = document.getElementById('messageInput');
  const text = input.value.trim();
  if (!text || !activeChat || !socket) return;

  if (editingMessage) {
    // Edit existing message
    socket.emit('edit_message', {
      chatId: activeChat.id,
      messageId: editingMessage.id,
      text
    }, (res) => {
      if (res && res.error) alert(res.error);
    });
    cancelReplyOrEdit();
    input.value = '';
    input.style.height = 'auto';
    return;
  }

  const currentChatId = activeChat.id;
  socket.emit('send_message', {
    chatId: currentChatId,
    text,
    type: 'text',
    replyToId: replyMessage ? replyMessage.id : null
  }, (res) => {
    if (res && res.error) {
      alert(res.error);
      return;
    }
    if (res && res.message && activeChat && Number(activeChat.id) === Number(res.message.chat_id)) {
      if (!document.getElementById(`msg-${res.message.id}`)) {
        appendMessageToView(res.message);
        scrollToBottom();
      }
      loadChats();
    }
  });

  input.value = '';
  input.style.height = 'auto';
  document.getElementById('sendBtn').classList.add('hidden');
  document.getElementById('voiceBtn').classList.remove('hidden');
  cancelReplyOrEdit();
}

function startEditMessage(messageId, currentText) {
  editingMessage = { id: messageId, text: currentText };
  replyMessage = null;

  document.getElementById('replyPreviewBar').classList.remove('hidden');
  document.getElementById('replyPreviewIcon').className = 'fa-solid fa-pencil text-warning';
  document.getElementById('replyToName').innerText = 'Редактирование сообщения';
  document.getElementById('replyToText').innerText = currentText;

  const input = document.getElementById('messageInput');
  input.value = currentText;
  input.focus();
  input.dispatchEvent(new Event('input'));
}

function deleteMessageById(messageId) {
  if (!activeChat || !socket) return;
  if (!confirm('Удалить это сообщение?')) return;

  socket.emit('delete_message', {
    chatId: activeChat.id,
    messageId
  }, (res) => {
    if (res && res.error) alert(res.error);
  });
}

function setReplyMessage(msg) {
  editingMessage = null;
  replyMessage = msg;
  document.getElementById('replyPreviewBar').classList.remove('hidden');
  document.getElementById('replyPreviewIcon').className = 'fa-solid fa-reply reply-icon';
  document.getElementById('replyToName').innerText = msg.sender.name;
  document.getElementById('replyToText').innerText = msg.type === 'text' ? msg.text : `[${msg.type}]`;
}

function setReplyMessageById(messageId) {
  const row = document.getElementById(`msg-${messageId}`);
  if (!row) return;
  const nameEl = row.querySelector('.msg-sender-name span') || row.querySelector('.msg-reply-sender');
  const textEl = row.querySelector('.msg-text-content');
  const name = nameEl ? nameEl.innerText : 'Собеседник';
  const text = textEl ? textEl.innerText : 'Вложение';
  setReplyMessage({ id: messageId, sender: { name }, type: 'text', text });
}

function cancelReplyOrEdit() {
  replyMessage = null;
  editingMessage = null;
  document.getElementById('replyPreviewBar').classList.add('hidden');
}

function toggleAttachmentMenu() {
  document.getElementById('attachmentMenu').classList.toggle('hidden');
}

function triggerFileInput(acceptType) {
  const fileInput = document.getElementById('hiddenFileInput');
  fileInput.accept = acceptType;
  fileInput.click();
  document.getElementById('attachmentMenu').classList.add('hidden');
}

// ----------------------------------------------------
// FILE UPLOAD WITH PROGRESS BAR
// ----------------------------------------------------

async function handleFileSelected(e) {
  const file = e.target.files[0];
  if (!file || !activeChat) return;

  const formData = new FormData();
  formData.append('file', file);

  const progressBar = document.getElementById('uploadProgressBar');
  const progressFill = document.getElementById('uploadProgressFill');
  const progressText = document.getElementById('uploadProgressText');

  progressBar.classList.remove('hidden');
  progressFill.style.width = '0%';
  progressText.innerHTML = `<i class="fa-solid fa-cloud-arrow-up fa-fade"></i> Загрузка ${escapeHtml(file.name)}: 0%`;

  const xhr = new XMLHttpRequest();
  currentUploadXhr = xhr;

  xhr.upload.onprogress = (event) => {
    if (event.lengthComputable) {
      const percent = Math.round((event.loaded / event.total) * 100);
      progressFill.style.width = percent + '%';
      progressText.innerHTML = `<i class="fa-solid fa-cloud-arrow-up fa-fade"></i> Загрузка ${escapeHtml(file.name)}: ${percent}% (${formatFileSize(event.loaded)} / ${formatFileSize(event.total)})`;
    }
  };

  xhr.onload = () => {
    progressBar.classList.add('hidden');
    currentUploadXhr = null;
    if (xhr.status >= 200 && xhr.status < 300) {
      try {
        const data = JSON.parse(xhr.responseText);
        socket.emit('send_message', {
          chatId: activeChat.id,
          type: data.type,
          fileUrl: data.url,
          fileName: data.name,
          fileSize: data.size,
          replyToId: replyMessage ? replyMessage.id : null
        });
        cancelReplyOrEdit();
      } catch (e) {
        alert('Ошибка обработки ответа сервера');
      }
    } else {
      alert('Ошибка загрузки файла на сервер');
    }
  };

  xhr.onerror = () => {
    progressBar.classList.add('hidden');
    currentUploadXhr = null;
    alert('Сетевая ошибка при передаче файла');
  };

  xhr.open('POST', '/api/upload');
  xhr.setRequestHeader('Authorization', `Bearer ${token}`);
  xhr.send(formData);
}

function cancelCurrentUpload() {
  if (currentUploadXhr) {
    currentUploadXhr.abort();
    currentUploadXhr = null;
    document.getElementById('uploadProgressBar').classList.add('hidden');
    showToast('Загрузка отменена');
  }
}

// ----------------------------------------------------
// SCHEDULED MESSAGES (Отправить позже)
// ----------------------------------------------------

function openScheduleModal() {
  const input = document.getElementById('messageInput');
  if (!input.value.trim()) {
    return alert('Сначала напишите текст сообщения в поле ввода');
  }
  const now = new Date(Date.now() + 10 * 60000); // 10 min from now
  const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  document.getElementById('scheduleDatetimeInput').value = localIso;
  document.getElementById('scheduleModal').classList.remove('hidden');
}

function setQuickScheduleTime(minutes) {
  const target = new Date(Date.now() + minutes * 60000);
  const localIso = new Date(target.getTime() - target.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  document.getElementById('scheduleDatetimeInput').value = localIso;
}

function setQuickScheduleTomorrow() {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(9, 0, 0, 0);
  const localIso = new Date(tomorrow.getTime() - tomorrow.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  document.getElementById('scheduleDatetimeInput').value = localIso;
}

function submitScheduledMessage() {
  const dtVal = document.getElementById('scheduleDatetimeInput').value;
  if (!dtVal) return alert('Выберите дату и время отправки');

  const scheduledDate = new Date(dtVal);
  if (scheduledDate <= new Date()) {
    return alert('Время отправки должно быть в будущем');
  }

  const input = document.getElementById('messageInput');
  const text = input.value.trim();
  if (!text || !activeChat || !socket) return;

  socket.emit('send_message', {
    chatId: activeChat.id,
    text,
    type: 'text',
    scheduledAt: scheduledDate.toISOString(),
    replyToId: replyMessage ? replyMessage.id : null
  }, (res) => {
    if (res && res.error) {
      alert(res.error);
    } else {
      closeModal('scheduleModal');
      input.value = '';
      input.style.height = 'auto';
      cancelReplyOrEdit();
      showToast(`Сообщение запланировано на ${scheduledDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}, ${scheduledDate.toLocaleDateString()}`);
    }
  });
}

// ----------------------------------------------------
// VOICE MESSAGES
// ----------------------------------------------------

async function toggleVoiceRecording() {
  if (mediaRecorder && mediaRecorder.state === 'recording') {
    stopAndSendVoice();
    return;
  }

  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    mediaRecorder = new MediaRecorder(stream);
    audioChunks = [];

    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) audioChunks.push(e.data);
    };

    mediaRecorder.start();
    voiceStartTime = Date.now();
    document.getElementById('voiceRecordingBar').classList.remove('hidden');
    document.getElementById('voiceBtn').classList.add('hidden');

    voiceTimerInterval = setInterval(() => {
      const sec = Math.floor((Date.now() - voiceStartTime) / 1000);
      const m = String(Math.floor(sec / 60)).padStart(2, '0');
      const s = String(sec % 60).padStart(2, '0');
      document.getElementById('voiceTimer').innerText = `${m}:${s}`;
    }, 500);
  } catch (err) {
    alert('Разрешите доступ к микрофону в браузере для отправки голосовых сообщений.');
  }
}

function cancelVoiceRecording() {
  if (mediaRecorder) {
    mediaRecorder.stop();
    mediaRecorder.stream.getTracks().forEach(t => t.stop());
  }
  clearInterval(voiceTimerInterval);
  document.getElementById('voiceRecordingBar').classList.add('hidden');
  document.getElementById('voiceBtn').classList.remove('hidden');
}

function stopAndSendVoice() {
  if (!mediaRecorder) return;

  mediaRecorder.onstop = async () => {
    const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
    const formData = new FormData();
    formData.append('file', audioBlob, 'voice_' + Date.now() + '.webm');

    try {
      const res = await fetch('/api/upload', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: formData
      });
      const data = await res.json();
      if (res.ok && activeChat) {
        socket.emit('send_message', {
          chatId: activeChat.id,
          type: 'voice',
          fileUrl: data.url,
          fileName: 'Голосовое сообщение',
          fileSize: audioBlob.size
        });
      }
    } catch (e) {
      alert('Ошибка отправки голосового сообщения');
    }
  };

  mediaRecorder.stop();
  mediaRecorder.stream.getTracks().forEach(t => t.stop());
  clearInterval(voiceTimerInterval);
  document.getElementById('voiceRecordingBar').classList.add('hidden');
  document.getElementById('voiceBtn').classList.remove('hidden');
}

// ----------------------------------------------------
// ADVANCED AUDIO & VOICE PLAYER CONTROLLER
// ----------------------------------------------------

let globalAudioPlayer = {
  audio: null,
  currentUrl: null,
  currentBtn: null,
  currentContainer: null,
  playbackRate: 1.0
};

function formatAudioTime(seconds) {
  if (isNaN(seconds) || seconds === Infinity || seconds < 0) return '0:00';
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

function updateAudioProgressUI(container, currentTime, duration) {
  if (!container) return;
  const fill = container.querySelector('.audio-seek-fill');
  const thumb = container.querySelector('.audio-seek-thumb');
  const currentTimeEl = container.querySelector('.audio-current-time');
  const totalTimeEl = container.querySelector('.audio-total-time');

  const dur = duration && !isNaN(duration) ? duration : 0;
  const cur = currentTime && !isNaN(currentTime) ? currentTime : 0;
  const ratio = dur > 0 ? Math.min(100, Math.max(0, (cur / dur) * 100)) : 0;

  if (fill) fill.style.width = `${ratio}%`;
  if (thumb) thumb.style.left = `${ratio}%`;
  if (currentTimeEl) currentTimeEl.textContent = formatAudioTime(cur);
  if (totalTimeEl && dur > 0) totalTimeEl.textContent = formatAudioTime(dur);
}

function resetPreviousAudioUI() {
  if (globalAudioPlayer.currentBtn) {
    globalAudioPlayer.currentBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
    globalAudioPlayer.currentBtn.classList.remove('playing');
  }
  if (globalAudioPlayer.currentContainer) {
    globalAudioPlayer.currentContainer.classList.remove('is-playing');
  }
}

function togglePlayAudio(btn, url, startRatio = null) {
  const container = btn.closest('.msg-audio-card, .msg-voice-box');

  // If clicking play/pause on currently active audio
  if (globalAudioPlayer.currentUrl === url && globalAudioPlayer.audio) {
    if (!globalAudioPlayer.audio.paused) {
      globalAudioPlayer.audio.pause();
      btn.innerHTML = '<i class="fa-solid fa-play"></i>';
      btn.classList.remove('playing');
      if (container) container.classList.remove('is-playing');
      return;
    } else {
      globalAudioPlayer.audio.playbackRate = globalAudioPlayer.playbackRate;
      globalAudioPlayer.audio.play();
      btn.innerHTML = '<i class="fa-solid fa-pause"></i>';
      btn.classList.add('playing');
      if (container) container.classList.add('is-playing');
      return;
    }
  }

  // Stop previous audio if playing
  if (globalAudioPlayer.audio) {
    globalAudioPlayer.audio.pause();
    resetPreviousAudioUI();
  }

  // Create new Audio instance
  const audio = new Audio(url);
  audio.playbackRate = globalAudioPlayer.playbackRate;
  globalAudioPlayer.audio = audio;
  globalAudioPlayer.currentUrl = url;
  globalAudioPlayer.currentBtn = btn;
  globalAudioPlayer.currentContainer = container;

  btn.innerHTML = '<i class="fa-solid fa-pause"></i>';
  btn.classList.add('playing');
  if (container) container.classList.add('is-playing');

  audio.addEventListener('loadedmetadata', () => {
    if (startRatio !== null && audio.duration) {
      audio.currentTime = startRatio * audio.duration;
    }
    updateAudioProgressUI(container, audio.currentTime, audio.duration);
  });

  audio.addEventListener('timeupdate', () => {
    updateAudioProgressUI(container, audio.currentTime, audio.duration);
  });

  audio.addEventListener('ended', () => {
    btn.innerHTML = '<i class="fa-solid fa-play"></i>';
    btn.classList.remove('playing');
    if (container) {
      container.classList.remove('is-playing');
      updateAudioProgressUI(container, 0, audio.duration);
    }
  });

  audio.addEventListener('error', () => {
    btn.innerHTML = '<i class="fa-solid fa-play"></i>';
    btn.classList.remove('playing');
    if (container) container.classList.remove('is-playing');
  });

  audio.play().catch(e => {
    console.warn("Audio play error:", e);
    btn.innerHTML = '<i class="fa-solid fa-play"></i>';
    btn.classList.remove('playing');
    if (container) container.classList.remove('is-playing');
  });
}

function handleAudioSeekClick(e, trackEl, url) {
  const container = trackEl.closest('.msg-audio-card, .msg-voice-box');
  const rect = trackEl.getBoundingClientRect();
  const clickX = e.clientX - rect.left;
  const ratio = Math.max(0, Math.min(1, clickX / rect.width));

  if (globalAudioPlayer.currentUrl === url && globalAudioPlayer.audio && globalAudioPlayer.audio.duration) {
    globalAudioPlayer.audio.currentTime = ratio * globalAudioPlayer.audio.duration;
    updateAudioProgressUI(container, globalAudioPlayer.audio.currentTime, globalAudioPlayer.audio.duration);
  } else {
    const playBtn = container.querySelector('.audio-play-btn');
    if (playBtn) togglePlayAudio(playBtn, url, ratio);
  }
}

function seekAudioRelative(btn, offsetSeconds) {
  const container = btn.closest('.msg-audio-card, .msg-voice-box');
  if (globalAudioPlayer.audio && globalAudioPlayer.currentContainer === container) {
    const dur = globalAudioPlayer.audio.duration || 0;
    const newTime = Math.max(0, Math.min(dur, globalAudioPlayer.audio.currentTime + offsetSeconds));
    globalAudioPlayer.audio.currentTime = newTime;
    updateAudioProgressUI(container, newTime, dur);
  }
}

function cycleAudioSpeed(btn) {
  const rates = [1.0, 1.5, 2.0];
  const currentIdx = rates.indexOf(globalAudioPlayer.playbackRate);
  const nextIdx = (currentIdx + 1) % rates.length;
  globalAudioPlayer.playbackRate = rates[nextIdx];

  document.querySelectorAll('.audio-speed-btn').forEach(b => {
    b.textContent = `${globalAudioPlayer.playbackRate}x`;
  });

  if (globalAudioPlayer.audio) {
    globalAudioPlayer.audio.playbackRate = globalAudioPlayer.playbackRate;
  }
}

function togglePlayVoice(btn, url) {
  togglePlayAudio(btn, url);
}

// ----------------------------------------------------
// EMOJI & REACTIONS
// ----------------------------------------------------

function toggleEmojiPicker() {
  document.getElementById('emojiPicker').classList.toggle('hidden');
}

function loadEmojiCategory(cat, btn) {
  if (btn) {
    document.querySelectorAll('.emoji-category').forEach(el => el.classList.remove('active'));
    btn.classList.add('active');
  }
  const grid = document.getElementById('emojiGrid');
  if (!grid) return;
  const list = (emojis[cat] || []).slice(0, 25);
  grid.innerHTML = list.map(e => `
    <span onclick="insertEmoji('${e}')">${e}</span>
  `).join('');
}

function insertEmoji(e) {
  const input = document.getElementById('messageInput');
  input.value += e;
  input.dispatchEvent(new Event('input'));
  input.focus();
}

function toggleReaction(messageId, emoji) {
  if (!socket || !activeChat) return;
  socket.emit('toggle_reaction', { messageId, emoji, chatId: activeChat.id });
}

function renderReactions(messageId, reactionsMap) {
  const container = document.getElementById(`reactions-${messageId}`);
  if (!container) return;
  container.innerHTML = '';

  if (!reactionsMap) return;

  Object.entries(reactionsMap).forEach(([emoji, users]) => {
    if (!users || users.length === 0) return;
    const tag = document.createElement('span');
    tag.className = 'reaction-tag';
    tag.innerHTML = `${emoji} ${users.length}`;
    tag.title = users.map(u => u.name).join(', ');
    tag.onclick = () => toggleReaction(messageId, emoji);
    container.appendChild(tag);
  });
}

// ----------------------------------------------------
// 5x5 (25 EMOJIS) REACTION PICKER (NO SCROLLBAR)
// ----------------------------------------------------
const POPULAR_EMOJIS_25 = [
  '👏','😮','😢','😍','🎉',
  '🤔','🚀','💯','🤝','🙏',
  '😎','🤣','🥳','🤩','😡',
  '💩','🤯','😱','🤫','👀',
  '💎','✨','⚡','🎯','👌'
];

let activeReactionMessageId = null;

function openReactionPicker(e, messageId) {
  if (e) e.stopPropagation();
  activeReactionMessageId = messageId;
  const popover = document.getElementById('reactionPopover');
  const grid = document.getElementById('reactionGrid25');
  if (!popover || !grid) return;

  grid.innerHTML = POPULAR_EMOJIS_25.map(emoji => `
    <div class="emoji-btn-25" onclick="select25Reaction('${emoji}')">${emoji}</div>
  `).join('');

  popover.classList.remove('hidden');

  const target = e.currentTarget || e.target;
  const rect = target.getBoundingClientRect();
  const popoverWidth = 250;
  const popoverHeight = 280;

  let left = rect.left - 100;
  let top = rect.top - popoverHeight - 8;

  if (left < 10) left = 10;
  if (left + popoverWidth > window.innerWidth - 10) left = window.innerWidth - popoverWidth - 10;
  if (top < 10) top = rect.bottom + 8;

  popover.style.left = `${left}px`;
  popover.style.top = `${top}px`;
}

function select25Reaction(emoji) {
  if (activeReactionMessageId) {
    toggleReaction(activeReactionMessageId, emoji);
  }
  closeReactionPicker();
}

function closeReactionPicker() {
  const popover = document.getElementById('reactionPopover');
  if (popover) popover.classList.add('hidden');
  activeReactionMessageId = null;
}

document.addEventListener('click', (e) => {
  const popover = document.getElementById('reactionPopover');
  if (popover && !popover.classList.contains('hidden')) {
    if (!popover.contains(e.target) && !e.target.closest('.reaction-more')) {
      closeReactionPicker();
    }
  }
});

// ----------------------------------------------------
// MULTI-MESSAGE SELECTION SYSTEM
// ----------------------------------------------------
function toggleSelectionMode(forceState) {
  if (typeof forceState === 'boolean') {
    isSelectionMode = forceState;
  } else {
    isSelectionMode = !isSelectionMode;
  }

  const bar = document.getElementById('selectionBar');
  const container = document.getElementById('messagesContainer');
  const headerBtn = document.getElementById('headerSelectMessagesBtn');

  if (isSelectionMode) {
    if (bar) bar.classList.remove('hidden');
    if (container) container.classList.add('selection-mode');
    if (headerBtn) headerBtn.classList.add('active');
  } else {
    if (bar) bar.classList.add('hidden');
    if (container) container.classList.remove('selection-mode');
    if (headerBtn) headerBtn.classList.remove('active');
    selectedMessageIds.clear();
    document.querySelectorAll('.msg-row.selected').forEach(r => r.classList.remove('selected'));
  }

  updateSelectionUI();
}

function exitSelectionMode() {
  toggleSelectionMode(false);
}

function toggleSelectMessage(msgId, event) {
  if (event) {
    event.stopPropagation();
  }

  // If selection mode wasn't active, activate it immediately
  if (!isSelectionMode) {
    toggleSelectionMode(true);
  }

  const id = Number(msgId);
  const row = document.getElementById(`msg-${id}`);

  if (selectedMessageIds.has(id)) {
    selectedMessageIds.delete(id);
    if (row) row.classList.remove('selected');
  } else {
    selectedMessageIds.add(id);
    if (row) row.classList.add('selected');
  }

  updateSelectionUI();
}

function toggleSelectAllMessages() {
  if (!activeChat) return;
  if (!isSelectionMode) {
    toggleSelectionMode(true);
  }

  const allRows = Array.from(document.querySelectorAll('#messagesScroll .msg-row'));
  const allIds = allRows.map(r => Number(r.id.replace('msg-', ''))).filter(n => !isNaN(n));

  const allSelected = allIds.length > 0 && allIds.every(id => selectedMessageIds.has(id));

  if (allSelected) {
    // Unselect all
    selectedMessageIds.clear();
    allRows.forEach(r => r.classList.remove('selected'));
  } else {
    // Select all
    allIds.forEach(id => selectedMessageIds.add(id));
    allRows.forEach(r => r.classList.add('selected'));
  }

  updateSelectionUI();
}

function updateSelectionUI() {
  const count = selectedMessageIds.size;
  const countText = document.getElementById('selectionCountText');
  const forwardCountBadge = document.getElementById('forwardSelectedCountBadge');
  const deleteCountBadge = document.getElementById('deleteSelectedCountBadge');
  const forwardBtn = document.getElementById('deleteSelectedBtn') ? document.getElementById('forwardSelectedBtn') : null;
  const deleteBtn = document.getElementById('deleteSelectedBtn');
  const selectAllBtn = document.getElementById('selectAllBtn');

  if (countText) countText.innerText = `Выбрано: ${count}`;
  if (forwardCountBadge) forwardCountBadge.innerText = count;
  if (deleteCountBadge) deleteCountBadge.innerText = count;

  if (forwardBtn) forwardBtn.disabled = count === 0;
  if (deleteBtn) deleteBtn.disabled = count === 0;

  const allRows = document.querySelectorAll('#messagesScroll .msg-row');
  const totalCount = allRows.length;

  if (selectAllBtn) {
    if (totalCount > 0 && count === totalCount) {
      selectAllBtn.innerHTML = '<i class="fa-solid fa-xmark"></i> Снять выбор';
    } else {
      selectAllBtn.innerHTML = '<i class="fa-solid fa-check-double"></i> Выбрать все';
    }
  }
}

function forwardSelectedMessages() {
  if (selectedMessageIds.size === 0) return;
  const idsArray = Array.from(selectedMessageIds).sort((a, b) => a - b);
  openForwardModal(idsArray);
}

function deleteSelectedMessages() {
  if (!activeChat || !socket || selectedMessageIds.size === 0) return;

  const count = selectedMessageIds.size;
  const confirmMsg = count === 1 
    ? 'Удалить выбранное сообщение?' 
    : `Удалить выбранные сообщения (${count} шт.)?`;

  if (!confirm(confirmMsg)) return;

  const idsArray = Array.from(selectedMessageIds);
  const deleteBtn = document.getElementById('deleteSelectedBtn');
  if (deleteBtn) {
    deleteBtn.disabled = true;
    deleteBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Удаление...';
  }

  socket.emit('delete_messages', {
    chatId: activeChat.id,
    messageIds: idsArray
  }, (res) => {
    if (deleteBtn) {
      deleteBtn.disabled = false;
      deleteBtn.innerHTML = `<i class="fa-solid fa-trash"></i> Удалить (<span id="deleteSelectedCountBadge">0</span>)`;
    }

    if (res && res.error) {
      alert(res.error);
    } else {
      showToast(`Удалено сообщений: ${res && res.count !== undefined ? res.count : idsArray.length}`);
      exitSelectionMode();
    }
  });
}

// ----------------------------------------------------
// FORWARD MESSAGE SYSTEM (Compact Vertical & Multi-Select)
// ----------------------------------------------------
let forwardMessageIds = []; // Can be array of IDs or single ID in array
let forwardSelectedRecipients = new Set();
let forwardAvailableItems = [];

async function openForwardModal(targetIds) {
  if (Array.isArray(targetIds)) {
    forwardMessageIds = targetIds.map(Number);
  } else if (targetIds) {
    forwardMessageIds = [Number(targetIds)];
  } else {
    forwardMessageIds = [];
  }

  forwardSelectedRecipients.clear();
  updateForwardSubmitButton();

  const modal = document.getElementById('forwardModal');
  const modalTitle = document.getElementById('forwardModalTitle');
  const searchInput = document.getElementById('forwardSearchInput');
  const listContainer = document.getElementById('forwardRecipientsList');

  if (modalTitle) {
    const count = forwardMessageIds.length;
    modalTitle.innerHTML = `<i class="fa-solid fa-share text-primary"></i> Переслать ${count > 1 ? `сообщения (${count})` : 'сообщение'}`;
  }

  if (searchInput) searchInput.value = '';
  modal.classList.remove('hidden');

  listContainer.innerHTML = '<div class="text-center text-muted" style="padding: 20px;"><i class="fa-solid fa-spinner fa-spin"></i> Загрузка получателей...</div>';

  try {
    const chatsRes = await fetch('/api/chats', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const chatsData = await chatsRes.json();
    const chats = chatsData.chats || [];

    const usersRes = await fetch('/api/users/search?q=', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const usersData = await usersRes.json();
    const users = usersData.users || [];

    forwardAvailableItems = [];

    chats.forEach(c => {
      forwardAvailableItems.push({
        key: `chat_${c.id}`,
        type: 'chat',
        chatId: c.id,
        name: c.name,
        handle: c.type === 'group' ? 'Группа' : `@${c.other_user?.username || 'диалог'}`,
        avatar: c.avatar || (c.other_user ? c.other_user.avatar : null)
      });
    });

    const chatUserIds = new Set(chats.filter(c => c.type === 'direct' && c.other_user).map(c => c.other_user.id));
    users.forEach(u => {
      if (!chatUserIds.has(u.id) && u.id !== currentUser.id) {
        forwardAvailableItems.push({
          key: `user_${u.id}`,
          type: 'user',
          userId: u.id,
          name: u.name,
          handle: `@${u.username}`,
          avatar: u.avatar
        });
      }
    });

    renderForwardList(forwardAvailableItems);
  } catch (err) {
    listContainer.innerHTML = '<div class="text-center text-danger" style="padding: 16px;">Ошибка загрузки списка</div>';
  }
}

function renderForwardList(items) {
  const listContainer = document.getElementById('forwardRecipientsList');
  if (!listContainer) return;

  if (items.length === 0) {
    listContainer.innerHTML = '<div class="text-center text-muted" style="padding: 20px;">Получатели не найдены</div>';
    return;
  }

  listContainer.innerHTML = items.map(item => {
    const isSelected = forwardSelectedRecipients.has(item.key);
    return `
      <div class="forward-recipient-row ${isSelected ? 'selected' : ''}" onclick="toggleForwardRecipient('${item.key}')">
        <div class="forward-recipient-left">
          ${renderAvatar(item.avatar, item.name, 'avatar-sm')}
          <div style="min-width: 0;">
            <div class="forward-recipient-name">${escapeHtml(item.name)}</div>
            <div class="forward-recipient-handle">${escapeHtml(item.handle)}</div>
          </div>
        </div>
        <div class="forward-checkbox">
          <i class="fa-solid fa-check"></i>
        </div>
      </div>
    `;
  }).join('');
}

function filterForwardRecipients(query) {
  const q = (query || '').toLowerCase().trim();
  if (!q) {
    renderForwardList(forwardAvailableItems);
    return;
  }
  const filtered = forwardAvailableItems.filter(item => 
    item.name.toLowerCase().includes(q) || item.handle.toLowerCase().includes(q)
  );
  renderForwardList(filtered);
}

function toggleForwardRecipient(key) {
  if (forwardSelectedRecipients.has(key)) {
    forwardSelectedRecipients.delete(key);
  } else {
    forwardSelectedRecipients.add(key);
  }
  const searchVal = document.getElementById('forwardSearchInput').value;
  filterForwardRecipients(searchVal);
  updateForwardSubmitButton();
}

function updateForwardSubmitButton() {
  const count = forwardSelectedRecipients.size;
  const countEl = document.getElementById('forwardSelectedCount');
  const btn = document.getElementById('submitForwardBtn');
  if (countEl) countEl.innerText = count;
  if (btn) btn.disabled = count === 0;
}

async function submitForwardMessage() {
  if (!forwardMessageIds || forwardMessageIds.length === 0 || forwardSelectedRecipients.size === 0) return;

  const btn = document.getElementById('submitForwardBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Пересылка...';

  try {
    const targetChatIds = [];

    for (const key of forwardSelectedRecipients) {
      if (key.startsWith('chat_')) {
        targetChatIds.push(Number(key.replace('chat_', '')));
      } else if (key.startsWith('user_')) {
        const targetUserId = Number(key.replace('user_', ''));
        const directRes = await fetch('/api/chats/direct', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
          body: JSON.stringify({ targetUserId })
        });
        const directData = await directRes.json();
        if (directRes.ok && directData.chatId) {
          targetChatIds.push(directData.chatId);
        }
      }
    }

    if (targetChatIds.length === 0) {
      alert('Не удалось определить целевые чаты');
      btn.disabled = false;
      btn.innerHTML = `<i class="fa-solid fa-paper-plane"></i> Переслать (<span id="forwardSelectedCount">${forwardSelectedRecipients.size}</span>)`;
      return;
    }

    if (forwardMessageIds.length === 1) {
      // Single message forward
      socket.emit('forward_message', {
        messageId: forwardMessageIds[0],
        targetChatIds
      }, (resp) => {
        btn.disabled = false;
        btn.innerHTML = `<i class="fa-solid fa-paper-plane"></i> Переслать (<span id="forwardSelectedCount">0</span>)`;
        if (resp && resp.error) {
          alert(resp.error);
        } else {
          closeModal('forwardModal');
          showToast(`Сообщение успешно переслано (${targetChatIds.length})!`);
          exitSelectionMode();
          loadChats();
        }
      });
    } else {
      // Multi-message batch forward
      socket.emit('forward_messages', {
        messageIds: forwardMessageIds,
        targetChatIds
      }, (resp) => {
        btn.disabled = false;
        btn.innerHTML = `<i class="fa-solid fa-paper-plane"></i> Переслать (<span id="forwardSelectedCount">0</span>)`;
        if (resp && resp.error) {
          alert(resp.error);
        } else {
          closeModal('forwardModal');
          showToast(`Сообщения успешно пересланы (${forwardMessageIds.length} шт.)!`);
          exitSelectionMode();
          loadChats();
        }
      });
    }
  } catch (err) {
    alert('Ошибка пересылки сообщения');
    btn.disabled = false;
    btn.innerHTML = `<i class="fa-solid fa-paper-plane"></i> Переслать (<span id="forwardSelectedCount">${forwardSelectedRecipients.size}</span>)`;
  }
}

// ----------------------------------------------------
// ALL CONTACTS & DIRECT SEARCH (3 Columns Grid)
// ----------------------------------------------------

async function openNewDirectModal() {
  closeMainMenu();
  document.getElementById('directSearchInput').value = '';
  document.getElementById('newDirectModal').classList.remove('hidden');
  await searchUsersForDirect('');
}

async function searchUsersForDirect(q) {
  const container = document.getElementById('directUsersSelectList');
  if (!container) return;
  container.innerHTML = '<div class="text-center text-muted" style="grid-column: 1 / -1; padding: 16px;"><i class="fa-solid fa-spinner fa-spin"></i> Загрузка контактов...</div>';

  try {
    const res = await fetch(`/api/users/search?q=${encodeURIComponent(q || '')}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    if (!res.ok) {
      if (res.status === 401) { logout(); return; }
      const errData = await res.json();
      container.innerHTML = `<div class="text-center text-danger" style="grid-column: 1 / -1; padding: 16px;">${escapeHtml(errData.error || 'Ошибка загрузки')}</div>`;
      return;
    }
    const data = await res.json();
    const users = data.users || [];

    if (users.length === 0) {
      container.innerHTML = '<div class="text-center text-muted" style="grid-column: 1 / -1; padding: 20px;">Контакты не найдены</div>';
      return;
    }

    container.innerHTML = users.map(u => `
      <div class="user-contact-card" onclick="startDirectWithUser(${u.id})">
        <div class="contact-card-avatar">
          ${renderAvatar(u.avatar, u.name, 'avatar-md')}
        </div>
        <div class="contact-card-info">
          <div class="contact-card-name" title="${escapeHtml(u.name)}">${escapeHtml(u.name)}</div>
          <div class="contact-card-login">@${escapeHtml(u.username)}</div>
        </div>
        <div style="display: flex; gap: 5px; align-items: center;">
          <button class="btn btn-xs btn-primary contact-card-btn" onclick="event.stopPropagation(); startDirectWithUser(${u.id})" title="Написать"><i class="fa-solid fa-paper-plane"></i> Написать</button>
          ${u.id !== currentUser.id ? `
            <button class="btn btn-xs btn-outline btn-report" onclick="event.stopPropagation(); openReportModal(${u.id}, '${escapeForJs(u.name)}', '${escapeForJs(u.username)}', '${escapeForJs(u.avatar || '')}', null, 'Контакты')" title="Пожаловаться на пользователя"><i class="fa-solid fa-triangle-exclamation"></i></button>
          ` : ''}
        </div>
      </div>
    `).join('');
  } catch (e) {
    container.innerHTML = '<div class="text-center text-danger" style="grid-column: 1 / -1; padding: 16px;">Ошибка сети при загрузке контактов</div>';
  }
}

async function startDirectWithUser(targetUserId) {
  try {
    const res = await fetch('/api/chats/direct', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ targetUserId })
    });
    const data = await res.json();
    if (res.ok) {
      closeModal('newDirectModal');
      closeModal('adminModal');
      await loadChats();
      selectChat(data.chatId);
    } else {
      alert(data.error || 'Ошибка начала диалога');
    }
  } catch (e) {
    alert('Сетевая ошибка');
  }
}

// ----------------------------------------------------
// GLOBAL SEARCH
// ----------------------------------------------------

async function handleGlobalSearch(query) {
  const clearBtn = document.getElementById('clearSearchBtn');
  const resultsPanel = document.getElementById('searchResultsPanel');
  const resultsList = document.getElementById('searchUsersList');

  const q = query.trim();
  if (!q) {
    clearBtn.classList.add('hidden');
    resultsPanel.classList.add('hidden');
    renderChatsList();
    return;
  }

  clearBtn.classList.remove('hidden');
  resultsPanel.classList.remove('hidden');

  try {
    const res = await fetch(`/api/users/search?q=${encodeURIComponent(q)}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const { users } = await res.json();

    if (!users || users.length === 0) {
      resultsList.innerHTML = '<div class="text-center text-muted" style="padding: 12px; font-size: 12px;">Пользователи не найдены</div>';
    } else {
      resultsList.innerHTML = users.map(u => `
        <div class="user-select-item" onclick="startDirectWithUser(${u.id})" style="padding: 8px 10px; display: flex; align-items: center; gap: 8px; cursor: pointer;">
          ${renderAvatar(u.avatar, u.name, 'avatar-sm')}
          <div style="flex: 1; min-width: 0;">
            <div style="font-weight: 600; font-size: 13px;">${escapeHtml(u.name)}</div>
            <div style="font-size: 11px; color: var(--accent-color);">@${escapeHtml(u.username)}</div>
          </div>
          <button class="btn btn-xs btn-primary"><i class="fa-solid fa-comment"></i> Написать</button>
        </div>
      `).join('');
    }
  } catch (e) {}
}

function clearGlobalSearch() {
  document.getElementById('globalSearchInput').value = '';
  handleGlobalSearch('');
}

// ----------------------------------------------------
// ADMIN MODERATION PANEL (Владимир) - 2-Line Layout
// ----------------------------------------------------

async function checkPendingUsersCount() {
  try {
    const res = await fetch('/api/admin/stats', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    const badge = document.getElementById('pendingUsersBadge');
    if (data.pendingUsers > 0) {
      badge.innerText = data.pendingUsers;
      badge.classList.remove('hidden');
    } else {
      badge.classList.add('hidden');
    }
  } catch (e) {}
}

async function openAdminModal() {
  closeMainMenu();
  document.getElementById('adminModal').classList.remove('hidden');
  loadAdminData();
}

async function loadAdminData() {
  try {
    const statsRes = await fetch('/api/admin/stats', { headers: { Authorization: `Bearer ${token}` } });
    const stats = await statsRes.json();
    document.getElementById('statPendingCount').innerText = stats.pendingUsers;
    document.getElementById('statApprovedCount').innerText = stats.approvedUsers;
    document.getElementById('statChatsCount').innerText = stats.totalChats;
    document.getElementById('statMessagesCount').innerText = stats.totalMessages;

    const usersRes = await fetch('/api/admin/users', { headers: { Authorization: `Bearer ${token}` } });
    const { users } = await usersRes.json();
    adminAllUsersCache = users || [];

    const pending = (users || []).filter(u => u.status === 'pending');
    const pendingTable = document.getElementById('adminPendingUsersTable');

    if (pending.length === 0) {
      pendingTable.innerHTML = `<tr><td colspan="4" class="text-center text-muted" style="padding: 16px;">Заявок на проверку нет. Все пользователи проверены!</td></tr>`;
    } else {
      pendingTable.innerHTML = pending.map(u => `
        <tr>
          <td>
            <div style="display: flex; align-items: center; gap: 10px;">
              ${renderAvatar(u.avatar, u.name, 'avatar-sm')}
              <div style="min-width: 0;">
                <div style="font-weight: 700; font-size: 13.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(u.name)}</div>
                <div style="font-size: 12px; color: var(--accent-color);">@${escapeHtml(u.username)}</div>
              </div>
            </div>
          </td>
          <td>
            <div style="font-size: 12.5px;"><code>${escapeHtml(u.email || '-')}</code></div>
            <div style="font-size: 11.5px; color: var(--text-muted); margin-top: 2px;">${escapeHtml(u.phone || '-')}</div>
          </td>
          <td>
            <span class="badge badge-warning">Ожидает</span>
          </td>
          <td>
            <div style="display: flex; gap: 6px; flex-wrap: wrap;">
              <button class="btn btn-xs btn-success" onclick="adminApproveUser(${u.id})" title="Одобрить"><i class="fa-solid fa-check"></i> Одобрить</button>
              <button class="btn btn-xs btn-primary" onclick="openAdminEditUserModalById(${u.id})" title="Редактировать"><i class="fa-solid fa-user-pen"></i></button>
              <button class="btn btn-xs btn-danger" onclick="adminSetStatus(${u.id}, 'rejected')" title="Отклонить"><i class="fa-solid fa-xmark"></i></button>
            </div>
          </td>
        </tr>
      `).join('');
    }

    const allTable = document.getElementById('adminAllUsersTable');
    allTable.innerHTML = (users || []).map(u => `
      <tr>
        <td>
          <div style="display: flex; align-items: center; gap: 10px;">
            ${renderAvatar(u.avatar, u.name, 'avatar-sm')}
            <div style="min-width: 0;">
              <div style="font-weight: 700; font-size: 13.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(u.name)}</div>
              <div style="font-size: 12px; color: var(--accent-color);">@${escapeHtml(u.username)}</div>
            </div>
          </div>
        </td>
        <td>
          <div style="font-size: 12.5px;"><code>${escapeHtml(u.email || '-')}</code></div>
          <div style="font-size: 11.5px; color: var(--text-muted); margin-top: 2px;">${escapeHtml(u.phone || '-')}</div>
        </td>
        <td>
          <div style="display: flex; flex-direction: column; gap: 3px;">
            <span class="badge ${u.role === 'superadmin' ? 'badge-danger' : (u.role === 'admin' ? 'badge-warning' : 'badge-primary')}">${u.role}</span>
            <span class="badge ${u.status === 'approved' ? 'badge-success' : 'badge-danger'}">${u.status}</span>
          </div>
        </td>
        <td>
          <div style="display: flex; gap: 5px; flex-wrap: wrap;">
            ${u.id !== currentUser.id ? `
              <button class="btn btn-xs btn-primary" onclick="startDirectWithUser(${u.id})" title="Написать"><i class="fa-solid fa-paper-plane"></i> Написать</button>
              <button class="btn btn-xs btn-warning" onclick="openAdminPassModal(${u.id}, '${escapeHtml(u.name)}', '${escapeHtml(u.username)}')" title="Сменить пароль"><i class="fa-solid fa-key"></i> Пароль</button>
              <button class="btn btn-xs btn-outline" onclick="openAdminMergeModal(${u.id})" title="Объединить этот аккаунт с другим"><i class="fa-solid fa-code-merge"></i> Слить</button>
              <button class="btn btn-xs btn-outline" onclick="openAdminEditUserModalById(${u.id})" title="Изм"><i class="fa-solid fa-user-pen"></i></button>
              <button class="btn btn-xs btn-danger" onclick="adminDeleteUser(${u.id})" title="Удалить"><i class="fa-solid fa-trash"></i></button>
            ` : `
              <button class="btn btn-xs btn-outline" onclick="openAdminEditUserModalById(${u.id})" title="Редактировать"><i class="fa-solid fa-user-pen"></i> Изм</button>
              <button class="btn btn-xs btn-outline" onclick="openAdminMergeModal()" title="Объединить два любых аккаунта"><i class="fa-solid fa-code-merge"></i> Слияние</button>
              <span class="text-muted" style="font-size: 11px; align-self: center;">(Вы)</span>
            `}
          </div>
        </td>
      </tr>
    `).join('');

    // Fetch and render reports
    try {
      const reportsRes = await fetch('/api/admin/reports', { headers: { Authorization: `Bearer ${token}` } });
      const { reports } = await reportsRes.json();
      const reportsTable = document.getElementById('adminReportsTable');
      const reportsCountEl = document.getElementById('adminReportsCount');

      const pendingReports = (reports || []).filter(r => r.status === 'pending');
      if (reportsCountEl) reportsCountEl.innerText = pendingReports.length;

      if (!reports || reports.length === 0) {
        if (reportsTable) reportsTable.innerHTML = `<tr><td colspan="4" class="text-center text-muted" style="padding: 16px;">Активных жалоб нет</td></tr>`;
      } else {
        if (reportsTable) {
          reportsTable.innerHTML = reports.map(r => {
            const isResolved = r.status === 'resolved';
            const isDismissed = r.status === 'dismissed';
            return `
              <tr style="${isResolved || isDismissed ? 'opacity: 0.6;' : ''}">
                <td>
                  <div style="display: flex; align-items: center; gap: 8px;">
                    ${renderAvatar(r.reported_avatar, r.reported_name, 'avatar-sm')}
                    <div style="min-width: 0;">
                      <div style="font-weight: 700; font-size: 13px;">${escapeHtml(r.reported_name)}</div>
                      <div style="font-size: 11.5px; color: #ef4444;">@${escapeHtml(r.reported_username)}</div>
                      <span class="badge ${r.reported_status === 'banned' ? 'badge-danger' : 'badge-primary'}" style="font-size: 10px;">${r.reported_status}</span>
                    </div>
                  </div>
                </td>
                <td>
                  <div style="display: flex; align-items: center; gap: 8px;">
                    ${renderAvatar(r.reporter_avatar, r.reporter_name, 'avatar-sm')}
                    <div style="min-width: 0;">
                      <div style="font-weight: 600; font-size: 13px;">${escapeHtml(r.reporter_name)}</div>
                      <div style="font-size: 11.5px; color: var(--accent-color);">@${escapeHtml(r.reporter_username)}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <div style="font-size: 11.5px; color: var(--text-muted); margin-bottom: 4px;">
                    <i class="fa-solid fa-comments"></i> <b>Чат:</b> ${escapeHtml(r.chat_name || 'Личный диалог')}
                  </div>
                  <div style="display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 4px;">
                    ${(r.reasons || []).map(reason => `<span class="badge badge-warning" style="font-size: 10.5px;">${escapeHtml(reason)}</span>`).join('')}
                  </div>
                  ${r.comment ? `<div style="font-size: 12px; font-style: italic; color: rgba(255,255,255,0.85); background: rgba(0,0,0,0.2); padding: 4px 8px; border-radius: 6px;">«${escapeHtml(r.comment)}»</div>` : ''}
                </td>
                <td>
                  <div style="display: flex; gap: 5px; flex-wrap: wrap;">
                    ${r.status === 'pending' ? `
                      <button class="btn btn-xs btn-danger" onclick="adminBanUserFromReport(${r.id})" title="Заблокировать нарушителя"><i class="fa-solid fa-ban"></i> Бан</button>
                      <button class="btn btn-xs btn-success" onclick="adminResolveReport(${r.id}, 'resolved')" title="Пометить решенной"><i class="fa-solid fa-check"></i> Закрыть</button>
                      <button class="btn btn-xs btn-outline" onclick="adminResolveReport(${r.id}, 'dismissed')" title="Отклонить"><i class="fa-solid fa-xmark"></i></button>
                    ` : `
                      <span class="badge ${isResolved ? 'badge-success' : 'badge-muted'}">${r.status}</span>
                    `}
                  </div>
                </td>
              </tr>
            `;
          }).join('');
        }
      }
    } catch(e) {}
  } catch (err) {
    console.error('Failed to load admin data:', err);
  }
}

async function adminResolveReport(reportId, status) {
  try {
    const res = await fetch(`/api/admin/reports/${reportId}/status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ status })
    });
    if (res.ok) {
      loadAdminData();
      showToast('Статус жалобы обновлен');
    }
  } catch (e) {}
}

async function adminBanUserFromReport(reportId) {
  if (!confirm('Вы уверены, что хотите навсегда заблокировать этого пользователя?')) return;
  try {
    const res = await fetch(`/api/admin/reports/${reportId}/ban`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` }
    });
    if (res.ok) {
      loadAdminData();
      showToast('Пользователь заблокирован по жалобе');
    }
  } catch (e) {}
}

// ----------------------------------------------------
// USER REPORTS SYSTEM (Пожаловаться)
// ----------------------------------------------------
let selectedReportReasons = new Set();

function openReportModal(targetUserId, targetUserName, targetUserUsername, targetUserAvatar, chatId, chatName) {
  selectedReportReasons.clear();
  document.getElementById('reportTargetUserId').value = targetUserId;
  document.getElementById('reportChatId').value = chatId || '';
  
  document.getElementById('reportUserName').innerText = targetUserName || 'Пользователь';
  document.getElementById('reportUserHandle').innerText = `@${targetUserUsername || 'user'}`;
  document.getElementById('reportChatContext').innerHTML = `<i class="fa-solid fa-users"></i> Контекст: ${escapeHtml(chatName || 'Личные контакты')}`;
  updateAvatarElement('reportUserAvatar', targetUserAvatar, targetUserName, 'avatar-md');

  document.querySelectorAll('.report-reason-item').forEach(item => {
    item.classList.remove('selected');
  });
  document.getElementById('reportCommentInput').value = '';
  updateReportSubmitButton();

  document.getElementById('reportModal').classList.remove('hidden');
}

function toggleReportReason(el, reasonText) {
  if (selectedReportReasons.has(reasonText)) {
    selectedReportReasons.delete(reasonText);
    el.classList.remove('selected');
  } else {
    selectedReportReasons.add(reasonText);
    el.classList.add('selected');
  }
  updateReportSubmitButton();
}

function updateReportSubmitButton() {
  const count = selectedReportReasons.size;
  const countEl = document.getElementById('reportSelectedCount');
  const btn = document.getElementById('submitReportBtn');
  if (countEl) countEl.innerText = count;
  if (btn) btn.disabled = count === 0;
}

async function submitUserReport() {
  const reportedUserId = document.getElementById('reportTargetUserId').value;
  const chatId = document.getElementById('reportChatId').value;
  const comment = document.getElementById('reportCommentInput').value.trim();

  if (!reportedUserId || selectedReportReasons.size === 0) return;

  const btn = document.getElementById('submitReportBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Отправка жалобы...';

  try {
    const res = await fetch('/api/reports', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({
        reportedUserId: Number(reportedUserId),
        chatId: chatId ? Number(chatId) : null,
        reasons: Array.from(selectedReportReasons),
        comment
      })
    });
    const data = await res.json();

    if (res.ok) {
      closeModal('reportModal');
      showToast('🚨 Жалоба отправлена! Все администраторы получили оповещение.');
    } else {
      alert(data.error || 'Ошибка отправки жалобы');
    }
  } catch (err) {
    alert('Сетевая ошибка при отправке жалобы');
  } finally {
    btn.disabled = false;
    btn.innerHTML = `<i class="fa-solid fa-paper-plane"></i> Отправить жалобу администраторам (<span id="reportSelectedCount">${selectedReportReasons.size}</span>)`;
  }
}

async function adminApproveUser(userId) {
  try {
    const res = await fetch(`/api/admin/users/${userId}/approve`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` }
    });
    if (res.ok) {
      loadAdminData();
      checkPendingUsersCount();
      showToast('Пользователь успешно одобрен!');
    }
  } catch (e) {}
}

async function adminSetStatus(userId, status) {
  try {
    await fetch(`/api/admin/users/${userId}/status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ status })
    });
    loadAdminData();
  } catch (e) {}
}

async function adminDeleteUser(userId) {
  if (!confirm('Удалить этого пользователя из системы?')) return;
  try {
    await fetch(`/api/admin/users/${userId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    });
    loadAdminData();
    if (activeChat) selectChat(activeChat.id);
    showToast('Пользователь удален');
  } catch (e) {}
}

// ----------------------------------------------------
// ADMIN PASSWORD RESET MODAL
// ----------------------------------------------------

function openAdminPassModal(userId, name, username) {
  document.getElementById('resetPassUserId').value = userId;
  document.getElementById('resetPassUserName').value = `${name} (@${username})`;
  document.getElementById('resetPassNewVal').value = '';
  document.getElementById('resetPassAlert').className = 'alert-box';
  document.getElementById('adminPassModal').classList.remove('hidden');
}

async function handleAdminResetPassword(e) {
  e.preventDefault();
  const userId = document.getElementById('resetPassUserId').value;
  const newPassword = document.getElementById('resetPassNewVal').value;
  const alertBox = document.getElementById('resetPassAlert');

  try {
    const res = await fetch(`/api/admin/users/${userId}/password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ newPassword })
    });
    const data = await res.json();

    if (!res.ok) {
      alertBox.className = 'alert-box error show';
      alertBox.innerText = data.error || 'Ошибка смены пароля';
      return;
    }

    alertBox.className = 'alert-box success show';
    alertBox.innerText = 'Пароль успешно изменен и сохранен!';
    setTimeout(() => {
      closeModal('adminPassModal');
    }, 1200);
  } catch (err) {
    alertBox.className = 'alert-box error show';
    alertBox.innerText = 'Сетевая ошибка';
  }
}

// ----------------------------------------------------
// ADMIN EDIT USER MODAL
// ----------------------------------------------------

async function openAdminEditUserModalById(userId) {
  try {
    const res = await fetch(`/api/admin/users/${userId}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (!res.ok) {
      alert(data.error || 'Ошибка загрузки данных пользователя');
      return;
    }
    openAdminEditUserModal(data.user);
  } catch (err) {
    alert('Сетевая ошибка при загрузке пользователя');
  }
}

let currentAdminEditingAvatar = null;

function openAdminEditUserModal(user) {
  document.getElementById('adminEditUserId').value = user.id;
  document.getElementById('adminEditUserName').value = user.name || '';
  document.getElementById('adminEditUserLogin').value = user.username || '';
  document.getElementById('adminEditUserEmail').value = user.email || '';
  document.getElementById('adminEditUserPhone').value = user.phone || '';
  document.getElementById('adminEditUserBio').value = user.bio || '';
  document.getElementById('adminEditUserRole').value = user.role || 'user';
  document.getElementById('adminEditUserStatus').value = user.status || 'approved';
  document.getElementById('adminEditUserNewPass').value = '';

  currentAdminEditingAvatar = user.avatar || null;
  updateAvatarElement('adminEditUserAvatarPreview', user.avatar, user.name, 'avatar-md');

  document.getElementById('adminEditUserAlert').className = 'alert-box';
  document.getElementById('adminEditUserModal').classList.remove('hidden');
}

async function handleAdminSaveUser(e) {
  e.preventDefault();
  const userId = document.getElementById('adminEditUserId').value;
  const name = document.getElementById('adminEditUserName').value.trim();
  const username = document.getElementById('adminEditUserLogin').value.trim();
  const email = document.getElementById('adminEditUserEmail').value.trim();
  const phone = document.getElementById('adminEditUserPhone').value.trim();
  const bio = document.getElementById('adminEditUserBio').value.trim();
  const role = document.getElementById('adminEditUserRole').value;
  const status = document.getElementById('adminEditUserStatus').value;
  const newPassword = document.getElementById('adminEditUserNewPass').value;
  const alertBox = document.getElementById('adminEditUserAlert');

  try {
    const res = await fetch(`/api/admin/users/${userId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ name, username, email, phone, bio, role, status, newPassword, avatar: currentAdminEditingAvatar })
    });
    const data = await res.json();

    if (!res.ok) {
      alertBox.className = 'alert-box error show';
      alertBox.innerText = data.error || 'Ошибка сохранения пользователя';
      return;
    }

    alertBox.className = 'alert-box success show';
    alertBox.innerText = 'Данные пользователя успешно сохранены!';
    loadAdminData();
    if (activeChat) renderChatMembersList();
    if (Number(userId) === currentUser.id) {
      currentUser = data.user;
      initApp();
    }
    setTimeout(() => {
      closeModal('adminEditUserModal');
    }, 1200);
  } catch (err) {
    alertBox.className = 'alert-box error show';
    alertBox.innerText = 'Сетевая ошибка сохранения';
  }
}

// ----------------------------------------------------
// GROUP CREATION (3 Columns Grid & Green Glow)
// ----------------------------------------------------

let selectedGroupUserIds = [];

function openNewGroupModal() {
  closeMainMenu();
  selectedGroupUserIds = [];
  document.getElementById('newGroupName').value = '';
  document.getElementById('newGroupDesc').value = '';
  renderSelectedGroupMembers();
  document.getElementById('newGroupModal').classList.remove('hidden');
  searchUsersForGroup('');
}

async function searchUsersForGroup(q) {
  const container = document.getElementById('groupUsersSelectList');
  try {
    const res = await fetch(`/api/users/search?q=${encodeURIComponent(q || '')}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const { users } = await res.json();
    if (!users || users.length === 0) {
      container.innerHTML = '<div class="text-center text-muted" style="grid-column: 1 / -1; padding: 20px;">Пользователи не найдены</div>';
      return;
    }
    container.innerHTML = users.map(u => {
      const isSelected = selectedGroupUserIds.includes(u.id);
      return `
        <div class="user-select-card ${isSelected ? 'selected' : ''}" id="groupCardUser_${u.id}" onclick="toggleSelectGroupUser(${u.id}, '${escapeHtml(u.name)}')">
          <div class="user-card-avatar">
            ${renderAvatar(u.avatar, u.name, 'avatar-md')}
          </div>
          <div class="user-card-info">
            <div class="user-card-name" title="${escapeHtml(u.name)}">${escapeHtml(u.name)}</div>
            <div class="user-card-login">@${escapeHtml(u.username)}</div>
          </div>
          <div class="user-card-check">
            <i class="fa-solid fa-check" style="${isSelected ? '' : 'display:none;'}"></i>
          </div>
        </div>
      `;
    }).join('');
  } catch (e) {
    container.innerHTML = '<div class="text-center text-danger" style="grid-column: 1 / -1; padding: 16px;">Ошибка загрузки</div>';
  }
}

function toggleSelectGroupUser(uid, name) {
  const card = document.getElementById(`groupCardUser_${uid}`);
  if (selectedGroupUserIds.includes(uid)) {
    selectedGroupUserIds = selectedGroupUserIds.filter(id => id !== uid);
    if (card) {
      card.classList.remove('selected');
      const checkIcon = card.querySelector('.user-card-check i');
      if (checkIcon) checkIcon.style.display = 'none';
    }
  } else {
    selectedGroupUserIds.push(uid);
    if (card) {
      card.classList.add('selected');
      const checkIcon = card.querySelector('.user-card-check i');
      if (checkIcon) checkIcon.style.display = 'block';
    }
  }
  renderSelectedGroupMembers();
}

function renderSelectedGroupMembers() {
  const tags = document.getElementById('selectedGroupMembers');
  tags.innerHTML = selectedGroupUserIds.map(uid => `
    <span class="badge badge-warning" style="margin-right: 4px; display: inline-block;">Участник #${uid}</span>
  `).join('');
}

async function createGroupSubmit() {
  const name = document.getElementById('newGroupName').value.trim();
  const desc = document.getElementById('newGroupDesc').value.trim();
  if (!name) return alert('Укажите название группы');

  try {
    const res = await fetch('/api/chats/group', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ name, description: desc, memberIds: selectedGroupUserIds })
    });
    const data = await res.json();
    if (res.ok) {
      closeModal('newGroupModal');
      await loadChats();
      selectChat(data.chatId);
    }
  } catch (e) {}
}

// ----------------------------------------------------
// FULL GROUP DETAILS & MANAGEMENT (Single Row Invite Link)
// ----------------------------------------------------

function openChatDetailsModal() {
  if (!activeChat) return;

  const isGroup = activeChat.type === 'group';
  const directBlock = document.getElementById('directDetailsBlock');
  const groupBlock = document.getElementById('groupDetailsBlock');
  const titleEl = document.getElementById('detailsModalTitle');

  if (isGroup) {
    if (titleEl) titleEl.innerHTML = '<i class="fa-solid fa-users text-primary"></i> Настройки и участники группы';
    if (directBlock) directBlock.classList.add('hidden');
    if (groupBlock) groupBlock.classList.remove('hidden');

    const displayName = activeChat.name || 'Группа';
    updateAvatarElement('detailsAvatar', activeChat.avatar, displayName, 'avatar-lg');

    const canEdit = activeChat.myRole === 'owner' || activeChat.myRole === 'admin' || (currentUser && currentUser.role === 'superadmin');

    const editAvatarBtn = document.getElementById('groupAvatarEditBtn');
    if (editAvatarBtn) editAvatarBtn.style.display = canEdit ? 'flex' : 'none';

    const addMembersBtn = document.getElementById('addGroupMembersBtn');
    if (addMembersBtn) addMembersBtn.style.display = canEdit ? 'inline-flex' : 'none';

    const editNameInput = document.getElementById('editGroupNameInput');
    const editDescInput = document.getElementById('editGroupDescInput');
    const saveBtn = document.getElementById('saveGroupInfoBtn');
    const descView = document.getElementById('groupDescView');

    if (editNameInput) editNameInput.value = activeChat.name || '';
    if (editDescInput) editDescInput.value = activeChat.description || '';

    if (canEdit) {
      if (editNameInput) editNameInput.disabled = false;
      if (editDescInput) editDescInput.style.display = 'block';
      if (saveBtn) saveBtn.style.display = 'inline-flex';
    } else {
      if (editNameInput) editNameInput.disabled = true;
      if (editDescInput) editDescInput.style.display = 'none';
      if (saveBtn) saveBtn.style.display = 'none';
    }

    // Render description with clickable links
    if (descView) {
      if (activeChat.description && activeChat.description.trim()) {
        descView.innerHTML = `<strong>Описание:</strong><br>${formatMessageText(activeChat.description)}`;
        descView.style.display = 'block';
      } else {
        descView.innerHTML = '<span class="text-muted">Описание не указано</span>';
        descView.style.display = canEdit ? 'none' : 'block';
      }
    }

    const inviteInput = document.getElementById('inviteLinkInput');
    const slug = encodeURIComponent((activeChat.name || 'group').trim().replace(/[\s\/]+/g, '_'));
    const code = activeChat.invite_code || activeChat.id;
    if (inviteInput) inviteInput.value = `${window.location.origin}/#/group/${code}/${slug}`;
    const inviteBox = document.getElementById('inviteLinkBox');
    if (inviteBox) inviteBox.classList.remove('hidden');

    renderChatMembersList();
  } else {
    // DIRECT 1-ON-1 CHAT PROFILE
    if (titleEl) titleEl.innerHTML = '';
    if (groupBlock) groupBlock.classList.add('hidden');
    if (directBlock) directBlock.classList.remove('hidden');

    const partner = activeChat.partner || {};
    const partnerName = partner.name || activeChat.name || 'Собеседник';
    const partnerUsername = partner.username || '';
    const partnerAvatar = partner.avatar || activeChat.avatar;
    const partnerRole = partner.role || 'user';
    const isPartnerOnline = partner.is_online || false;

    updateAvatarElement('directDetailsAvatar', partnerAvatar, partnerName, 'avatar-lg');

    const nameEl = document.getElementById('directDetailsName');
    if (nameEl) nameEl.innerText = partnerName;

    const handleEl = document.getElementById('directDetailsHandle');
    if (handleEl) handleEl.innerText = partnerUsername ? `@${partnerUsername}` : '';

    const roleEl = document.getElementById('directDetailsRole');
    if (roleEl) {
      if (partnerRole === 'superadmin') roleEl.innerHTML = '<span class="badge badge-danger">👑 Создатель</span>';
      else if (partnerRole === 'admin') roleEl.innerHTML = '<span class="badge badge-warning">🛡️ Администратор</span>';
      else roleEl.innerHTML = '<span class="badge badge-primary">Пользователь</span>';
    }

    const statusEl = document.getElementById('directDetailsStatus');
    if (statusEl) {
      statusEl.innerHTML = formatUserStatus(isPartnerOnline, partner.last_seen);
    }

    const infoList = document.getElementById('directProfileInfoList');
    if (infoList) {
      let rows = '';
      if (partner.bio && partner.bio.trim()) {
        rows += `
          <div class="direct-info-row">
            <span class="direct-info-label"><i class="fa-solid fa-quote-left text-primary"></i> О себе:</span>
            <span class="direct-info-val">${escapeHtml(partner.bio)}</span>
          </div>`;
      }
      rows += `
        <div class="direct-info-row">
          <span class="direct-info-label"><i class="fa-solid fa-shield-halved text-success"></i> Шифрование:</span>
          <span class="direct-info-val text-success"><i class="fa-solid fa-lock"></i> E2EE AES-256-GCM</span>
        </div>
        <div class="direct-info-row">
          <span class="direct-info-label"><i class="fa-solid fa-network-wired text-primary"></i> Канал связи:</span>
          <span class="direct-info-val text-primary"><i class="fa-solid fa-tower-broadcast"></i> WebRTC P2P Direct</span>
        </div>
      `;
      infoList.innerHTML = rows;
    }

    // Common Groups Rendering
    const commonGroupsList = document.getElementById('directCommonGroupsList');
    const commonGroupsCount = document.getElementById('directCommonGroupsCount');
    const commonGroups = activeChat.commonGroups || [];
    if (commonGroupsCount) commonGroupsCount.innerText = commonGroups.length;
    if (commonGroupsList) {
      if (commonGroups.length > 0) {
        commonGroupsList.innerHTML = commonGroups.map(g => `
          <div class="common-group-item" onclick="closeModal('chatDetailsModal'); selectChat(${g.id});" style="display: flex; align-items: center; justify-content: space-between; padding: 8px 12px; background: var(--bg-secondary); border: 1px solid var(--border-color); border-radius: 10px; cursor: pointer; transition: all 0.2s ease;">
            <div style="display: flex; align-items: center; gap: 10px; min-width: 0;">
              ${renderAvatar(g.avatar, g.name, 'avatar-sm')}
              <div style="min-width: 0;">
                <div style="font-weight: 700; font-size: 13px; color: var(--text-main);">${escapeHtml(g.name)}</div>
                <div style="font-size: 11.5px; color: var(--text-muted);">${g.member_count || 1} участников</div>
              </div>
            </div>
            <i class="fa-solid fa-chevron-right text-muted" style="font-size: 12px;"></i>
          </div>
        `).join('');
      } else {
        commonGroupsList.innerHTML = '<div style="font-size: 12px; color: var(--text-muted); padding: 4px 0;">Нет общих групп с этим контактом</div>';
      }
    }
  }

  document.getElementById('chatDetailsModal').classList.remove('hidden');
}

function startDirectCallFromDetails(type = 'audio') {
  closeModal('chatDetailsModal');
  startDirectCall(type);
}

function openWallpaperFromDetails() {
  closeModal('chatDetailsModal');
  openWallpaperModal();
}

function copyDirectContactLink() {
  if (!activeChat) return;
  const link = `${window.location.origin}/#/c/${activeChat.id}`;
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(link).then(() => {
      showToast('Ссылка на диалог скопирована в буфер!');
    }).catch(() => {
      prompt('Скопируйте ссылку на диалог:', link);
    });
  } else {
    prompt('Скопируйте ссылку на диалог:', link);
  }
}

function renderChatMembersList() {
  const list = document.getElementById('chatMembersList');
  if (!list || !activeChat) return;
  const isOwnerOrSuper = activeChat.myRole === 'owner' || (currentUser && currentUser.role === 'superadmin');
  const isAdmin = activeChat.myRole === 'admin';

  document.getElementById('membersCount').innerText = activeChat.members ? activeChat.members.length : 1;

  list.innerHTML = (activeChat.members || []).map(m => {
    const isMe = m.id === currentUser.id;
    const isMemberOwner = m.role === 'owner';
    const isMemberAdmin = m.role === 'admin';

    let actionBtns = '';
    if (!isMe) {
      if (isOwnerOrSuper) {
        if (isMemberAdmin) {
          actionBtns += `<button class="btn btn-xs btn-outline" onclick="changeMemberRole(${m.id}, 'member')" title="Снять права админа"><i class="fa-solid fa-shield"></i> Снять админа</button>`;
        } else if (!isMemberOwner) {
          actionBtns += `<button class="btn btn-xs btn-outline" onclick="changeMemberRole(${m.id}, 'admin')" title="Сделать админом"><i class="fa-solid fa-shield-halved text-warning"></i> Сделать админом</button>`;
        }
      }

      if (isOwnerOrSuper || (isAdmin && !isMemberAdmin && !isMemberOwner)) {
        actionBtns += `<button class="btn btn-xs btn-danger" onclick="removeMemberFromGroup(${m.id}, '${escapeHtml(m.name)}')" title="Исключить"><i class="fa-solid fa-user-minus"></i> Исключить</button>`;
      }

      if (currentUser && (currentUser.role === 'superadmin' || currentUser.role === 'admin')) {
        actionBtns += `<button class="btn btn-xs btn-outline" onclick="openAdminEditUserModalById(${m.id})" title="Редактировать"><i class="fa-solid fa-user-pen"></i></button>`;
      }

      actionBtns += `<button class="btn btn-xs btn-outline btn-report" onclick="openReportModal(${m.id}, '${escapeForJs(m.name)}', '${escapeForJs(m.username)}', '${escapeForJs(m.avatar || '')}', ${activeChat.id}, '${escapeForJs(activeChat.name)}')" title="Пожаловаться на пользователя"><i class="fa-solid fa-triangle-exclamation"></i> Жалоба</button>`;
    }

    return `
      <div class="member-row" style="display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid rgba(255,255,255,0.04);">
        <div style="display: flex; align-items: center; gap: 10px; min-width: 0;">
          ${renderAvatar(m.avatar, m.name, 'avatar-sm')}
          <div style="min-width: 0;">
            <div style="font-weight: 700; font-size: 13.5px;">
              ${escapeHtml(m.name)} 
              <span class="badge ${isMemberOwner ? 'badge-danger' : (isMemberAdmin ? 'badge-warning' : 'badge-success')}">${m.role}</span>
              ${isMe ? '<span class="text-muted" style="font-size: 11px;">(Вы)</span>' : ''}
            </div>
            <div style="font-size: 12px; color: var(--accent-color);">@${escapeHtml(m.username)}</div>
          </div>
        </div>
        <div style="display: flex; gap: 6px; flex-wrap: wrap;">
          ${actionBtns}
        </div>
      </div>
    `;
  }).join('');
}

async function saveGroupInfo() {
  if (!activeChat) return;
  const name = document.getElementById('editGroupNameInput').value.trim();
  const description = document.getElementById('editGroupDescInput').value.trim();
  if (!name) return alert('Укажите название группы');

  const btn = document.getElementById('saveGroupInfoBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Сохранение...';

  try {
    const res = await fetch(`/api/chats/${activeChat.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ name, description })
    });
    const data = await res.json();
    if (!res.ok) {
      alert(data.error || 'Ошибка сохранения');
      return;
    }

    activeChat.name = name;
    activeChat.description = description;
    document.getElementById('chatHeaderTitle').innerText = activeChat.name;
    openChatDetailsModal();
    loadChats();
    showToast('Настройки группы успешно сохранены!');
  } catch (err) {
    alert('Сетевая ошибка при сохранении');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Сохранить настройки';
  }
}

async function changeMemberRole(targetUserId, newRole) {
  if (!activeChat) return;
  try {
    const res = await fetch(`/api/chats/${activeChat.id}/admin/${targetUserId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ role: newRole })
    });
    const data = await res.json();
    if (res.ok) {
      const member = activeChat.members.find(m => m.id === targetUserId);
      if (member) member.role = newRole;
      renderChatMembersList();
    } else {
      alert(data.error || 'Ошибка изменения роли');
    }
  } catch (e) {
    alert('Сетевая ошибка');
  }
}

async function removeMemberFromGroup(targetUserId, name) {
  if (!activeChat) return;
  if (!confirm(`Исключить пользователя ${name} из группы?`)) return;

  try {
    const res = await fetch(`/api/chats/${activeChat.id}/members/${targetUserId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (res.ok) {
      activeChat.members = activeChat.members.filter(m => m.id !== targetUserId);
      renderChatMembersList();
      updateChatHeaderSubtitle();
    } else {
      alert(data.error || 'Ошибка удаления участника');
    }
  } catch (e) {
    alert('Сетевая ошибка');
  }
}

// ----------------------------------------------------
// ADD MEMBERS TO EXISTING GROUP MODAL (3 Columns Grid)
// ----------------------------------------------------

let selectedExistingGroupMemberIds = [];

async function openAddGroupMembersModal() {
  if (!activeChat) return;
  selectedExistingGroupMemberIds = [];
  document.getElementById('searchAddMembersInput').value = '';
  document.getElementById('addGroupMembersModal').classList.remove('hidden');
  await searchUsersForExistingGroup('');
}

async function searchUsersForExistingGroup(q) {
  const container = document.getElementById('existingGroupUsersSelectList');
  if (!container || !activeChat) return;
  container.innerHTML = '<div class="text-center text-muted" style="grid-column: 1 / -1; padding: 20px;"><i class="fa-solid fa-spinner fa-spin"></i> Поиск пользователей...</div>';

  const currentMemberIds = (activeChat.members || []).map(m => m.id);

  try {
    const res = await fetch(`/api/users/search?q=${encodeURIComponent(q || '')}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const { users } = await res.json();

    const availableUsers = (users || []).filter(u => !currentMemberIds.includes(u.id));

    if (availableUsers.length === 0) {
      container.innerHTML = '<div class="text-center text-muted" style="grid-column: 1 / -1; padding: 20px;">Все доступные контакты уже состоят в этой группе</div>';
      return;
    }

    container.innerHTML = availableUsers.map(u => {
      const isSelected = selectedExistingGroupMemberIds.includes(u.id);
      return `
        <div class="user-select-card ${isSelected ? 'selected' : ''}" id="chkCardUser_${u.id}" onclick="toggleSelectExistingGroupUser(${u.id})">
          <div class="user-card-avatar">
            ${renderAvatar(u.avatar, u.name, 'avatar-md')}
          </div>
          <div class="user-card-info">
            <div class="user-card-name" title="${escapeHtml(u.name)}">${escapeHtml(u.name)}</div>
            <div class="user-card-login">@${escapeHtml(u.username)}</div>
          </div>
          <div class="user-card-check">
            <i class="fa-solid fa-check" style="${isSelected ? '' : 'display:none;'}"></i>
          </div>
        </div>
      `;
    }).join('');
  } catch (e) {
    container.innerHTML = '<div class="text-center text-danger" style="grid-column: 1 / -1; padding: 16px;">Ошибка загрузки</div>';
  }
}

function toggleSelectExistingGroupUser(uid) {
  const card = document.getElementById(`chkCardUser_${uid}`);
  if (selectedExistingGroupMemberIds.includes(uid)) {
    selectedExistingGroupMemberIds = selectedExistingGroupMemberIds.filter(id => id !== uid);
    if (card) {
      card.classList.remove('selected');
      const checkIcon = card.querySelector('.user-card-check i');
      if (checkIcon) checkIcon.style.display = 'none';
    }
  } else {
    selectedExistingGroupMemberIds.push(uid);
    if (card) {
      card.classList.add('selected');
      const checkIcon = card.querySelector('.user-card-check i');
      if (checkIcon) checkIcon.style.display = 'block';
    }
  }
}

async function submitAddMembersToGroup() {
  if (!activeChat || selectedExistingGroupMemberIds.length === 0) {
    return alert('Выберите хотя бы одного пользователя для добавления');
  }

  const btn = document.getElementById('submitAddMembersBtn');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Добавление...';

  try {
    const res = await fetch(`/api/chats/${activeChat.id}/members`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ userIds: selectedExistingGroupMemberIds })
    });
    const data = await res.json();
    if (!res.ok) {
      alert(data.error || 'Ошибка добавления участников');
      return;
    }

    closeModal('addGroupMembersModal');
    const chatRes = await fetch(`/api/chats/${activeChat.id}`, { headers: { Authorization: `Bearer ${token}` } });
    const chatData = await chatRes.json();
    if (chatData.members) {
      activeChat.members = chatData.members;
      renderChatMembersList();
      updateChatHeaderSubtitle();
    }
    showToast('Участники успешно добавлены в группу!');
  } catch (err) {
    alert('Сетевая ошибка при добавлении участников');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-check"></i> Добавить выбранных в группу';
  }
}

function copyInviteLink() {
  const input = document.getElementById('inviteLinkInput');
  input.select();
  navigator.clipboard.writeText(input.value);
  showToast('Ссылка скопирована в буфер обмена!');
}

async function regenerateInviteLink() {
  if (!activeChat) return;
  try {
    const res = await fetch(`/api/chats/${activeChat.id}/invite`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (res.ok) {
      activeChat.invite_code = data.inviteCode;
      const slug = encodeURIComponent((activeChat.name || 'group').trim().replace(/[\s\/]+/g, '_'));
      document.getElementById('inviteLinkInput').value = `${window.location.origin}/#/group/${data.inviteCode}/${slug}`;
      showToast('Новая ссылка-приглашение сгенерирована!');
    }
  } catch (e) {}
}

// ----------------------------------------------------
// SETTINGS & PROFILE
// ----------------------------------------------------

function openProfileModal() {
  closeMainMenu();
  document.getElementById('profileName').value = currentUser.name;
  document.getElementById('profileUsername').value = currentUser.username;
  document.getElementById('profileBio').value = currentUser.bio || '';
  document.getElementById('profileEmail').value = currentUser.email || '';
  document.getElementById('profilePhone').value = currentUser.phone || '';
  document.getElementById('profileOldPass').value = '';
  document.getElementById('profileNewPass').value = '';
  document.getElementById('profileAlert').className = 'alert-box';

  updateAvatarElement('profileAvatarPreview', currentUser.avatar, currentUser.name, 'avatar-lg');
  document.getElementById('profileModal').classList.remove('hidden');
  checkPushStatus();
}

async function saveProfile(e) {
  e.preventDefault();
  const alertBox = document.getElementById('profileAlert');
  alertBox.className = 'alert-box';

  const name = document.getElementById('profileName').value.trim();
  const username = document.getElementById('profileUsername').value.trim();
  const email = document.getElementById('profileEmail').value.trim();
  const phone = document.getElementById('profilePhone').value.trim();
  const bio = document.getElementById('profileBio').value.trim();
  const oldPassword = document.getElementById('profileOldPass').value;
  const newPassword = document.getElementById('profileNewPass').value;

  try {
    const res = await fetch('/api/auth/profile', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ name, username, email, phone, bio, oldPassword, newPassword })
    });
    const data = await res.json();
    if (!res.ok) {
      alertBox.className = 'alert-box error show';
      alertBox.innerText = data.error || 'Ошибка обновления';
      return;
    }

    currentUser = data.user;
    alertBox.className = 'alert-box success show';
    alertBox.innerText = 'Профиль успешно сохранен!';
    initApp();
  } catch (err) {
    alertBox.className = 'alert-box error show';
    alertBox.innerText = 'Ошибка сохранения';
  }
}

// ----------------------------------------------------
// CIRCULAR AVATAR CROPPER & COMPRESSOR (Pure Black Canvas)
// ----------------------------------------------------

let cropTarget = 'profile'; // 'profile' | 'group'
let cropImageObj = new Image();
let cropScale = 1.0;
let cropBaseScale = 1.0;
let cropOffsetX = 0;
let cropOffsetY = 0;
let cropIsDragging = false;
let cropDragStartX = 0;
let cropDragStartY = 0;

function chooseAvatarFor(target) {
  cropTarget = target;
  document.getElementById('avatarCropFileInput').click();
}

function handleAvatarFileSelected(e) {
  const file = e.target.files[0];
  if (!file) return;
  e.target.value = '';

  const reader = new FileReader();
  reader.onload = function(evt) {
    cropImageObj = new Image();
    cropImageObj.onload = function() {
      openAvatarCropper();
    };
    cropImageObj.src = evt.target.result;
  };
  reader.readAsDataURL(file);
}

function openAvatarCropper() {
  document.getElementById('avatarCropperModal').classList.remove('hidden');
  
  const minDim = Math.min(cropImageObj.width, cropImageObj.height);
  cropBaseScale = 240 / minDim;
  cropScale = cropBaseScale;
  cropOffsetX = (320 - cropImageObj.width * cropScale) / 2;
  cropOffsetY = (320 - cropImageObj.height * cropScale) / 2;
  
  const slider = document.getElementById('cropZoomSlider');
  slider.min = (cropBaseScale * 0.4).toFixed(2);
  slider.max = (cropBaseScale * 3.5).toFixed(2);
  slider.value = cropScale.toFixed(2);

  initCropperEvents();
  drawCropCanvas();
}

function initCropperEvents() {
  const canvas = document.getElementById('cropCanvas');
  
  canvas.onmousedown = (e) => {
    cropIsDragging = true;
    cropDragStartX = e.clientX - cropOffsetX;
    cropDragStartY = e.clientY - cropOffsetY;
  };
  window.onmousemove = (e) => {
    if (!cropIsDragging) return;
    cropOffsetX = e.clientX - cropDragStartX;
    cropOffsetY = e.clientY - cropDragStartY;
    drawCropCanvas();
  };
  window.onmouseup = () => { cropIsDragging = false; };

  canvas.ontouchstart = (e) => {
    if (e.touches.length === 1) {
      cropIsDragging = true;
      cropDragStartX = e.touches[0].clientX - cropOffsetX;
      cropDragStartY = e.touches[0].clientY - cropOffsetY;
    }
  };
  canvas.ontouchmove = (e) => {
    if (!cropIsDragging || e.touches.length !== 1) return;
    e.preventDefault();
    cropOffsetX = e.touches[0].clientX - cropDragStartX;
    cropOffsetY = e.touches[0].clientY - cropDragStartY;
    drawCropCanvas();
  };
  canvas.ontouchend = () => { cropIsDragging = false; };
}

function onCropZoomChange(val) {
  const newScale = parseFloat(val);
  const centerX = 160;
  const centerY = 160;
  
  cropOffsetX = centerX - (centerX - cropOffsetX) * (newScale / cropScale);
  cropOffsetY = centerY - (centerY - cropOffsetY) * (newScale / cropScale);
  cropScale = newScale;
  drawCropCanvas();
}

function drawCropCanvas() {
  const canvas = document.getElementById('cropCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#000000';
  ctx.fillRect(0, 0, 320, 320);

  ctx.save();
  ctx.drawImage(cropImageObj, cropOffsetX, cropOffsetY, cropImageObj.width * cropScale, cropImageObj.height * cropScale);
  ctx.restore();

  drawCropPreview();
}

function drawCropPreview() {
  const previewCanvas = document.getElementById('cropPreviewCanvas');
  if (!previewCanvas) return;
  const pCtx = previewCanvas.getContext('2d');
  pCtx.fillStyle = '#000000';
  pCtx.fillRect(0, 0, 64, 64);

  const cropX = 40;
  const cropY = 40;
  const cropSize = 240;

  pCtx.save();
  pCtx.beginPath();
  pCtx.arc(32, 32, 32, 0, Math.PI * 2);
  pCtx.clip();

  const mainCanvas = document.getElementById('cropCanvas');
  pCtx.drawImage(mainCanvas, cropX, cropY, cropSize, cropSize, 0, 0, 64, 64);
  pCtx.restore();
}

async function saveCroppedAvatar() {
  const saveBtn = document.getElementById('cropSaveBtn');
  saveBtn.disabled = true;
  saveBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Сжатие и загрузка...';

  const outCanvas = document.createElement('canvas');
  outCanvas.width = 128;
  outCanvas.height = 128;
  const outCtx = outCanvas.getContext('2d');
  outCtx.fillStyle = '#000000';
  outCtx.fillRect(0, 0, 128, 128);

  const cropX = 40;
  const cropY = 40;
  const cropSize = 240;

  outCtx.save();
  outCtx.drawImage(
    cropImageObj,
    (cropX - cropOffsetX) / cropScale,
    (cropY - cropOffsetY) / cropScale,
    cropSize / cropScale,
    cropSize / cropScale,
    0,
    0,
    128,
    128
  );
  outCtx.restore();

  outCanvas.toBlob(async (blob) => {
    if (!blob) {
      alert('Ошибка формирования аватара');
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<i class="fa-solid fa-check"></i> Сохранить и применить';
      return;
    }

    const formData = new FormData();
    formData.append('avatar', blob, 'avatar.webp');

    try {
      const res = await fetch('/api/upload/avatar', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: formData
      });
      const data = await res.json();

      if (!res.ok || !data.url) {
        alert(data.error || 'Ошибка загрузки аватара на сервер');
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<i class="fa-solid fa-check"></i> Сохранить и применить';
        return;
      }

      const avatarUrl = data.url;

      if (cropTarget === 'profile') {
        const updateRes = await fetch('/api/auth/profile', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
          body: JSON.stringify({ avatar: avatarUrl })
        });
        const updateData = await updateRes.json();
        if (updateData.user) {
          currentUser = updateData.user;
          updateAvatarElement('menuUserAvatar', currentUser.avatar, currentUser.name, 'avatar-md');
          updateAvatarElement('profileAvatarPreview', currentUser.avatar, currentUser.name, 'avatar-lg');
          loadChats();
        }
      } else if (cropTarget === 'group' && activeChat) {
        await fetch(`/api/chats/${activeChat.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
          body: JSON.stringify({ avatar: avatarUrl })
        });
        activeChat.avatar = avatarUrl;
        updateAvatarElement('detailsAvatar', activeChat.avatar, activeChat.name, 'avatar-lg');
        updateAvatarElement('chatHeaderAvatar', activeChat.avatar, activeChat.name, 'avatar-md');
        loadChats();
      } else if (cropTarget === 'adminUser') {
        currentAdminEditingAvatar = avatarUrl;
        updateAvatarElement('adminEditUserAvatarPreview', avatarUrl, 'User', 'avatar-md');
      }

      closeAvatarCropper();
      showToast('Аватар успешно обновлен!');
    } catch (err) {
      alert('Сетевая ошибка при сохранении аватара');
    } finally {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<i class="fa-solid fa-check"></i> Сохранить и применить';
    }
  }, 'image/webp', 0.85);
}

function closeAvatarCropper() {
  document.getElementById('avatarCropperModal').classList.add('hidden');
}

// ----------------------------------------------------
// UTILITIES & HELPERS
// ----------------------------------------------------

function toggleMainMenu() {
  const m = document.getElementById('mainMenu');
  if (m) {
    m.classList.toggle('hidden');
    if (!m.classList.contains('hidden')) {
      checkPushStatus();
    }
  }
}

function closeMainMenu() {
  const m = document.getElementById('mainMenu');
  if (m) m.classList.add('hidden');
}

function openModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.remove('hidden');
}

function closeModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.add('hidden');
}

// ----------------------------------------------------
// ADMIN MERGE USERS (Владимир)
// ----------------------------------------------------

function openAdminMergeModal(sourceUserId = null) {
  const modal = document.getElementById('adminMergeModal');
  const targetSelect = document.getElementById('mergeTargetUserSelect');
  const sourceSelect = document.getElementById('mergeSourceUserSelect');
  const alertBox = document.getElementById('mergeAlert');
  const confirmBox = document.getElementById('mergeConfirmCheckbox');
  
  if (alertBox) alertBox.className = 'alert-box';
  if (confirmBox) confirmBox.checked = false;

  const isLight = document.body.classList.contains('light-theme');
  const optBg = isLight ? '#ffffff' : '#17212b';
  const optColor = isLight ? '#0f172a' : '#f5f5f5';
  const usersList = adminAllUsersCache && adminAllUsersCache.length > 0 ? adminAllUsersCache : [];
  const optionsHtml = usersList.map(u => 
    `<option value="${u.id}" style="background-color: ${optBg} !important; color: ${optColor} !important;">${escapeHtml(u.name)} (@${escapeHtml(u.username)}) [ID: ${u.id}, ${u.role}]</option>`
  ).join('');

  if (targetSelect) {
    targetSelect.innerHTML = `<option value="" style="background-color: ${optBg} !important; color: ${optColor} !important;">-- Выберите основной аккаунт (куда переносим) --</option>` + optionsHtml;
  }
  if (sourceSelect) {
    sourceSelect.innerHTML = `<option value="" style="background-color: ${optBg} !important; color: ${optColor} !important;">-- Выберите дубликат для слияния (который удалится) --</option>` + optionsHtml;
    if (sourceUserId) {
      sourceSelect.value = sourceUserId;
    }
  }

  if (modal) modal.classList.remove('hidden');
}

async function handleAdminMergeUsers(e) {
  e.preventDefault();
  const alertBox = document.getElementById('mergeAlert');
  const submitBtn = document.getElementById('mergeSubmitBtn');
  const targetUserId = document.getElementById('mergeTargetUserSelect').value;
  const sourceUserId = document.getElementById('mergeSourceUserSelect').value;

  if (!targetUserId || !sourceUserId) {
    alertBox.className = 'alert-box error show';
    alertBox.innerText = 'Пожалуйста, выберите оба аккаунта для слияния.';
    return;
  }

  if (targetUserId === sourceUserId) {
    alertBox.className = 'alert-box error show';
    alertBox.innerText = 'Нельзя объединить аккаунт сам с собой.';
    return;
  }

  const targetUser = adminAllUsersCache.find(u => u.id == targetUserId);
  const sourceUser = adminAllUsersCache.find(u => u.id == sourceUserId);

  const confirmText = `Вы действительно хотите объединить дубликат "${sourceUser ? sourceUser.name : ('ID ' + sourceUserId)}" в основной аккаунт "${targetUser ? targetUser.name : ('ID ' + targetUserId)}"?\n\nВсе сообщения, чаты и группы будут перенесены. Аккаунт-дубликат будет закрыт. Это действие необратимо!`;
  if (!confirm(confirmText)) {
    return;
  }

  submitBtn.disabled = true;
  submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Объединение аккаунтов...';

  try {
    const res = await fetch('/api/admin/users/merge', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      body: JSON.stringify({ sourceUserId, targetUserId })
    });

    const data = await res.json();
    if (res.ok) {
      alertBox.className = 'alert-box success show';
      alertBox.innerText = data.message || 'Аккаунты успешно объединены!';
      showToast('🔗 Аккаунты успешно объединены!');
      setTimeout(() => {
        closeModal('adminMergeModal');
        loadAdminData();
        loadChats();
      }, 1500);
    } else {
      alertBox.className = 'alert-box error show';
      alertBox.innerText = data.error || 'Ошибка объединения аккаунтов';
    }
  } catch (err) {
    alertBox.className = 'alert-box error show';
    alertBox.innerText = 'Сетевая ошибка при объединении';
  } finally {
    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="fa-solid fa-code-merge"></i> Объединить аккаунты';
  }
}

// ----------------------------------------------------
// WALLPAPER & BACKGROUND SWITCHER (Telegram-style)
// ----------------------------------------------------
const wallpapers = [
  { id: 'aurora', name: 'Нежная Аврора', light: 'linear-gradient(45deg, #dbeafe 0%, #e0e7ff 35%, #f3e8ff 70%, #fae8ff 100%)', dark: 'linear-gradient(135deg, #180a2b 0%, #1e113a 40%, #0e1420 100%)' },
  { id: 'neon', name: 'Космос & Неон', light: 'linear-gradient(45deg, #e0f2fe 0%, #e879f9 50%, #c084fc 100%)', dark: 'linear-gradient(135deg, #0b0f19 0%, #2e1065 50%, #030712 100%)' },
  { id: 'ocean', name: 'Морской Бриз', light: 'linear-gradient(45deg, #ccfbf1 0%, #bae6fd 50%, #e0f2fe 100%)', dark: 'linear-gradient(135deg, #042f2e 0%, #0c4a6e 50%, #02131d 100%)' },
  { id: 'mint', name: 'Изумрудный Сад', light: 'linear-gradient(45deg, #dcfce7 0%, #d1fae5 50%, #f0fdf4 100%)', dark: 'linear-gradient(135deg, #052e16 0%, #064e3b 50%, #02160d 100%)' },
  { id: 'sunset', name: 'Закат & Персик', light: 'linear-gradient(45deg, #ffedd5 0%, #fed7aa 50%, #ffe4e6 100%)', dark: 'linear-gradient(135deg, #431407 0%, #701a75 50%, #1c0a1a 100%)' },
  { id: 'stealth', name: 'Скрытный Графит', light: 'linear-gradient(45deg, #f1f5f9 0%, #e2e8f0 50%, #cbd5e1 100%)', dark: 'linear-gradient(135deg, #111215 0%, #1e1b2e 50%, #090a0d 100%)' },
  { id: 'sakura', name: 'Сакура Bloom', light: 'linear-gradient(45deg, #fce7f3 0%, #fbcfe8 50%, #f5d0fe 100%)', dark: 'linear-gradient(135deg, #500724 0%, #701a75 50%, #1f0410 100%)' },
  { id: 'mocha', name: 'Уютный Мокко', light: 'linear-gradient(45deg, #fef3c7 0%, #fed7aa 50%, #fae8ff 100%)', dark: 'linear-gradient(135deg, #271a0c 0%, #3e1f2f 50%, #120b08 100%)' },
  { id: 'lavender', name: 'Лаванда & Сумерки', light: 'linear-gradient(45deg, #ede9fe 0%, #ddd6fe 50%, #f5f3ff 100%)', dark: 'linear-gradient(135deg, #2e1065 0%, #1e1b4b 50%, #090614 100%)' },
  { id: 'cyberpunk', name: 'Киберпанк 2077', light: 'linear-gradient(45deg, #fef08a 0%, #fed7aa 50%, #fbcfe8 100%)', dark: 'linear-gradient(135deg, #450a0a 0%, #581c87 50%, #020617 100%)' },
  { id: 'deepspace', name: 'Глубокий Космос', light: 'linear-gradient(45deg, #e2e8f0 0%, #cbd5e1 50%, #94a3b8 100%)', dark: 'linear-gradient(135deg, #020617 0%, #0f172a 50%, #020617 100%)' },
  { id: 'solid_classic', name: 'Классический Монохром', light: '#f8fafc', dark: '#0e1621' }
];

function applyWallpaper(wpId) {
  const currentWpId = wpId || localStorage.getItem('gin_chat_wallpaper') || 'aurora';
  const wp = wallpapers.find(w => w.id === currentWpId) || wallpapers[0];
  const isLight = document.body.classList.contains('light-theme');
  const bg = isLight ? wp.light : wp.dark;
  
  // Set CSS variable on root and body
  document.documentElement.style.setProperty('--chat-wallpaper-bg', bg);
  document.body.style.setProperty('--chat-wallpaper-bg', bg);
  
  const activeChatEl = document.getElementById('activeChatContainer');
  const messagesContainerEl = document.getElementById('messagesContainer');
  const emptyStateEl = document.getElementById('emptyChatState');
  const chatViewEl = document.getElementById('chatView');

  if (activeChatEl) activeChatEl.style.setProperty('background', bg, 'important');
  if (messagesContainerEl) messagesContainerEl.style.setProperty('background', bg, 'important');
  if (emptyStateEl) emptyStateEl.style.setProperty('background', bg, 'important');
  if (chatViewEl) chatViewEl.style.setProperty('background', bg, 'important');
  
  localStorage.setItem('gin_chat_wallpaper', wp.id);
}

function renderWallpaperGrid() {
  const currentWp = localStorage.getItem('gin_chat_wallpaper') || 'aurora';
  const isLight = document.body.classList.contains('light-theme');
  const grid = document.getElementById('wallpaperGrid');
  if (!grid) return;
  
  grid.innerHTML = wallpapers.map(wp => `
    <div class="wallpaper-card ${wp.id === currentWp ? 'active' : ''}" onclick="selectWallpaper('${wp.id}')" style="background: ${isLight ? wp.light : wp.dark};">
      <div class="wallpaper-card-inner">
        <div class="wallpaper-mock-msg out">Привет! 👋</div>
        <div class="wallpaper-mock-msg in">Отличный фон! ✨</div>
      </div>
      <div class="wallpaper-card-name">${wp.name}</div>
      ${wp.id === currentWp ? '<div class="wallpaper-check"><i class="fa-solid fa-check"></i></div>' : ''}
    </div>
  `).join('');
}

function selectWallpaper(wpId) {
  applyWallpaper(wpId);
  renderWallpaperGrid();
  showToast('Фон чатов успешно установлен!');
  closeModal('wallpaperModal');
}

function openWallpaperModal() {
  closeMainMenu();
  const modal = document.getElementById('wallpaperModal');
  if (modal) {
    renderWallpaperGrid();
    modal.classList.remove('hidden');
    modal.style.display = 'flex';
  }
}

function openWallpaperModalFromProfile() {
  closeModal('profileModal');
  setTimeout(() => {
    openWallpaperModal();
  }, 50);
}

function initTheme() {
  const savedTheme = localStorage.getItem('gin_chat_theme') || 'dark';
  if (savedTheme === 'light') {
    document.body.classList.add('light-theme');
    document.body.classList.remove('dark-theme');
    const icon = document.getElementById('themeIcon');
    if (icon) icon.className = 'fa-solid fa-sun';
  } else {
    document.body.classList.remove('light-theme');
    document.body.classList.add('dark-theme');
    const icon = document.getElementById('themeIcon');
    if (icon) icon.className = 'fa-solid fa-moon';
  }
  applyWallpaper(localStorage.getItem('gin_chat_wallpaper') || 'aurora');
}

function toggleTheme() {
  document.body.classList.toggle('light-theme');
  const isLight = document.body.classList.contains('light-theme');
  if (isLight) {
    document.body.classList.remove('dark-theme');
    localStorage.setItem('gin_chat_theme', 'light');
  } else {
    document.body.classList.add('dark-theme');
    localStorage.setItem('gin_chat_theme', 'dark');
  }
  const icon = document.getElementById('themeIcon');
  if (icon) icon.className = isLight ? 'fa-solid fa-sun' : 'fa-solid fa-moon';
  applyWallpaper(localStorage.getItem('gin_chat_wallpaper') || 'aurora');
}

function openAboutModal() {
  closeMainMenu();
  openModal('aboutAppModal');
}

function openLightbox(url) {
  document.getElementById('lightboxImg').src = url;
  document.getElementById('lightbox').classList.remove('hidden');
}

function closeLightbox() {
  document.getElementById('lightbox').classList.add('hidden');
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function escapeForJs(str) {
  if (!str) return '';
  return String(str).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\r/g, '');
}

// ----------------------------------------------------
// TOAST NOTIFICATIONS & CHAT LINK SHARING
// ----------------------------------------------------

function showToast(msg) {
  const toast = document.getElementById('toastNotification');
  if (!toast) return;
  toast.innerHTML = `<i class="fa-solid fa-circle-check"></i> ${msg}`;
  toast.classList.remove('hidden');
  setTimeout(() => {
    toast.classList.add('hidden');
  }, 2500);
}

function copyCurrentChatLink() {
  if (!activeChat) return;
  let link = '';
  let toastMsg = '';

  if (activeChat.type === 'group') {
    const slug = encodeURIComponent((activeChat.name || 'group').trim().replace(/[\s\/]+/g, '_'));
    const code = activeChat.invite_code || activeChat.id;
    link = `${window.location.origin}/#/group/${code}/${slug}`;
    toastMsg = 'Ссылка-приглашение в группу скопирована!';
  } else {
    link = `${window.location.origin}/#/c/${activeChat.id}`;
    toastMsg = 'Ссылка на диалог скопирована!';
  }

  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(link).then(() => {
      showToast(toastMsg);
    }).catch(() => {
      prompt('Скопируйте ссылку:', link);
    });
  } else {
    prompt('Скопируйте ссылку:', link);
  }
}

async function handleUrlRouting() {
  const hash = window.location.hash || sessionStorage.getItem('pending_chat_hash') || '';
  if (!hash) return;

  if (!token) {
    sessionStorage.setItem('pending_chat_hash', hash);
    return;
  }

  // Handle #/group/:code_or_id/:slug or #/group/:code_or_id
  const groupMatch = hash.match(/#\/group\/([a-zA-Z0-9_-]+)/);
  if (groupMatch) {
    const groupParam = groupMatch[1];
    sessionStorage.removeItem('pending_chat_hash');

    if (/^\d+$/.test(groupParam)) {
      const targetChatId = Number(groupParam);
      const existingChat = allChats.find(c => c.id === targetChatId);
      if (existingChat) {
        selectChat(targetChatId);
      } else {
        try {
          const joinRes = await fetch(`/api/chats/${targetChatId}/join`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${token}` }
          });
          if (joinRes.ok) {
            await loadChats();
            selectChat(targetChatId);
            showToast('Вы присоединились к группе!');
          } else {
            selectChat(targetChatId);
          }
        } catch (e) {
          selectChat(targetChatId);
        }
      }
      return;
    } else {
      try {
        const joinRes = await fetch(`/api/chats/join/${groupParam}`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` }
        });
        const data = await joinRes.json();
        if (joinRes.ok) {
          await loadChats();
          selectChat(data.chatId);
          showToast(`Вы присоединились к группе «${data.name}»!`);
        } else {
          alert(data.error || 'Недействительная ссылка-приглашение');
        }
      } catch (e) {}
      return;
    }
  }

  // Handle #/c/:id
  const chatMatch = hash.match(/#\/c\/(\d+)/);
  if (chatMatch) {
    const targetChatId = Number(chatMatch[1]);
    sessionStorage.removeItem('pending_chat_hash');

    const existingChat = allChats.find(c => c.id === targetChatId);
    if (existingChat) {
      selectChat(targetChatId);
    } else {
      try {
        const joinRes = await fetch(`/api/chats/${targetChatId}/join`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` }
        });
        if (joinRes.ok) {
          await loadChats();
          selectChat(targetChatId);
          showToast('Вы присоединились к диалогу!');
        } else {
          await loadChats();
          selectChat(targetChatId);
        }
      } catch (e) {
        selectChat(targetChatId);
      }
    }
    return;
  }
}

window.addEventListener('hashchange', () => {
  handleUrlRouting();
});

// Android & Mobile Back Button Navigation Handler (popstate)
window.addEventListener('popstate', (event) => {
  // 1. If any modal dialog is currently open, close it first
  const openModals = document.querySelectorAll('.modal-overlay:not(.hidden)');
  if (openModals.length > 0) {
    openModals.forEach(m => {
      if (m.id) closeModal(m.id);
    });
    return;
  }

  // 2. If fullscreen media lightbox is open, close lightbox
  const lightbox = document.getElementById('lightboxOverlay');
  if (lightbox && !lightbox.classList.contains('hidden')) {
    closeLightbox();
    return;
  }

  // 3. If emoji picker or GIF picker is open, close it
  const emojiPicker = document.getElementById('emojiPicker');
  if (emojiPicker && !emojiPicker.classList.contains('hidden')) {
    emojiPicker.classList.add('hidden');
    return;
  }
  const gifPicker = document.getElementById('gifPicker');
  if (gifPicker && !gifPicker.classList.contains('hidden')) {
    closeGifPicker();
    return;
  }

  // 4. If mobile chat view is open, return back to the contacts / chats list
  if (document.body.classList.contains('mobile-chat-open')) {
    backToChatsList(false);
    return;
  }

  // 5. If state contains specific navigation or hash changed
  if (window.location.hash && window.location.hash !== '#/' && window.location.hash !== '') {
    handleUrlRouting();
  }
});

// ----------------------------------------------------
// TELEGRAM-STYLE /gif & ANIMATED STICKERS ENGINE
// ----------------------------------------------------
const GIF_COLLECTION = [
  // Money / Crypto / Rich
  { url: 'https://media.giphy.com/media/67ThRZlYBvibtdF9JH/giphy.gif', tags: ['money', 'деньги', 'dollar', 'rich', 'cash', 'crypto', 'gold', 'trending'] },
  { url: 'https://media.giphy.com/media/3o6gDWzmAzrpi5DQU8/giphy.gif', tags: ['money', 'деньги', 'rain', 'dollar', 'rich', 'trending'] },
  { url: 'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif', tags: ['money', 'деньги', 'wolf', 'wallstreet', 'dollar', 'rich'] },
  { url: 'https://media.giphy.com/media/xT5LMPj8P20jjOqZ5C/giphy.gif', tags: ['money', 'деньги', 'count', 'cash', 'dollars'] },
  { url: 'https://media.giphy.com/media/jsl82uOLnCdAXBqBulk/giphy.gif', tags: ['money', 'crypto', 'bitcoin', 'btc', 'moon', 'rocket', 'деньги'] },
  { url: 'https://media.giphy.com/media/sDcfxFDozb3bO/giphy.gif', tags: ['money', 'take', 'buy', 'деньги', 'купи', 'shut up'] },
  { url: 'https://media.giphy.com/media/13yNFN1TlNCjC0/giphy.gif', tags: ['money', 'stacks', 'cash', 'деньги', 'богатство'] },

  // Ninja / Stealth / Secret
  { url: 'https://media.giphy.com/media/l0MYDGA3Du1hBR4xG/giphy.gif', tags: ['ninja', 'ниндзя', 'stealth', 'secret', 'smoke', 'vanish'] },
  { url: 'https://media.giphy.com/media/3o7TKSjRrfIPjeiVyM/giphy.gif', tags: ['ninja', 'ниндзя', 'jump', 'shadow', 'katana', 'secret'] },
  { url: 'https://media.giphy.com/media/26AHG5KGFxSkUWw1i/giphy.gif', tags: ['ninja', 'ниндзя', 'sword', 'strike', 'warrior'] },
  { url: 'https://media.giphy.com/media/SEp6ZNTv426L6/giphy.gif', tags: ['ninja', 'secret', '007', 'agent', 'секрет', 'шпион'] },
  { url: 'https://media.giphy.com/media/eIm624c8nnNbiG0V3g/giphy.gif', tags: ['ninja', 'hacker', 'matrix', 'code', 'хакер', 'matrix'] },

  // Win / Celebration / Party
  { url: 'https://media.giphy.com/media/BPJmthQ3YRwD6QqcVD/giphy.gif', tags: ['win', 'победа', 'gatsby', 'cheers', 'toast', 'celebrate', 'ура', 'trending'] },
  { url: 'https://media.giphy.com/media/artj92V8o75VPL7AeQ/giphy.gif', tags: ['win', 'party', 'minions', 'celebrate', 'победа', 'праздник'] },
  { url: 'https://media.giphy.com/media/26u4cqiYI30juCOGY/giphy.gif', tags: ['win', 'confetti', 'dance', 'победа', 'party'] },
  { url: 'https://media.giphy.com/media/nXxOjZrbnbRxS/giphy.gif', tags: ['win', 'success', 'kid', 'yes', 'победа', 'ура'] },
  { url: 'https://media.giphy.com/media/peAFQfg7Ol6IE/giphy.gif', tags: ['win', 'fireworks', 'салют', 'праздник', 'celebrate'] },
  { url: 'https://media.giphy.com/media/hryis7A55UXZNCUTNA/giphy.gif', tags: ['win', 'ronaldo', 'siuu', 'победа', 'goal'] },

  // Cats / Animals
  { url: 'https://media.giphy.com/media/BzyTuYCmvSORqs1ABM/giphy.gif', tags: ['cats', 'котики', 'cat', 'vibing', 'nod', 'кот', 'trending'] },
  { url: 'https://media.giphy.com/media/mlvseq9yvZhba/giphy.gif', tags: ['cats', 'котики', 'cat', 'typing', 'fast', 'кот'] },
  { url: 'https://media.giphy.com/media/JIX9t2j0ZTN9S/giphy.gif', tags: ['cats', 'котики', 'cat', 'work', 'кот', 'комп'] },
  { url: 'https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif', tags: ['cats', 'котики', 'kitten', 'cute', 'мило'] },
  { url: 'https://media.giphy.com/media/oF5oUYTOhvFnO/giphy.gif', tags: ['cats', 'котики', 'popcat', 'meme'] },

  // Fire / Rocket / Hype
  { url: 'https://media.giphy.com/media/26AHONQ79FdWZhAI0/giphy.gif', tags: ['fire', 'огонь', 'flame', 'hype', 'жара', 'trending'] },
  { url: 'https://media.giphy.com/media/l46CqLVMWzaJUFPLW/giphy.gif', tags: ['fire', 'огонь', 'hot', 'burn'] },
  { url: 'https://media.giphy.com/media/mi6DsSSNKDbUY/giphy.gif', tags: ['rocket', 'space', 'ракета', 'moon', 'fly', 'взлет'] },
  { url: 'https://media.giphy.com/media/9M5jK4GXmD5o1irGrF/giphy.gif', tags: ['fire', 'fine', 'dog', 'мем', 'огонь'] },
  { url: 'https://media.giphy.com/media/26ufdipQqU2lhNA4g/giphy.gif', tags: ['mindblown', 'fire', 'explosion', 'шок', 'взрыв'] },

  // Cool / Swagger / Memes
  { url: 'https://media.giphy.com/media/1jnyRP4DorCh2/giphy.gif', tags: ['cool', 'круто', 'deal with it', 'glasses', 'очки'] },
  { url: 'https://media.giphy.com/media/DHqth0hVQoIzS/giphy.gif', tags: ['cool', 'snoop', 'dance', 'круто', 'танцы'] },
  { url: 'https://media.giphy.com/media/wEgs1VRJsAqg8/giphy.gif', tags: ['cool', 'ironman', 'superhero', 'круто'] },
  { url: 'https://media.giphy.com/media/7TtvTUMm9mp20/giphy.gif', tags: ['cool', 'terminator', 'thumbsup', 'класс'] },

  // Love / Hearts
  { url: 'https://media.giphy.com/media/26FLdmIp6wJr91JAI/giphy.gif', tags: ['love', 'любовь', 'heart', 'сердце', 'влюблен'] },
  { url: 'https://media.giphy.com/media/l8ooT55UMbTBIxgYWu/giphy.gif', tags: ['love', 'hug', 'обнимашки', 'любовь', 'мило'] },
  { url: 'https://media.giphy.com/media/M90mJvfWfd5mbUuULX/giphy.gif', tags: ['love', 'kiss', 'поцелуй', 'любовь'] },
  { url: 'https://media.giphy.com/media/L4lvBzeGQwpwc/giphy.gif', tags: ['love', 'heart', 'pulse', 'сердечко'] },

  // Laugh / Funny
  { url: 'https://media.giphy.com/media/10JhviFuU2gWD6/giphy.gif', tags: ['laugh', 'смех', 'lol', 'haha', 'ржу', 'funny'] },
  { url: 'https://media.giphy.com/media/bC9czlgCMtw4cj8RgH/giphy.gif', tags: ['laugh', 'cat', 'haha', 'смех', 'кот'] },
  { url: 'https://media.giphy.com/media/7J4Lvpz55rocO07QvI/giphy.gif', tags: ['laugh', 'stevecarell', 'смех', 'хаха'] },
  { url: 'https://media.giphy.com/media/A7ZbCuv0fJ0POGucw4/giphy.gif', tags: ['laugh', 'joker', 'джокер', 'смех'] },

  // Coffee / Relax
  { url: 'https://media.giphy.com/media/oZEBLugoTgavS/giphy.gif', tags: ['coffee', 'кофе', 'morning', 'утро', 'чай'] },
  { url: 'https://media.giphy.com/media/3o85xGocUH8RYoDKKs/giphy.gif', tags: ['coffee', 'relax', 'чай', 'отдых'] },
  { url: 'https://media.giphy.com/media/l2Je4rm0DCduJ6QJG/giphy.gif', tags: ['coffee', 'homer', 'simpsons', 'кофе'] },

  // Agree / Yes / Clapping
  { url: 'https://media.giphy.com/media/gVoBC0SuaHStq/giphy.gif', tags: ['yes', 'да', 'nod', 'agree', 'согласен'] },
  { url: 'https://media.giphy.com/media/111ebonMs90YLu/giphy.gif', tags: ['yes', 'thumbsup', 'лайк', 'класс', 'супер'] },
  { url: 'https://media.giphy.com/media/g9582DNuQppxC/giphy.gif', tags: ['clap', 'applause', 'браво', 'аплодисменты'] }
];

let currentGifCategory = 'trending';
let gifSearchQuery = '';

function toggleGifPicker() {
  const picker = document.getElementById('gifPicker');
  if (!picker) return;
  const isHidden = picker.classList.contains('hidden');
  if (isHidden) {
    openGifPicker();
  } else {
    closeGifPicker();
  }
}

function openGifPicker(query = '') {
  const picker = document.getElementById('gifPicker');
  const emojiPicker = document.getElementById('emojiPicker');
  if (emojiPicker) emojiPicker.classList.add('hidden');
  if (!picker) return;

  picker.classList.remove('hidden');
  const btn = document.getElementById('gifBtn');
  if (btn) btn.classList.add('active');

  const searchInput = document.getElementById('gifSearchInput');
  if (searchInput) {
    searchInput.value = query;
    gifSearchQuery = query;
    const clearBtn = document.getElementById('gifClearBtn');
    if (clearBtn) clearBtn.classList.toggle('hidden', !query);
    if (!query) searchInput.focus();
  }

  renderGifGrid(query || currentGifCategory);
}

function closeGifPicker() {
  const picker = document.getElementById('gifPicker');
  if (picker) picker.classList.add('hidden');
  const btn = document.getElementById('gifBtn');
  if (btn) btn.classList.remove('active');
}

function selectGifCategory(cat, btn) {
  currentGifCategory = cat;
  gifSearchQuery = '';
  const searchInput = document.getElementById('gifSearchInput');
  if (searchInput) searchInput.value = '';
  const clearBtn = document.getElementById('gifClearBtn');
  if (clearBtn) clearBtn.classList.add('hidden');

  if (btn) {
    document.querySelectorAll('.gif-chip').forEach(el => el.classList.remove('active'));
    btn.classList.add('active');
  }

  renderGifGrid(cat);
}

function handleGifSearchInput(e) {
  const query = e.target.value.trim().toLowerCase();
  gifSearchQuery = query;
  const clearBtn = document.getElementById('gifClearBtn');
  if (clearBtn) clearBtn.classList.toggle('hidden', !query);
  renderGifGrid(query || currentGifCategory);
}

function clearGifSearch() {
  const searchInput = document.getElementById('gifSearchInput');
  if (searchInput) {
    searchInput.value = '';
    searchInput.focus();
  }
  const clearBtn = document.getElementById('gifClearBtn');
  if (clearBtn) clearBtn.classList.add('hidden');
  gifSearchQuery = '';
  renderGifGrid(currentGifCategory);
}

function renderGifGrid(filter = '') {
  const grid = document.getElementById('gifGrid');
  if (!grid) return;

  const f = filter.toLowerCase().trim();
  let results = [];

  if (!f || f === 'trending') {
    results = GIF_COLLECTION;
  } else {
    results = GIF_COLLECTION.filter(item => 
      item.tags.some(tag => tag.toLowerCase().includes(f)) ||
      f.split(/[\s/]+/).some(w => w && item.tags.some(tag => tag.toLowerCase().includes(w)))
    );
  }

  if (results.length === 0) {
    grid.innerHTML = `
      <div class="gif-empty-notice">
        <i class="fa-solid fa-film" style="font-size: 28px; margin-bottom: 8px; opacity: 0.6; display: block;"></i>
        Ничего не найдено по запросу "<b>${escapeHtml(filter)}</b>".<br>
        Попробуйте: <i>money, котики, win, ninja, fire, rock, love</i>
      </div>
    `;
    return;
  }

  grid.innerHTML = results.map(item => `
    <div class="gif-grid-item" onclick="sendGif('${item.url}')" title="Отправить GIF в чат">
      <img src="${item.url}" alt="GIF" loading="lazy">
    </div>
  `).join('');
}

function sendGif(gifUrl) {
  if (!activeChat || !socket) return;

  // Clear input of /gif commands
  const input = document.getElementById('messageInput');
  if (input) {
    if (input.value.startsWith('/gif') || input.value.startsWith('@gif')) {
      input.value = '';
      input.style.height = 'auto';
    }
  }

  socket.emit('send_message', {
    chatId: activeChat.id,
    type: 'gif',
    fileUrl: gifUrl,
    replyToId: replyMessage ? replyMessage.id : null
  }, (res) => {
    if (res && res.error) {
      showToast(res.error, 'error');
    }
  });

  cancelReply();
  closeGifPicker();
}

// Global click to close GIF picker
document.addEventListener('click', (e) => {
  const picker = document.getElementById('gifPicker');
  if (picker && !picker.classList.contains('hidden')) {
    if (!picker.contains(e.target) && !e.target.closest('#gifBtn')) {
      closeGifPicker();
    }
  }
});

// ====================================================
// WEBRTC P2P 1-ON-1 AUDIO/VIDEO CALLS & LOUNGE MUSIC (v025)
// ====================================================
let localStream = null;
let remoteStream = null;
let peerConnection = null;
let currentCallPeerId = null;
let currentCallType = 'audio'; // 'audio' | 'video'
let isCallInitiator = false;
let callDurationTimer = null;
let callSecondsElapsed = 0;
let isFrontCamera = true;
let pendingIncomingCallData = null;
let pendingIceCandidates = [];

// High-Reliability STUN & TURN Relay Configuration
const iceServersConfig = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
    { urls: 'stun:stun2.l.google.com:19302' },
    { urls: 'stun:stun3.l.google.com:19302' },
    { urls: 'stun:stun4.l.google.com:19302' },
    { urls: 'stun:stun.cloudflare.com:3478' },
    { urls: 'stun:global.stun.twilio.com:3478' },
    {
      urls: [
        'turn:openrelay.metered.ca:80',
        'turn:openrelay.metered.ca:443',
        'turn:openrelay.metered.ca:443?transport=tcp'
      ],
      username: 'openrelayproject',
      credential: 'openrelayproject'
    }
  ],
  iceCandidatePoolSize: 10
};

// ====================================================
// ELEVATOR LOUNGE WAITING MUSIC SYNTHESIZER (Web Audio API)
// ====================================================
let callMusicTimer = null;
let callMusicCtx = null;

function playElevatorMusic() {
  stopCallTone();
  try {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    callMusicCtx = new AudioCtx();

    // Master Gain & Warm Vintage Lowpass Filter
    const masterGain = callMusicCtx.createGain();
    masterGain.gain.setValueAtTime(0.07, callMusicCtx.currentTime);

    const filter = callMusicCtx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(1500, callMusicCtx.currentTime);
    filter.Q.setValueAtTime(1.2, callMusicCtx.currentTime);

    masterGain.connect(filter);
    filter.connect(callMusicCtx.destination);

    // Warm Elevator Lounge Chord Progression: Fmaj7 -> Em7 -> Dm7 -> Cmaj7
    const notes = {
      C3: 130.81, D3: 146.83, E3: 164.81, F3: 174.61, G3: 196.00, A3: 220.00, B3: 246.94,
      C4: 261.63, D4: 293.66, E4: 329.63, F4: 349.23, G4: 392.00, A4: 440.00, B4: 493.88,
      C5: 523.25, D5: 587.33, E5: 659.25, G5: 783.99
    };

    const pattern = [
      { bass: notes.F3, chord: [notes.A3, notes.C4, notes.E4], melody: [notes.A4, notes.C5, notes.E5, notes.C5], time: 0 },
      { bass: notes.E3, chord: [notes.G3, notes.B3, notes.D4], melody: [notes.G4, notes.B4, notes.D5, notes.B4], time: 2.4 },
      { bass: notes.D3, chord: [notes.F3, notes.A3, notes.C4], melody: [notes.F4, notes.A4, notes.C5, notes.A4], time: 4.8 },
      { bass: notes.C3, chord: [notes.E3, notes.G3, notes.B3], melody: [notes.E4, notes.G4, notes.B4, notes.G4], time: 7.2 }
    ];

    function playNote(freq, startTime, duration, vol = 0.15, isMelody = false) {
      if (!callMusicCtx || callMusicCtx.state === 'closed') return;
      const osc = callMusicCtx.createOscillator();
      const gain = callMusicCtx.createGain();

      osc.type = isMelody ? 'sine' : 'triangle';
      osc.frequency.setValueAtTime(freq, startTime);

      // Warm envelope
      gain.gain.setValueAtTime(0.001, startTime);
      gain.gain.linearRampToValueAtTime(vol, startTime + 0.04);
      gain.gain.exponentialRampToValueAtTime(0.001, startTime + duration);

      osc.connect(gain);
      gain.connect(masterGain);

      osc.start(startTime);
      osc.stop(startTime + duration + 0.05);
    }

    function scheduleLoop(startOffset) {
      if (!callMusicCtx || callMusicCtx.state === 'closed') return;
      pattern.forEach(bar => {
        const barStart = startOffset + bar.time;
        // Bass Note
        playNote(bar.bass, barStart, 2.0, 0.22, false);
        // Harmony chord
        bar.chord.forEach(n => playNote(n, barStart + 0.05, 1.8, 0.12, false));
        // Soft arpeggio melody
        bar.melody.forEach((mn, idx) => {
          playNote(mn, barStart + 0.3 + (idx * 0.5), 0.75, 0.22, true);
        });
      });
    }

    let loopStart = callMusicCtx.currentTime + 0.1;
    scheduleLoop(loopStart);

    callMusicTimer = setInterval(() => {
      if (!callMusicCtx || callMusicCtx.state === 'closed') return;
      loopStart += 9.6;
      scheduleLoop(loopStart);
    }, 9600);

  } catch (e) {
    console.warn('Elevator music error:', e);
  }
}

function playIncomingRingtone() {
  stopCallTone();
  try {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    callMusicCtx = new AudioCtx();

    const masterGain = callMusicCtx.createGain();
    masterGain.gain.setValueAtTime(0.12, callMusicCtx.currentTime);
    masterGain.connect(callMusicCtx.destination);

    const notes = [523.25, 659.25, 783.99, 1046.50, 783.99, 659.25]; // C5, E5, G5, C6, G5, E5

    function playRingtoneNote(freq, time) {
      if (!callMusicCtx || callMusicCtx.state === 'closed') return;
      const osc = callMusicCtx.createOscillator();
      const gain = callMusicCtx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, time);
      gain.gain.setValueAtTime(0.001, time);
      gain.gain.linearRampToValueAtTime(0.18, time + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, time + 0.4);
      osc.connect(gain);
      gain.connect(masterGain);
      osc.start(time);
      osc.stop(time + 0.45);
    }

    function scheduleRingtoneLoop(startOffset) {
      if (!callMusicCtx || callMusicCtx.state === 'closed') return;
      notes.forEach((freq, i) => {
        playRingtoneNote(freq, startOffset + (i * 0.18));
      });
    }

    let t = callMusicCtx.currentTime + 0.1;
    scheduleRingtoneLoop(t);

    callMusicTimer = setInterval(() => {
      if (!callMusicCtx || callMusicCtx.state === 'closed') return;
      t = callMusicCtx.currentTime + 0.1;
      scheduleRingtoneLoop(t);
    }, 2400);

  } catch (e) {
    console.warn('Ringtone synth error:', e);
  }
}

function playCallTone(type = 'dialing') {
  if (type === 'dialing') {
    playElevatorMusic();
  } else if (type === 'ringing') {
    playIncomingRingtone();
  }
}

function stopCallTone() {
  if (callMusicTimer) {
    clearInterval(callMusicTimer);
    callMusicTimer = null;
  }
  if (callMusicCtx) {
    try {
      callMusicCtx.close();
    } catch (e) {}
    callMusicCtx = null;
  }
}

// Resilient media acquisition helper with multi-tier fallback
async function acquireUserMedia(requestedType = 'audio') {
  const audioConstraints = {
    echoCancellation: true,
    noiseSuppression: true,
    autoGainControl: true
  };

  if (requestedType === 'video') {
    // Tier 1: Flexible video + audio
    try {
      return await navigator.mediaDevices.getUserMedia({
        audio: audioConstraints,
        video: {
          facingMode: isFrontCamera ? 'user' : 'environment',
          width: { ideal: 1280, min: 320 },
          height: { ideal: 720, min: 240 }
        }
      });
    } catch (vidErr1) {
      console.warn('Strict video getUserMedia failed, trying minimal video: true...', vidErr1);
      try {
        // Tier 2: Minimal video constraint
        return await navigator.mediaDevices.getUserMedia({
          audio: audioConstraints,
          video: true
        });
      } catch (vidErr2) {
        console.warn('Video acquisition failed, falling back to audio-only...', vidErr2);
        // Tier 3: Graceful audio-only fallback
        const audioStream = await navigator.mediaDevices.getUserMedia({
          audio: audioConstraints,
          video: false
        });
        showToast('Камера недоступна (занята или нет доступа). Звонок переведён в голосовой режим', 'warning');
        return audioStream;
      }
    }
  } else {
    // Audio-only
    return await navigator.mediaDevices.getUserMedia({
      audio: audioConstraints,
      video: false
    });
  }
}

// Flush all queued ICE candidates once remote description is set
async function processPendingIceCandidates() {
  if (!peerConnection || !peerConnection.remoteDescription || !peerConnection.remoteDescription.type) return;
  while (pendingIceCandidates.length > 0) {
    const cand = pendingIceCandidates.shift();
    try {
      await peerConnection.addIceCandidate(new RTCIceCandidate(cand));
    } catch (e) {
      console.warn('Error adding queued ICE candidate:', e);
    }
  }
}

async function startDirectCall(type = 'audio') {
  if (!activeChat || activeChat.type === 'group' || !activeChat.partner) {
    showToast('Звонки доступны только в личных диалогах 1-на-1', 'info');
    return;
  }

  currentCallPeerId = activeChat.partner.id;
  currentCallType = type;
  isCallInitiator = true;
  pendingIceCandidates = [];

  setupCallModalUI({
    name: activeChat.partner.name,
    username: activeChat.partner.username,
    avatar: activeChat.partner.avatar,
    status: 'Вызов собеседника...',
    isIncoming: false,
    type
  });

  playCallTone('dialing');

  try {
    localStream = await acquireUserMedia(type);
    const hasVideo = localStream.getVideoTracks().length > 0;

    if (hasVideo) {
      const localVid = document.getElementById('localVideo');
      if (localVid) {
        localVid.srcObject = localStream;
        localVid.muted = true;
        localVid.play().catch(() => {});
      }
      document.getElementById('callVideoContainer').classList.remove('hidden');
    } else {
      document.getElementById('callVideoContainer').classList.add('hidden');
      document.getElementById('callToggleCamBtn').classList.add('hidden');
      document.getElementById('callSwitchCamBtn').classList.add('hidden');
    }

    createPeerConnection();

    localStream.getTracks().forEach(track => {
      peerConnection.addTrack(track, localStream);
    });

    const offer = await peerConnection.createOffer({
      offerToReceiveAudio: true,
      offerToReceiveVideo: true
    });
    await peerConnection.setLocalDescription(offer);

    socket.emit('call_start', {
      toUserId: currentCallPeerId,
      type: hasVideo ? 'video' : 'audio',
      offer,
      chatId: activeChat.id
    });
  } catch (err) {
    console.error('Call media error:', err);
    stopCallTone();
    closeModal('callModal');
    showToast('Не удалось получить доступ к микрофону. Разрешите доступ в настройках браузера.', 'error');
  }
}

function handleIncomingCall(data) {
  pendingIncomingCallData = data;
  currentCallPeerId = data.fromUserId;
  currentCallType = data.type || 'audio';
  isCallInitiator = false;
  pendingIceCandidates = [];

  setupCallModalUI({
    name: data.callerName,
    username: data.callerUsername,
    avatar: data.callerAvatar,
    status: data.type === 'video' ? '📹 Входящий видеозвонок...' : '📞 Входящий голосовой звонок...',
    isIncoming: true,
    type: data.type
  });

  playCallTone('ringing');
}

async function acceptIncomingCall() {
  if (!pendingIncomingCallData) return;
  stopCallTone();

  document.getElementById('callAcceptBtn').classList.add('hidden');
  document.getElementById('callStatusText').innerText = 'Подключение...';

  try {
    localStream = await acquireUserMedia(currentCallType);
    const hasVideo = localStream.getVideoTracks().length > 0;

    if (hasVideo) {
      const localVid = document.getElementById('localVideo');
      if (localVid) {
        localVid.srcObject = localStream;
        localVid.muted = true;
        localVid.play().catch(() => {});
      }
      document.getElementById('callVideoContainer').classList.remove('hidden');
      document.getElementById('callToggleCamBtn').classList.remove('hidden');
      document.getElementById('callSwitchCamBtn').classList.remove('hidden');
    } else {
      document.getElementById('callToggleCamBtn').classList.add('hidden');
      document.getElementById('callSwitchCamBtn').classList.add('hidden');
    }

    createPeerConnection();

    localStream.getTracks().forEach(track => {
      peerConnection.addTrack(track, localStream);
    });

    await peerConnection.setRemoteDescription(new RTCSessionDescription(pendingIncomingCallData.offer));
    await processPendingIceCandidates();

    const answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    socket.emit('call_accept', {
      toUserId: currentCallPeerId,
      answer
    });

    startCallTimer();
  } catch (err) {
    console.error('Accept call error:', err);
    endCall();
    showToast('Ошибка подключения звонка: разрешите микрофон', 'error');
  }
}

async function handleCallAccepted({ fromUserId, answer }) {
  stopCallTone();
  document.getElementById('callStatusText').innerText = 'Соединено (P2P)';
  startCallTimer();

  try {
    if (peerConnection) {
      await peerConnection.setRemoteDescription(new RTCSessionDescription(answer));
      await processPendingIceCandidates();
    }
  } catch (err) {
    console.error('Set remote answer error:', err);
  }
}

function handleCallRejected({ fromUserId, reason }) {
  stopCallTone();
  showToast('Собеседник отклонил звонок', 'info');
  cleanUpCall();
}

function handleCallEnded() {
  stopCallTone();
  showToast('Звонок завершён', 'info');
  cleanUpCall();
}

function handleCallFailed({ reason, message }) {
  stopCallTone();
  showToast(message || 'Не удалось дозвониться', 'error');
  cleanUpCall();
}

async function handleCallIceCandidate({ candidate }) {
  if (!candidate) return;
  try {
    if (peerConnection && peerConnection.remoteDescription && peerConnection.remoteDescription.type) {
      await peerConnection.addIceCandidate(new RTCIceCandidate(candidate));
    } else {
      pendingIceCandidates.push(candidate);
    }
  } catch (e) {
    console.warn('Add ICE candidate error:', e);
  }
}

function createPeerConnection() {
  peerConnection = new RTCPeerConnection(iceServersConfig);

  peerConnection.onicecandidate = (event) => {
    if (event.candidate && currentCallPeerId && socket) {
      socket.emit('call_ice_candidate', {
        toUserId: currentCallPeerId,
        candidate: event.candidate
      });
    }
  };

  peerConnection.ontrack = (event) => {
    console.log('WebRTC ontrack track kind:', event.track.kind);
    if (event.streams && event.streams[0]) {
      remoteStream = event.streams[0];
    } else {
      if (!remoteStream) remoteStream = new MediaStream();
      remoteStream.addTrack(event.track);
    }

    const remoteVid = document.getElementById('remoteVideo');
    const remoteAud = document.getElementById('remoteAudio');

    if (remoteAud) {
      remoteAud.srcObject = remoteStream;
      remoteAud.autoplay = true;
      remoteAud.playsInline = true;
      remoteAud.play().catch(err => console.warn('Remote audio autoplay error:', err));
    }

    if (event.track.kind === 'video' && remoteVid) {
      remoteVid.srcObject = remoteStream;
      remoteVid.autoplay = true;
      remoteVid.playsInline = true;
      document.getElementById('callVideoContainer').classList.remove('hidden');
      remoteVid.play().catch(err => console.warn('Remote video autoplay error:', err));
    }
  };

  peerConnection.oniceconnectionstatechange = () => {
    console.log('ICE connection state:', peerConnection?.iceConnectionState);
    if (peerConnection?.iceConnectionState === 'connected' || peerConnection?.iceConnectionState === 'completed') {
      document.getElementById('callStatusText').innerText = 'В разговоре (P2P Защищено)';
      const remoteAud = document.getElementById('remoteAudio');
      if (remoteAud) remoteAud.play().catch(() => {});
    } else if (peerConnection?.iceConnectionState === 'failed') {
      console.warn('ICE connection failed, attempting ICE restart...');
      if (peerConnection.restartIce) peerConnection.restartIce();
    }
  };

  peerConnection.onconnectionstatechange = () => {
    if (!peerConnection) return;
    if (peerConnection.connectionState === 'connected') {
      document.getElementById('callStatusText').innerText = 'В разговоре (P2P Защищено)';
      const remoteAud = document.getElementById('remoteAudio');
      if (remoteAud) remoteAud.play().catch(() => {});
    } else if (peerConnection.connectionState === 'disconnected' || peerConnection.connectionState === 'failed') {
      endCall();
    }
  };
}

function setupCallModalUI({ name, username, avatar, status, isIncoming, type }) {
  const avatarEl = document.getElementById('callAvatar');
  if (avatarEl) {
    avatarEl.innerHTML = avatar ? `<img src="${avatar}" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">` : getInitials(name);
  }
  document.getElementById('callUserName').innerText = name || `@${username}`;
  document.getElementById('callStatusText').innerText = status;
  document.getElementById('callTimer').classList.add('hidden');
  document.getElementById('callTimer').innerText = '00:00';

  if (isIncoming) {
    document.getElementById('callAcceptBtn').classList.remove('hidden');
  } else {
    document.getElementById('callAcceptBtn').classList.add('hidden');
  }

  if (type === 'video') {
    document.getElementById('callToggleCamBtn').classList.remove('hidden');
    document.getElementById('callSwitchCamBtn').classList.remove('hidden');
  } else {
    document.getElementById('callToggleCamBtn').classList.add('hidden');
    document.getElementById('callSwitchCamBtn').classList.add('hidden');
    document.getElementById('callVideoContainer').classList.add('hidden');
  }

  openModal('callModal');
}

function startCallTimer() {
  clearInterval(callDurationTimer);
  callSecondsElapsed = 0;
  const timerEl = document.getElementById('callTimer');
  timerEl.classList.remove('hidden');
  callDurationTimer = setInterval(() => {
    callSecondsElapsed++;
    const m = Math.floor(callSecondsElapsed / 60);
    const s = callSecondsElapsed % 60;
    timerEl.innerText = `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }, 1000);
}

function toggleCallMic() {
  if (localStream) {
    const audioTrack = localStream.getAudioTracks()[0];
    if (audioTrack) {
      audioTrack.enabled = !audioTrack.enabled;
      const btn = document.getElementById('callMuteMicBtn');
      btn.classList.toggle('active-off', !audioTrack.enabled);
      btn.innerHTML = audioTrack.enabled ? '<i class="fa-solid fa-microphone"></i>' : '<i class="fa-solid fa-microphone-slash"></i>';
    }
  }
}

async function toggleCallCam() {
  if (!localStream) return;
  let videoTrack = localStream.getVideoTracks()[0];
  const btn = document.getElementById('callToggleCamBtn');

  if (videoTrack) {
    videoTrack.enabled = !videoTrack.enabled;
    btn.classList.toggle('active-off', !videoTrack.enabled);
    btn.innerHTML = videoTrack.enabled ? '<i class="fa-solid fa-video"></i>' : '<i class="fa-solid fa-video-slash"></i>';
  } else {
    try {
      const camStream = await navigator.mediaDevices.getUserMedia({
        video: {
          facingMode: isFrontCamera ? 'user' : 'environment',
          width: { ideal: 1280, min: 320 },
          height: { ideal: 720, min: 240 }
        }
      });
      videoTrack = camStream.getVideoTracks()[0];
      if (videoTrack) {
        localStream.addTrack(videoTrack);
        const localVid = document.getElementById('localVideo');
        if (localVid) {
          localVid.srcObject = localStream;
          localVid.muted = true;
          localVid.play().catch(() => {});
        }
        document.getElementById('callVideoContainer').classList.remove('hidden');
        document.getElementById('callSwitchCamBtn').classList.remove('hidden');
        btn.classList.remove('active-off');
        btn.innerHTML = '<i class="fa-solid fa-video"></i>';

        if (peerConnection) {
          const sender = peerConnection.getSenders().find(s => s.track && s.track.kind === 'video');
          if (sender) {
            await sender.replaceTrack(videoTrack);
          } else {
            peerConnection.addTrack(videoTrack, localStream);
          }
        }
      }
    } catch (e) {
      console.warn('Failed to enable camera on-the-fly:', e);
      showToast('Не удалось получить доступ к камере', 'warning');
    }
  }
}

async function switchCallCamera() {
  if (!localStream || currentCallType !== 'video') return;
  isFrontCamera = !isFrontCamera;
  const videoTrack = localStream.getVideoTracks()[0];
  if (videoTrack) {
    videoTrack.stop();
    localStream.removeTrack(videoTrack);
  }

  try {
    const newStream = await navigator.mediaDevices.getUserMedia({
      video: {
        facingMode: isFrontCamera ? 'user' : 'environment',
        width: { ideal: 1280, min: 320 },
        height: { ideal: 720, min: 240 }
      }
    });
    const newTrack = newStream.getVideoTracks()[0];
    if (newTrack) {
      localStream.addTrack(newTrack);
      const localVid = document.getElementById('localVideo');
      if (localVid) {
        localVid.srcObject = localStream;
        localVid.muted = true;
        localVid.play().catch(() => {});
      }

      if (peerConnection) {
        const sender = peerConnection.getSenders().find(s => s.track && s.track.kind === 'video');
        if (sender) {
          await sender.replaceTrack(newTrack);
        } else {
          peerConnection.addTrack(newTrack, localStream);
        }
      }
    }
  } catch (e) {
    console.warn('Failed to switch camera:', e);
    showToast('Не удалось переключить камеру', 'warning');
  }
}

function endCall() {
  stopCallTone();
  if (currentCallPeerId && socket) {
    socket.emit('call_end', { toUserId: currentCallPeerId });
  }
  cleanUpCall();
}

function cleanUpCall() {
  stopCallTone();
  clearInterval(callDurationTimer);
  if (localStream) {
    localStream.getTracks().forEach(t => t.stop());
    localStream = null;
  }
  if (remoteStream) {
    remoteStream.getTracks().forEach(t => t.stop());
    remoteStream = null;
  }
  const localVid = document.getElementById('localVideo');
  if (localVid) localVid.srcObject = null;
  const remoteVid = document.getElementById('remoteVideo');
  if (remoteVid) remoteVid.srcObject = null;
  const remoteAud = document.getElementById('remoteAudio');
  if (remoteAud) remoteAud.srcObject = null;

  if (peerConnection) {
    try { peerConnection.close(); } catch (e) {}
    peerConnection = null;
  }
  pendingIceCandidates = [];
  currentCallPeerId = null;
  pendingIncomingCallData = null;
  closeModal('callModal');
}


async function leaveCurrentGroup() {
  if (!activeChat || activeChat.type !== 'group') return;
  const groupName = activeChat.name || 'группу';
  if (!confirm(`Вы действительно хотите покинуть группу «${groupName}»?\n\nВы больше не будете состоять в ней и не будете получать уведомления о новых участниках и сообщениях.`)) {
    return;
  }

  try {
    const res = await fetch(`/api/chats/${activeChat.id}/members/${currentUser.id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (res.ok) {
      closeModal('chatDetailsModal');
      activeChat = null;
      showToast(`Вы покинули группу «${groupName}»`);
      await loadChats();
      document.getElementById('emptyChatState').classList.remove('hidden');
      document.getElementById('activeChatState').classList.add('hidden');
    } else {
      alert(data.error || 'Ошибка при выходе из группы');
    }
  } catch (err) {
    alert('Сетевая ошибка при выходе из группы');
  }
}

// ----------------------------------------------------
// WEB PUSH NOTIFICATIONS CLIENT (iOS Safari / Android / Desktop)
// ----------------------------------------------------

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/\-/g, '+').replace(/_/g, '/');
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

async function getSwRegistration() {
  if (!('serviceWorker' in navigator)) return null;
  try {
    const reg = await navigator.serviceWorker.getRegistration();
    if (reg) return reg;
    return await Promise.race([
      navigator.serviceWorker.ready,
      new Promise((resolve) => setTimeout(() => resolve(null), 2500))
    ]);
  } catch (e) {
    return null;
  }
}

function updatePushStatusUI(status) {
  const badge = document.getElementById('pushStatusBadge');
  const btn = document.getElementById('pushEnableBtn');
  const menuBadge = document.getElementById('mainMenuPushBadge');
  const menuIcon = document.getElementById('mainMenuPushIcon');
  const menuText = document.getElementById('mainMenuPushText');

  if (status === 'unsupported') {
    if (badge) { badge.className = 'badge badge-secondary'; badge.innerText = 'Не поддерживается'; }
    if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fa-solid fa-ban"></i> Не поддерживается'; }
    if (menuBadge) { menuBadge.className = 'badge badge-secondary'; menuBadge.innerText = 'Н/Д'; }
    if (menuIcon) { menuIcon.className = 'fa-solid fa-ban text-secondary'; }
    if (menuText) { menuText.innerText = 'Push: Не поддерживается'; }
  } else if (status === 'denied') {
    if (badge) { badge.className = 'badge badge-danger'; badge.innerText = 'Заблокировано'; }
    if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fa-solid fa-lock"></i> Разрешите в браузере'; }
    if (menuBadge) { menuBadge.className = 'badge badge-danger'; menuBadge.innerText = 'Блок'; }
    if (menuIcon) { menuIcon.className = 'fa-solid fa-lock text-danger'; }
    if (menuText) { menuText.innerText = 'Push: Разрешите в браузере'; }
  } else if (status === 'granted') {
    if (badge) { badge.className = 'badge badge-success'; badge.innerText = 'Включено (Активно)'; }
    if (btn) {
      btn.className = 'btn btn-outline btn-xs';
      btn.innerHTML = '<i class="fa-solid fa-bell-slash"></i> Отключить Push';
      btn.disabled = false;
    }
    if (menuBadge) { menuBadge.className = 'badge badge-success'; menuBadge.innerText = 'Вкл'; }
    if (menuIcon) { menuIcon.className = 'fa-solid fa-bell text-success'; }
    if (menuText) { menuText.innerText = 'Уведомления (Вкл)'; }
  } else {
    // off
    if (badge) { badge.className = 'badge badge-warning'; badge.innerText = 'Выключено'; }
    if (btn) {
      btn.className = 'btn btn-primary btn-xs';
      btn.innerHTML = '<i class="fa-solid fa-bell"></i> Включить Push';
      btn.disabled = false;
    }
    if (menuBadge) { menuBadge.className = 'badge badge-warning'; menuBadge.innerText = 'Выкл'; }
    if (menuIcon) { menuIcon.className = 'fa-solid fa-bell-slash text-warning'; }
    if (menuText) { menuText.innerText = 'Уведомления (Выкл)'; }
  }
}

async function checkPushStatus() {
  if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
    updatePushStatusUI('unsupported');
    return;
  }

  if (Notification.permission === 'denied') {
    updatePushStatusUI('denied');
    return;
  }

  try {
    const reg = await getSwRegistration();
    if (!reg) return;
    const sub = await reg.pushManager.getSubscription();
    if (sub && Notification.permission === 'granted') {
      updatePushStatusUI('granted');
    } else {
      updatePushStatusUI('off');
    }
  } catch (e) {
    console.error('checkPushStatus error:', e);
  }
}

async function autoSyncPushSubscription() {
  if (!('serviceWorker' in navigator) || !('PushManager' in window)) return;
  if (!token || Notification.permission !== 'granted') return;

  try {
    const reg = await getSwRegistration();
    if (!reg) return;

    let sub = await reg.pushManager.getSubscription();
    if (!sub) {
      // User has notifications enabled in Android/Browser settings, auto-subscribe!
      const keyRes = await fetch('/api/push/vapid-public-key');
      const keyData = await keyRes.json();
      if (!keyData.publicKey) return;
      const applicationServerKey = urlBase64ToUint8Array(keyData.publicKey);
      try {
        sub = await reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey
        });
      } catch (subErr) {
        console.warn('autoSync push subscribe error:', subErr);
      }
    }

    if (sub) {
      await fetch('/api/push/subscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({
          subscription: sub.toJSON(),
          userAgent: navigator.userAgent
        })
      });
      await checkPushStatus();
    }
  } catch (err) {
    console.warn('autoSyncPushSubscription non-fatal:', err);
  }
}

async function togglePushSubscription() {
  if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
    alert('Ваш браузер или устройство не поддерживает Push Notifications API.\nНа iPhone убедитесь, что приложение добавлено на экран «Домой» через Safari (iOS 16.4+).');
    return;
  }

  let reg = await getSwRegistration();
  if (!reg) {
    try {
      reg = await navigator.serviceWorker.register('/sw.js');
      await navigator.serviceWorker.ready;
    } catch (e) {
      alert('Служба Service Worker еще инициализируется. Пожалуйста, подождите или перезагрузите страницу.');
      return;
    }
  }

  try {
    const existingSub = await reg.pushManager.getSubscription();
    if (existingSub) {
      // Toggle to unsubscribe
      await existingSub.unsubscribe();
      try {
        await fetch('/api/push/unsubscribe', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
          body: JSON.stringify({ endpoint: existingSub.endpoint })
        });
      } catch (netErr) {}
      showToast('🔕 Push-оповещения отключены');
      await checkPushStatus();
      return;
    }

    // Subscribe: trigger permission prompt
    const perm = await Notification.requestPermission();
    if (perm !== 'granted') {
      alert('Разрешение на отправку уведомлений не было предоставлено в браузере.');
      await checkPushStatus();
      return;
    }

    const keyRes = await fetch('/api/push/vapid-public-key');
    const keyData = await keyRes.json();
    if (!keyData.publicKey) {
      alert('Ошибка получения VAPID ключа с сервера');
      return;
    }

    const applicationServerKey = urlBase64ToUint8Array(keyData.publicKey);
    let newSub;
    try {
      newSub = await reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey
      });
    } catch (subErr) {
      console.warn('Initial pushManager.subscribe failed, trying clean attempt:', subErr);
      // If previous subscription orphaned or key changed, clear and retry
      const staleSub = await reg.pushManager.getSubscription();
      if (staleSub) await staleSub.unsubscribe();
      newSub = await reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey
      });
    }

    const subJson = newSub.toJSON();
    const saveRes = await fetch('/api/push/subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({
        subscription: subJson,
        userAgent: navigator.userAgent
      })
    });

    const saveJson = await saveRes.json().catch(() => ({}));
    if (saveRes.ok) {
      showToast('🔔 Push-оповещения успешно включены!');
      await checkPushStatus();
    } else {
      alert('Не удалось зарегистрировать Push на сервере: ' + (saveJson.error || 'Ошибка сервера'));
      await checkPushStatus();
    }
  } catch (err) {
    console.error('togglePushSubscription error:', err);
    alert('Ошибка при настройке Push-оповещений: ' + (err.message || err.name || 'неизвестная ошибка'));
    await checkPushStatus();
  }
}

async function sendTestPushNotification() {
  try {
    const res = await fetch('/api/push/test', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (res.ok) {
      showToast('🚀 Тестовый Push отправлен! Проверьте шторку уведомлений.');
    } else {
      alert(data.error || 'Ошибка отправки тестового пуша. Убедитесь, что Push включен.');
    }
  } catch (e) {
    alert('Сетевая ошибка при отправке теста');
  }
}

