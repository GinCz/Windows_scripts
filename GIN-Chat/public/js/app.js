let currentUser = null;
let token = localStorage.getItem('gin_chat_token') || null;
let socket = null;
let activeChat = null;
let allChats = [];
let currentFilter = 'all';
let replyMessage = null;
let editingMessage = null;
let currentUploadXhr = null;

// Voice recording state
let mediaRecorder = null;
let audioChunks = [];
let voiceTimerInterval = null;
let voiceStartTime = null;

// Emoji sets
const emojis = {
  smileys: ['😀','😃','😄','😁','😆','😅','😂','🤣','🥲','🥹','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😙','😚','😋','😛','😝','😜','🤪','🤨','🧐','🤓','😎','🥸','🤩','🥳','😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢','😭','😮‍💨','😤','😠','😡','🤬','🤯','😳','🥵','🥶','😱','😨','😰','😥','😓','🫣','🤗','🫡','🤫','🫠','🤥','😶','🫥','😐','🫤','😑','🫨','😬','🙄','😯','😦','😧','😮','😲','🥱','😴','🤤','😪','😵','😵‍💫','🤐','🥴','🤢','🤮','🤧','😷','🤒','🤕'],
  gestures: ['👍','👎','👏','🙌','🤝','🙏','💪','✌️','🤞','🤟','🤘','👌','🤏','👈','👉','👆','👇','☝️','✋','🤚','🖐️','🖖','👋','🤙','✍️','💅'],
  hearts: ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❤️‍🔥','❤️‍🩹','💖','💗','💓','💞','💕','💘','💝'],
  animals: ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🐔','🐧','🐦','🐤','🦆','🦅','🦉','🦇','🐺','🐗','🐴','🦄','🐝','🐛','🦋','🐌','🐞','🐜','🦟','🦗','🕷️','🦂','🐢','🐍','🦎','🐙','🦑','🦐','🦞','🦀','🐡','🐠','🐟','🐬','🐳','🐋','🦈','🐊','🐆','🐅','🐃','🐂','🐄','🐪','🐫','🦙','🐘','🦏','🦛','🐐','🐏','🐑','🐎','🐖'],
  objects: ['🔥','✨','🎉','🎊','💡','⭐','🌟','⚡','💥','🚀','🛡️','🎯','👑','🏆','🎁','🎈','🔔','📱','💻','⌨️','📷','🎥','🎧','🎵','🎶','🔑','🔒','⚙️','💎','💣','☕','🍺','🍕','🍔']
};

document.addEventListener('DOMContentLoaded', () => {
  if (token) {
    fetchMe();
  } else {
    showAuthScreen();
  }
  loadEmojiCategory('smileys');

  const msgInput = document.getElementById('messageInput');
  msgInput?.addEventListener('input', () => {
    msgInput.style.height = 'auto';
    msgInput.style.height = Math.min(msgInput.scrollHeight, 120) + 'px';
    const hasText = msgInput.value.trim().length > 0;
    document.getElementById('sendBtn').classList.toggle('hidden', !hasText);
    document.getElementById('voiceBtn').classList.toggle('hidden', hasText);
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
    if (activeChat && activeChat.id === msg.chat_id) {
      appendMessageToView(msg);
      scrollToBottom();
      socket.emit('mark_read', { chatId: msg.chat_id, messageIds: [msg.id] });
    }
    playMessageSound();
    loadChats();
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
    if (currentUser && (currentUser.role === 'superadmin' || currentUser.role === 'admin')) {
      checkPendingUsersCount();
      loadAdminData();
    }
  });

  socket.on('user_status', ({ userId, status }) => {
    if (activeChat && activeChat.partner && activeChat.partner.id === userId) {
      activeChat.partner.is_online = status === 'online';
      updateChatHeaderSubtitle();
    }
  });
}

function playMessageSound() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(587.33, ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.1);
    gain.gain.setValueAtTime(0.2, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + 0.2);
  } catch (e) {}
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
    const preview = chat.lastMessage ? escapeHtml(chat.lastMessage.text) : 'Нет сообщений';
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
    const res = await fetch(`/api/chats/${chatId}`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    if (!res.ok) return;

    activeChat = { ...data.chat, members: data.members, myRole: data.myRole, pinnedMessage: data.pinnedMessage };

    if (socket) {
      socket.emit('join_chat', { chatId });
    }

    document.getElementById('emptyChatState').classList.add('hidden');
    const activeChatEl = document.getElementById('activeChatContainer');
    activeChatEl.classList.remove('hidden');
    activeChatEl.className = activeChatEl.className.replace(/chat-theme-\d/g, '').trim();
    const themeIdx = Math.abs(Number(chatId) || 0) % 8;
    activeChatEl.classList.add(`chat-theme-${themeIdx}`);

    document.body.classList.add('mobile-chat-open');

    const displayName = activeChat.name || (activeChat.partner ? activeChat.partner.name : 'Личный диалог');
    document.getElementById('chatHeaderTitle').innerText = displayName;
    updateAvatarElement('chatHeaderAvatar', activeChat.avatar, displayName, 'avatar-md');
    updateChatHeaderSubtitle();

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

    if (activeChat.type === 'group') {
      const slug = encodeURIComponent((activeChat.name || 'group').trim().replace(/[\s\/]+/g, '_'));
      const code = activeChat.invite_code || activeChat.id;
      if (window.location.hash !== `#/group/${code}/${slug}`) {
        history.replaceState({ chatId }, '', `#/group/${code}/${slug}`);
      }
    } else {
      if (window.location.hash !== '#/c/' + chatId) {
        history.replaceState({ chatId }, '', '#/c/' + chatId);
      }
    }

    renderChatsList();
    loadMessages(chatId);
  } catch (err) {
    console.error('Error opening chat:', err);
  }
}

function updateChatHeaderSubtitle() {
  const sub = document.getElementById('chatHeaderSubtitle');
  if (!activeChat) return;
  if (activeChat.type === 'group') {
    sub.innerText = `${activeChat.members ? activeChat.members.length : 0} участников`;
  } else {
    if (activeChat.partner && activeChat.partner.username) {
      sub.innerText = `@${activeChat.partner.username} • в сети`;
    } else {
      sub.innerText = 'в сети';
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

  // Message Action Bar (Hover on bubble)
  contentHtml += `
    <div class="msg-action-bar">
      <button class="msg-act-btn" onclick="toggleReaction(${msg.id}, '👍')" title="Нравится 👍">👍</button>
      <button class="msg-act-btn" onclick="toggleReaction(${msg.id}, '❤️')" title="Любовь ❤️">❤️</button>
      <button class="msg-act-btn" onclick="toggleReaction(${msg.id}, '🔥')" title="Огонь 🔥">🔥</button>
      <button class="msg-act-btn" onclick="toggleReaction(${msg.id}, '😂')" title="Смех 😂">😂</button>
      <button class="msg-act-btn reaction-more" onclick="openReactionPicker(event, ${msg.id})" title="Все 25 реакций"><i class="fa-regular fa-face-smile"></i></button>
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
  } else if (msg.type === 'voice') {
    contentHtml += `
      <div class="msg-voice-box">
        <button class="voice-play-btn" onclick="togglePlayVoice(this, '${msg.file_url}')"><i class="fa-solid fa-play"></i></button>
        <div class="voice-progress-container">
          <div class="voice-waveform"><div class="voice-waveform-fill"></div></div>
          <div class="voice-time">0:00</div>
        </div>
      </div>
    `;
  } else if (msg.type === 'file') {
    const fileMeta = getFileInfo(msg.file_name);
    contentHtml += `
      <div class="msg-file-card">
        <div class="msg-file-badge" style="background: ${fileMeta.bg}; color: ${fileMeta.color}; border: 1px solid ${fileMeta.color}40;">
          <i class="${fileMeta.icon}"></i>
          <span class="msg-file-ext-tag">${fileMeta.label}</span>
        </div>
        <div class="msg-file-details">
          <div class="msg-file-title" title="${escapeHtml(msg.file_name)}">${escapeHtml(msg.file_name)}</div>
          <div class="msg-file-meta-row">
            <span class="msg-file-size-badge">${formatFileSize(msg.file_size)}</span>
          </div>
        </div>
        <a href="${msg.file_url}" target="_blank" download="${escapeHtml(msg.file_name)}" class="btn-file-open" title="Открыть или скачать файл">
          <i class="fa-solid fa-arrow-up-right-from-square"></i> Открыть
        </a>
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

  bubble.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    setReplyMessage(msg);
  });
  bubble.addEventListener('dblclick', () => {
    toggleReaction(msg.id, '👍');
  });

  row.appendChild(bubble);
  container.appendChild(row);

  renderReactions(msg.id, msg.reactions);
}

function getFileInfo(fileName) {
  const name = fileName || 'Файл';
  const parts = name.split('.');
  const ext = parts.length > 1 ? parts.pop().toLowerCase() : '';

  if (['pdf'].includes(ext)) {
    return { icon: 'fa-solid fa-file-pdf', color: '#ef4444', label: 'PDF', bg: 'rgba(239, 68, 68, 0.16)' };
  }
  if (['doc', 'docx', 'rtf', 'odt', 'txt'].includes(ext)) {
    return { icon: 'fa-solid fa-file-word', color: '#3b82f6', label: ext ? ext.toUpperCase() : 'DOC', bg: 'rgba(59, 130, 246, 0.16)' };
  }
  if (['xls', 'xlsx', 'csv'].includes(ext)) {
    return { icon: 'fa-solid fa-file-excel', color: '#10b981', label: ext.toUpperCase(), bg: 'rgba(16, 185, 129, 0.16)' };
  }
  if (['ppt', 'pptx'].includes(ext)) {
    return { icon: 'fa-solid fa-file-powerpoint', color: '#f97316', label: ext.toUpperCase(), bg: 'rgba(249, 115, 22, 0.16)' };
  }
  if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2'].includes(ext)) {
    return { icon: 'fa-solid fa-file-zipper', color: '#f59e0b', label: ext.toUpperCase(), bg: 'rgba(245, 158, 11, 0.16)' };
  }
  if (['js', 'ts', 'py', 'json', 'html', 'css', 'php', 'sh', 'sql', 'cpp', 'c', 'yml', 'yaml'].includes(ext)) {
    return { icon: 'fa-solid fa-file-code', color: '#a855f7', label: ext.toUpperCase(), bg: 'rgba(168, 85, 247, 0.16)' };
  }
  if (['mp4', 'mkv', 'avi', 'mov', 'webm'].includes(ext)) {
    return { icon: 'fa-solid fa-file-video', color: '#ec4899', label: ext.toUpperCase(), bg: 'rgba(236, 72, 153, 0.16)' };
  }
  if (['mp3', 'wav', 'ogg', 'flac', 'm4a'].includes(ext)) {
    return { icon: 'fa-solid fa-file-audio', color: '#06b6d4', label: ext.toUpperCase(), bg: 'rgba(6, 182, 212, 0.16)' };
  }
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].includes(ext)) {
    return { icon: 'fa-solid fa-file-image', color: '#38bdf8', label: ext.toUpperCase(), bg: 'rgba(56, 189, 248, 0.16)' };
  }
  return { icon: 'fa-solid fa-file-lines', color: '#94a3b8', label: ext ? ext.toUpperCase() : 'DOC', bg: 'rgba(148, 163, 184, 0.16)' };
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

function scrollToBottom() {
  const el = document.getElementById('messagesContainer');
  el.scrollTop = el.scrollHeight;
}

function backToChatsList() {
  document.body.classList.remove('mobile-chat-open');
}

// ----------------------------------------------------
// SEND MESSAGE, EDIT & DELETE ACTIONS
// ----------------------------------------------------

function handleInputKeydown(e) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    sendMessage();
  }
}

let typingTimeout = null;
function handleTypingEvent() {
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

  socket.emit('send_message', {
    chatId: activeChat.id,
    text,
    type: 'text',
    replyToId: replyMessage ? replyMessage.id : null
  }, (res) => {
    if (res && res.error) alert(res.error);
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

let activeAudio = null;
function togglePlayVoice(btn, url) {
  if (activeAudio && activeAudio.src.endsWith(url) && !activeAudio.paused) {
    activeAudio.pause();
    btn.innerHTML = '<i class="fa-solid fa-play"></i>';
    return;
  }

  if (activeAudio) {
    activeAudio.pause();
  }

  activeAudio = new Audio(url);
  const container = btn.closest('.msg-voice-box');
  const fill = container.querySelector('.voice-waveform-fill');
  const timeLabel = container.querySelector('.voice-time');

  btn.innerHTML = '<i class="fa-solid fa-pause"></i>';
  activeAudio.play();

  activeAudio.ontimeupdate = () => {
    const prog = (activeAudio.currentTime / activeAudio.duration) * 100;
    fill.style.width = prog + '%';
    const s = Math.floor(activeAudio.currentTime);
    timeLabel.innerText = `0:${String(s).padStart(2, '0')}`;
  };

  activeAudio.onended = () => {
    btn.innerHTML = '<i class="fa-solid fa-play"></i>';
    fill.style.width = '0%';
  };
}

// ----------------------------------------------------
// EMOJI & REACTIONS
// ----------------------------------------------------

function toggleEmojiPicker() {
  document.getElementById('emojiPicker').classList.toggle('hidden');
}

function loadEmojiCategory(cat) {
  const grid = document.getElementById('emojiGrid');
  grid.innerHTML = (emojis[cat] || []).map(e => `
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
// FORWARD MESSAGE SYSTEM (Compact Vertical & Multi-Select)
// ----------------------------------------------------
let forwardMessageId = null;
let forwardSelectedRecipients = new Set();
let forwardAvailableItems = [];

async function openForwardModal(messageId) {
  forwardMessageId = messageId;
  forwardSelectedRecipients.clear();
  updateForwardSubmitButton();

  const modal = document.getElementById('forwardModal');
  const searchInput = document.getElementById('forwardSearchInput');
  const listContainer = document.getElementById('forwardRecipientsList');
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
  if (!forwardMessageId || forwardSelectedRecipients.size === 0) return;

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

    socket.emit('forward_message', {
      messageId: forwardMessageId,
      targetChatIds
    }, (resp) => {
      btn.disabled = false;
      btn.innerHTML = `<i class="fa-solid fa-paper-plane"></i> Переслать (<span id="forwardSelectedCount">0</span>)`;
      if (resp && resp.error) {
        alert(resp.error);
      } else {
        closeModal('forwardModal');
        showToast(`Сообщение успешно переслано (${targetChatIds.length})!`);
        loadChats();
      }
    });
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
        <button class="btn btn-xs btn-primary contact-card-btn" onclick="event.stopPropagation(); startDirectWithUser(${u.id})" title="Написать"><i class="fa-solid fa-paper-plane"></i> Написать</button>
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

    const pending = users.filter(u => u.status === 'pending');
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
    allTable.innerHTML = users.map(u => `
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
              <button class="btn btn-xs btn-outline" onclick="openAdminEditUserModalById(${u.id})" title="Изм"><i class="fa-solid fa-user-pen"></i></button>
              <button class="btn btn-xs btn-danger" onclick="adminDeleteUser(${u.id})" title="Удалить"><i class="fa-solid fa-trash"></i></button>
            ` : `
              <button class="btn btn-xs btn-outline" onclick="openAdminEditUserModalById(${u.id})" title="Редактировать"><i class="fa-solid fa-user-pen"></i> Изм</button>
              <span class="text-muted" style="font-size: 11px; align-self: center;">(Вы)</span>
            `}
          </div>
        </td>
      </tr>
    `).join('');
  } catch (err) {
    console.error('Failed to load admin data:', err);
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
  const displayName = activeChat.name || (activeChat.partner ? activeChat.partner.name : 'Личный диалог');
  updateAvatarElement('detailsAvatar', activeChat.avatar, displayName, 'avatar-lg');

  const isGroup = activeChat.type === 'group';
  const canEdit = isGroup && (activeChat.myRole === 'owner' || activeChat.myRole === 'admin' || (currentUser && currentUser.role === 'superadmin'));

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
  if (isGroup) {
    const slug = encodeURIComponent((activeChat.name || 'group').trim().replace(/[\s\/]+/g, '_'));
    const code = activeChat.invite_code || activeChat.id;
    inviteInput.value = `${window.location.origin}/#/group/${code}/${slug}`;
    document.getElementById('inviteLinkBox').classList.remove('hidden');
  } else {
    document.getElementById('inviteLinkBox').classList.add('hidden');
  }

  renderChatMembersList();
  document.getElementById('chatDetailsModal').classList.remove('hidden');
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
  document.getElementById('mainMenu').classList.toggle('hidden');
}

function closeMainMenu() {
  document.getElementById('mainMenu').classList.add('hidden');
}

function closeModal(id) {
  document.getElementById(id).classList.add('hidden');
}

function toggleTheme() {
  document.body.classList.toggle('light-theme');
  const isLight = document.body.classList.contains('light-theme');
  document.getElementById('themeIcon').className = isLight ? 'fa-solid fa-sun' : 'fa-solid fa-moon';
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
