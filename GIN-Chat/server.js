const express = require('express');
const http = require('http');
const https = require('https');
const { Server } = require('socket.io');
const path = require('path');
const fs = require('fs');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const crypto = require('crypto');
const { db, encryptText, decryptText } = require('./db');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
  maxHttpBufferSize: 50 * 1024 * 1024 // 50MB file support
});

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'gin_super_jwt_secret_chat_2026';
const UPLOADS_DIR = process.env.UPLOADS_DIR || path.join(__dirname, 'uploads');
const TG_BOT_TOKEN = process.env.TG_BOT_TOKEN || '1226649515:AAF_jIP6ol767vCh9Ur__rEI5onTmIz2z2g';
const TG_ADMIN_CHAT_ID = process.env.TG_ADMIN_CHAT_ID || '261784949';

if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Telegram Alert Helper with Inline Buttons
function sendTelegramNotification(text, replyMarkup = null) {
  if (!TG_BOT_TOKEN || !TG_ADMIN_CHAT_ID) return;
  const payload = {
    chat_id: TG_ADMIN_CHAT_ID,
    text: text,
    parse_mode: 'HTML'
  };
  if (replyMarkup) {
    payload.reply_markup = replyMarkup;
  }
  const body = JSON.stringify(payload);
  const options = {
    hostname: 'api.telegram.org',
    port: 443,
    path: `/bot${TG_BOT_TOKEN}/sendMessage`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body)
    }
  };
  const req = https.request(options, (res) => {
    res.on('data', () => {});
  });
  req.on('error', (e) => console.error('Telegram send error:', e.message));
  req.write(body);
  req.end();
}

// Telegram API Helper (editMessageText / answerCallbackQuery)
function callTelegramApi(method, data) {
  if (!TG_BOT_TOKEN) return;
  const body = JSON.stringify(data);
  const options = {
    hostname: 'api.telegram.org',
    port: 443,
    path: `/bot${TG_BOT_TOKEN}/${method}`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body)
    }
  };
  const req = https.request(options, (res) => {
    res.on('data', () => {});
  });
  req.on('error', (e) => console.error(`Telegram ${method} error:`, e.message));
  req.write(body);
  req.end();
}

// Telegram Bot Polling Handler for Inline Actions & Moderation
let tgLastUpdateId = 0;
function pollTelegramUpdates() {
  if (!TG_BOT_TOKEN) return;
  const url = `https://api.telegram.org/bot${TG_BOT_TOKEN}/getUpdates?offset=${tgLastUpdateId + 1}&timeout=15`;
  https.get(url, (res) => {
    let raw = '';
    res.on('data', chunk => { raw += chunk; });
    res.on('end', () => {
      try {
        const data = JSON.parse(raw);
        if (data.ok && Array.isArray(data.result)) {
          data.result.forEach(update => {
            tgLastUpdateId = Math.max(tgLastUpdateId, update.update_id);
            handleTelegramUpdate(update);
          });
        }
      } catch (err) {}
      setTimeout(pollTelegramUpdates, 1500);
    });
  }).on('error', (err) => {
    setTimeout(pollTelegramUpdates, 5000);
  });
}

function handleTelegramUpdate(update) {
  // Handle Inline Button clicks
  if (update.callback_query) {
    const cb = update.callback_query;
    const data = cb.data || '';
    const queryId = cb.id;
    const msgId = cb.message ? cb.message.message_id : null;
    const chatId = cb.message ? cb.message.chat.id : TG_ADMIN_CHAT_ID;

    if (data.startsWith('approve_')) {
      const userId = data.split('_')[1];
      const user = db.prepare('SELECT id, name, username, email FROM users WHERE id = ?').get(userId);
      if (user) {
        db.prepare("UPDATE users SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(userId);
        callTelegramApi('answerCallbackQuery', { callback_query_id: queryId, text: `✅ Пользователь @${user.username} одобрен!` });
        if (msgId) {
          callTelegramApi('editMessageText', {
            chat_id: chatId,
            message_id: msgId,
            text: `✅ <b>ПОЛЬЗОВАТЕЛЬ ОДОБРЕН:</b>\n👤 <b>${escapeTgHtml(user.name)}</b> (@${escapeTgHtml(user.username)})\n📧 <code>${escapeTgHtml(user.email)}</code>\n\nДоступ в GIN-Chat открыт!`,
            parse_mode: 'HTML'
          });
        }
        io.emit('user_approved', { userId: Number(userId), username: user.username });
      } else {
        callTelegramApi('answerCallbackQuery', { callback_query_id: queryId, text: 'Пользователь не найден' });
      }
    } else if (data.startsWith('ban_')) {
      const userId = data.split('_')[1];
      const user = db.prepare('SELECT id, name, username FROM users WHERE id = ?').get(userId);
      if (user) {
        db.prepare("UPDATE users SET status = 'banned', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(userId);
        callTelegramApi('answerCallbackQuery', { callback_query_id: queryId, text: `⏸ Пользователь @${user.username} заблокирован!` });
        if (msgId) {
          callTelegramApi('editMessageText', {
            chat_id: chatId,
            message_id: msgId,
            text: `⏸ <b>ПОЛЬЗОВАТЕЛЬ ЗАБЛОКИРОВАН:</b>\n👤 <b>${escapeTgHtml(user.name)}</b> (@${escapeTgHtml(user.username)})\n\nДоступ заблокирован.`,
            parse_mode: 'HTML'
          });
        }
        io.emit('user_status_changed', { userId: Number(userId), status: 'banned' });
      }
    } else if (data.startsWith('delete_')) {
      const userId = data.split('_')[1];
      const user = db.prepare('SELECT id, name, username FROM users WHERE id = ?').get(userId);
      if (user) {
        db.prepare('DELETE FROM users WHERE id = ?').run(userId);
        callTelegramApi('answerCallbackQuery', { callback_query_id: queryId, text: `🗑 Пользователь @${user.username} удален!` });
        if (msgId) {
          callTelegramApi('editMessageText', {
            chat_id: chatId,
            message_id: msgId,
            text: `🗑 <b>ПОЛЬЗОВАТЕЛЬ УДАЛЕН ИЗ СИСТЕМЫ:</b>\n👤 <b>${escapeTgHtml(user.name)}</b> (@${escapeTgHtml(user.username)})`,
            parse_mode: 'HTML'
          });
        }
        io.emit('user_deleted', { userId: Number(userId) });
      }
    }
  }

  // Handle Text message replies from Vladimir
  if (update.message && update.message.text && String(update.message.chat.id) === String(TG_ADMIN_CHAT_ID)) {
    const text = update.message.text.trim().toLowerCase();
    const reply = update.message.reply_to_message;

    if (reply && reply.text) {
      const match = reply.text.match(/@([a-zA-Z0-9_]+)/);
      if (match) {
        const username = match[1];
        const user = db.prepare('SELECT id, name, username FROM users WHERE LOWER(username) = ?').get(username.toLowerCase());
        if (user) {
          if (text === 'да' || text === 'yes' || text === '+' || text === 'одобрить' || text === 'ок' || text === 'ok') {
            db.prepare("UPDATE users SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(user.id);
            sendTelegramNotification(`✅ Пользователь <b>${escapeTgHtml(user.name)}</b> (@${user.username}) одобрен по команде!`);
            io.emit('user_approved', { userId: user.id, username: user.username });
          } else if (text === 'бан' || text === 'блок' || text === 'заблокировать' || text === 'ban') {
            db.prepare("UPDATE users SET status = 'banned', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(user.id);
            sendTelegramNotification(`⏸ Пользователь <b>${escapeTgHtml(user.name)}</b> (@${user.username}) временно заблокирован.`);
            io.emit('user_status_changed', { userId: user.id, status: 'banned' });
          } else if (text === 'удалить' || text === 'delete' || text === 'del' || text === 'нет') {
            db.prepare('DELETE FROM users WHERE id = ?').run(user.id);
            sendTelegramNotification(`🗑 Пользователь <b>${escapeTgHtml(user.name)}</b> (@${user.username}) удален навсегда.`);
            io.emit('user_deleted', { userId: user.id });
          }
        }
      }
    }
  }
}

// Multer Storage Configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOADS_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const uniqueSuffix = Date.now() + '-' + crypto.randomBytes(6).toString('hex');
    cb(null, uniqueSuffix + ext);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 } // 50MB
});

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use('/uploads', express.static(UPLOADS_DIR));
app.use(express.static(path.join(__dirname, 'public')));

// Authentication Middleware
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Не авторизован' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = db.prepare('SELECT id, name, username, email, phone, role, status, avatar, bio FROM users WHERE id = ?').get(decoded.id);
    if (!user) return res.status(401).json({ error: 'Пользователь не найден' });
    if (user.status !== 'approved' && user.role !== 'superadmin') {
      return res.status(403).json({ error: 'Аккаунт еще не одобрен администратором', status: user.status });
    }
    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Неверный или устаревший токен' });
  }
}

// Superadmin and Admin check
function requireAdmin(req, res, next) {
  if (req.user.role !== 'superadmin' && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Доступ запрещен. Только для администратора.' });
  }
  next();
}

// Helper: Format User (Hide email and phone from ordinary users)
function sanitizeUser(user, isViewerAdmin = false, isSelf = false) {
  if (!user) return null;
  const sanitized = {
    id: user.id,
    name: user.name,
    username: user.username,
    avatar: user.avatar,
    bio: user.bio,
    role: user.role,
    status: user.status,
    last_seen: user.last_seen
  };
  if (isViewerAdmin || isSelf) {
    sanitized.email = user.email;
    sanitized.phone = user.phone;
    sanitized.created_at = user.created_at;
  }
  return sanitized;
}

function escapeTgHtml(str) {
  if (!str) return '';
  return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// ----------------------------------------------------
// AUTH ROUTES
// ----------------------------------------------------

// Register
app.post('/api/auth/register', (req, res) => {
  const { name, email, phone, username, password } = req.body;
  if (!name || !email || !phone || !password) {
    return res.status(400).json({ error: 'Заполните все обязательные поля (Имя, Email, Телефон, Пароль)' });
  }

  let finalUsername = username ? username.trim().toLowerCase().replace(/^@/, '') : email.split('@')[0].toLowerCase().replace(/[^a-z0-9_]/g, '');
  if (!finalUsername) finalUsername = 'user_' + Math.floor(Math.random() * 10000);

  const existing = db.prepare('SELECT email, username FROM users WHERE email = ? OR username = ?').get(email.trim().toLowerCase(), finalUsername);
  if (existing) {
    if (existing.email === email.trim().toLowerCase()) {
      return res.status(400).json({ error: 'Пользователь с таким email уже зарегистрирован' });
    }
    if (existing.username === finalUsername) {
      return res.status(400).json({ error: 'Логин @' + finalUsername + ' уже занят. Выберите другой.' });
    }
  }

  const salt = bcrypt.genSaltSync(10);
  const password_hash = bcrypt.hashSync(password, salt);

  try {
    const info = db.prepare(`
      INSERT INTO users (name, username, email, phone, password_hash, role, status)
      VALUES (?, ?, ?, ?, ?, 'user', 'pending')
    `).run(name.trim(), finalUsername, email.trim().toLowerCase(), phone.trim(), password_hash);

    const newUserId = info.lastInsertRowid;

    io.emit('new_pending_user', {
      id: newUserId,
      name: name.trim(),
      username: finalUsername,
      email: email.trim().toLowerCase(),
      phone: phone.trim()
    });

    const tgMsg = `🔔 <b>Новая заявка на регистрацию в GIN-Chat!</b>\n\n` +
                  `👤 <b>Имя:</b> ${escapeTgHtml(name.trim())}\n` +
                  `🏷 <b>Логин:</b> @${escapeTgHtml(finalUsername)}\n` +
                  `📧 <b>Email:</b> <code>${escapeTgHtml(email.trim().toLowerCase())}</code>\n` +
                  `📱 <b>Телефон:</b> <code>${escapeTgHtml(phone.trim())}</code>\n` +
                  `📅 <b>Дата:</b> ${new Date().toLocaleString('ru-RU', { timeZone: 'Europe/Prague' })}\n\n` +
                  `👉 <i>Выберите действие прямо в Telegram или откройте панель:</i>`;

    sendTelegramNotification(tgMsg, {
      inline_keyboard: [
        [
          { text: '✅ Одобрить', callback_data: `approve_${newUserId}` },
          { text: '⏸ Блокировать', callback_data: `ban_${newUserId}` },
          { text: '🗑 Удалить', callback_data: `delete_${newUserId}` }
        ],
        [
          { text: '🌐 Открыть GIN-Chat', url: 'https://4at.gincz.com' }
        ]
      ]
    });

    res.json({
      success: true,
      message: 'Заявка на регистрацию отправлена! Дождитесь одобрения администратором (Владимиром).',
      status: 'pending',
      username: finalUsername
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Ошибка базы данных при регистрации' });
  }
});

// Login
app.post('/api/auth/login', (req, res) => {
  const { login, password } = req.body;
  if (!login || !password) {
    return res.status(400).json({ error: 'Введите логин/email и пароль' });
  }

  const rawLogin = login.trim().toLowerCase();
  const cleanUsername = rawLogin.replace(/^@/, '');
  const user = db.prepare(`
    SELECT * FROM users 
    WHERE LOWER(username) = ? 
       OR LOWER(email) = ? 
       OR LOWER(username) = ?
  `).get(cleanUsername, rawLogin, cleanUsername.replace(/[^a-z0-9_]/g, ''));

  if (!user) {
    return res.status(400).json({ error: 'Пользователь не найден' });
  }

  const isMatch = bcrypt.compareSync(password, user.password_hash);
  if (!isMatch) {
    return res.status(400).json({ error: 'Неверный пароль' });
  }

  if (user.status === 'pending' && user.role !== 'superadmin') {
    return res.status(403).json({
      error: 'Ваш аккаунт находится на проверке у администратора (Владимира). Вы получите доступ сразу после одобрения.',
      status: 'pending'
    });
  }

  if (user.status === 'banned' || user.status === 'rejected') {
    return res.status(403).json({ error: 'Ваш аккаунт заблокирован или отклонен администратором.', status: user.status });
  }

  db.prepare("UPDATE users SET last_seen = CURRENT_TIMESTAMP WHERE id = ?").run(user.id);
  const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '30d' });

  res.json({
    success: true,
    token,
    user: sanitizeUser(user, user.role === 'superadmin', true)
  });
});

// Get Current User Profile
app.get('/api/auth/me', authMiddleware, (req, res) => {
  res.json({
    user: sanitizeUser(req.user, req.user.role === 'superadmin', true)
  });
});

// Update Profile
app.put('/api/auth/profile', authMiddleware, (req, res) => {
  const { name, username, email, phone, bio, avatar, oldPassword, newPassword } = req.body;
  const userId = req.user.id;

  let finalUsername = req.user.username;
  if (username && username.trim().toLowerCase() !== req.user.username.toLowerCase()) {
    finalUsername = username.trim().toLowerCase().replace(/^@/, '').replace(/[^a-z0-9_.-]/g, '');
    if (!finalUsername) finalUsername = req.user.username;
    const taken = db.prepare('SELECT id FROM users WHERE LOWER(username) = ? AND id != ?').get(finalUsername, userId);
    if (taken) {
      return res.status(400).json({ error: 'Логин @' + finalUsername + ' уже занят' });
    }
  }

  let finalEmail = req.user.email;
  if (email && email.trim().toLowerCase() !== (req.user.email || '').toLowerCase()) {
    finalEmail = email.trim().toLowerCase();
    const takenEmail = db.prepare('SELECT id FROM users WHERE LOWER(email) = ? AND id != ?').get(finalEmail, userId);
    if (takenEmail) {
      return res.status(400).json({ error: 'Email ' + finalEmail + ' уже используется другим аккаунтом' });
    }
  }

  let finalPhone = phone !== undefined ? phone.trim() : req.user.phone;
  let finalName = name ? name.trim() : req.user.name;
  let finalBio = bio !== undefined ? bio.trim() : req.user.bio;
  let finalAvatar = avatar !== undefined ? avatar : req.user.avatar;

  if (newPassword) {
    if (!oldPassword) return res.status(400).json({ error: 'Укажите текущий пароль для смены пароля' });
    const fullUser = db.prepare('SELECT password_hash FROM users WHERE id = ?').get(userId);
    if (!bcrypt.compareSync(oldPassword, fullUser.password_hash)) {
      return res.status(400).json({ error: 'Текущий пароль неверен' });
    }
    const hash = bcrypt.hashSync(newPassword, bcrypt.genSaltSync(10));
    db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(hash, userId);
  }

  db.prepare(`
    UPDATE users SET name = ?, username = ?, email = ?, phone = ?, bio = ?, avatar = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?
  `).run(finalName, finalUsername, finalEmail, finalPhone, finalBio, finalAvatar, userId);

  const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
  res.json({ success: true, user: sanitizeUser(updated, updated.role === 'superadmin' || updated.role === 'admin', true) });
});

// ----------------------------------------------------
// ADMIN ROUTES (Владимир and Admins)
// ----------------------------------------------------

// List all users
app.get('/api/admin/users', authMiddleware, requireAdmin, (req, res) => {
  const users = db.prepare(`
    SELECT id, name, username, email, phone, role, status, avatar, bio, last_seen, created_at
    FROM users
    ORDER BY CASE status WHEN 'pending' THEN 0 ELSE 1 END, id DESC
  `).all();
  res.json({ users });
});

// Get single user details by ID
app.get('/api/admin/users/:id', authMiddleware, requireAdmin, (req, res) => {
  const targetId = req.params.id;
  const user = db.prepare('SELECT id, name, username, email, phone, role, status, avatar, bio, last_seen, created_at FROM users WHERE id = ?').get(targetId);
  if (!user) return res.status(404).json({ error: 'Пользователь не найден' });
  res.json({ success: true, user: sanitizeUser(user, true, true) });
});

// Admin Update Any User Profile
app.put('/api/admin/users/:id', authMiddleware, requireAdmin, (req, res) => {
  const targetId = req.params.id;
  const { name, username, email, phone, bio, role, status, newPassword, avatar } = req.body;

  const target = db.prepare('SELECT * FROM users WHERE id = ?').get(targetId);
  if (!target) return res.status(404).json({ error: 'Пользователь не найден' });

  let finalUsername = target.username;
  if (username && username.trim().toLowerCase() !== target.username.toLowerCase()) {
    finalUsername = username.trim().toLowerCase().replace(/^@/, '').replace(/[^a-z0-9_.-]/g, '');
    if (!finalUsername) finalUsername = target.username;
    const taken = db.prepare('SELECT id FROM users WHERE LOWER(username) = ? AND id != ?').get(finalUsername, targetId);
    if (taken) {
      return res.status(400).json({ error: 'Логин @' + finalUsername + ' уже занят' });
    }
  }

  let finalEmail = target.email;
  if (email && email.trim().toLowerCase() !== (target.email || '').toLowerCase()) {
    finalEmail = email.trim().toLowerCase();
    const takenEmail = db.prepare('SELECT id FROM users WHERE LOWER(email) = ? AND id != ?').get(finalEmail, targetId);
    if (takenEmail) {
      return res.status(400).json({ error: 'Email ' + finalEmail + ' уже используется другим аккаунтом' });
    }
  }

  let finalName = name ? name.trim() : target.name;
  let finalPhone = phone !== undefined ? phone.trim() : target.phone;
  let finalBio = bio !== undefined ? bio.trim() : target.bio;
  let finalRole = role && ['user', 'admin', 'superadmin'].includes(role) ? role : target.role;
  let finalStatus = status && ['approved', 'pending', 'rejected', 'banned'].includes(status) ? status : target.status;
  let finalAvatar = avatar !== undefined ? (avatar ? avatar.trim() : null) : target.avatar;

  if (newPassword && newPassword.trim().length >= 6) {
    const salt = bcrypt.genSaltSync(10);
    const hash = bcrypt.hashSync(newPassword.trim(), salt);
    db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(hash, targetId);
  }

  db.prepare(`
    UPDATE users 
    SET name = ?, username = ?, email = ?, phone = ?, bio = ?, role = ?, status = ?, avatar = ?, updated_at = CURRENT_TIMESTAMP 
    WHERE id = ?
  `).run(finalName, finalUsername, finalEmail, finalPhone, finalBio, finalRole, finalStatus, finalAvatar, targetId);

  const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(targetId);
  sendTelegramNotification(`✏️ <b>Администратор обновил данные:</b> ${escapeTgHtml(finalName)} (@${escapeTgHtml(finalUsername)})\nEmail: ${escapeTgHtml(finalEmail)} | Тел: ${escapeTgHtml(finalPhone)} | Роль: ${finalRole}`);
  res.json({ success: true, user: sanitizeUser(updated, true, true) });
});

// Approve User
app.post('/api/admin/users/:id/approve', authMiddleware, requireAdmin, (req, res) => {
  const userId = req.params.id;
  db.prepare("UPDATE users SET status = 'approved', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(userId);
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
  
  io.emit('user_approved', { userId: Number(userId), username: user.username });
  sendTelegramNotification(`✅ <b>Пользователь одобрен:</b> ${escapeTgHtml(user.name)} (@${escapeTgHtml(user.username)})\nТеперь пользователь может войти в GIN-Chat.`);

  res.json({ success: true, user: sanitizeUser(user, true, false) });
});

// Admin Reset User Password
app.post('/api/admin/users/:id/password', authMiddleware, requireAdmin, (req, res) => {
  const userId = req.params.id;
  const { newPassword } = req.body;
  if (!newPassword || newPassword.trim().length < 6) {
    return res.status(400).json({ error: 'Пароль должен содержать минимум 6 символов' });
  }

  const user = db.prepare('SELECT id, name, username FROM users WHERE id = ?').get(userId);
  if (!user) return res.status(404).json({ error: 'Пользователь не найден' });

  const salt = bcrypt.genSaltSync(10);
  const hash = bcrypt.hashSync(newPassword.trim(), salt);
  db.prepare('UPDATE users SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(hash, userId);

  sendTelegramNotification(`🔑 <b>Администратор сменил пароль для:</b> ${escapeTgHtml(user.name)} (@${escapeTgHtml(user.username)})\nНовый пароль установлен.`);

  res.json({ success: true, message: `Пароль для @${user.username} успешно изменен!` });
});

// Reject / Ban User
app.post('/api/admin/users/:id/status', authMiddleware, requireAdmin, (req, res) => {
  const userId = req.params.id;
  const { status } = req.body;
  if (!['approved', 'rejected', 'banned', 'pending'].includes(status)) {
    return res.status(400).json({ error: 'Неверный статус' });
  }
  db.prepare("UPDATE users SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(status, userId);
  io.emit('user_status_changed', { userId: Number(userId), status });
  res.json({ success: true, status });
});

// Delete User
app.delete('/api/admin/users/:id', authMiddleware, requireAdmin, (req, res) => {
  const userId = req.params.id;
  if (Number(userId) === req.user.id) {
    return res.status(400).json({ error: 'Нельзя удалить свой собственный аккаунт' });
  }
  db.prepare('DELETE FROM users WHERE id = ?').run(userId);
  io.emit('user_deleted', { userId: Number(userId) });
  res.json({ success: true, message: 'Пользователь удален' });
});

// Admin Stats
app.get('/api/admin/stats', authMiddleware, requireAdmin, (req, res) => {
  const totalUsers = db.prepare("SELECT COUNT(*) as c FROM users").get().c;
  const pendingUsers = db.prepare("SELECT COUNT(*) as c FROM users WHERE status = 'pending'").get().c;
  const approvedUsers = db.prepare("SELECT COUNT(*) as c FROM users WHERE status = 'approved'").get().c;
  const totalMessages = db.prepare("SELECT COUNT(*) as c FROM messages").get().c;
  const totalChats = db.prepare("SELECT COUNT(*) as c FROM chats").get().c;
  const totalFiles = db.prepare("SELECT COUNT(*) as c FROM messages WHERE file_url IS NOT NULL").get().c;

  res.json({
    totalUsers,
    pendingUsers,
    approvedUsers,
    totalMessages,
    totalChats,
    totalFiles
  });
});

// ----------------------------------------------------
// CHATS & GROUPS ROUTES
// ----------------------------------------------------

// Get user's active chats list
app.get('/api/chats', authMiddleware, (req, res) => {
  const userId = req.user.id;
  
  const chats = db.prepare(`
    SELECT c.id, c.type, c.name, c.description, c.avatar, c.created_by, c.invite_code, c.pinned_message_id, c.updated_at,
           cm.role as my_role
    FROM chats c
    JOIN chat_members cm ON c.id = cm.chat_id
    WHERE cm.user_id = ?
    ORDER BY c.updated_at DESC
  `).all(userId);

  const enrichedChats = chats.map(chat => {
    let chatName = chat.name;
    let chatAvatar = chat.avatar;
    let partner = null;

    if (chat.type === 'direct') {
      const otherMember = db.prepare(`
        SELECT u.id, u.name, u.username, u.avatar, u.last_seen
        FROM chat_members cm
        JOIN users u ON cm.user_id = u.id
        WHERE cm.chat_id = ? AND cm.user_id != ?
      `).get(chat.id, userId);

      if (otherMember) {
        partner = otherMember;
        chatName = otherMember.name;
        chatAvatar = otherMember.avatar;
      } else {
        const selfMember = db.prepare(`SELECT id, name, username, avatar, last_seen FROM users WHERE id = ?`).get(userId);
        partner = selfMember;
        chatName = 'Избранное (Заметки)';
      }
    }

    const lastMsg = db.prepare(`
      SELECT m.id, m.sender_id, m.text_encrypted, m.type, m.file_name, m.created_at, u.name as sender_name
      FROM messages m
      LEFT JOIN users u ON m.sender_id = u.id
      WHERE m.chat_id = ? AND (m.scheduled_at IS NULL OR m.scheduled_at <= CURRENT_TIMESTAMP)
      ORDER BY m.id DESC LIMIT 1
    `).get(chat.id);

    const unread = db.prepare(`
      SELECT COUNT(*) as c
      FROM messages m
      LEFT JOIN message_reads mr ON m.id = mr.message_id AND mr.user_id = ?
      WHERE m.chat_id = ? AND m.sender_id != ? AND mr.read_at IS NULL AND (m.scheduled_at IS NULL OR m.scheduled_at <= CURRENT_TIMESTAMP)
    `).get(userId, chat.id, userId).c;

    let decryptedLastText = '';
    if (lastMsg) {
      if (lastMsg.type === 'text') {
        decryptedLastText = decryptText(lastMsg.text_encrypted);
      } else if (lastMsg.type === 'voice') {
        decryptedLastText = '🎙 Голосовое сообщение';
      } else if (lastMsg.type === 'image') {
        decryptedLastText = '🖼 Фотография';
      } else {
        decryptedLastText = '📎 ' + (lastMsg.file_name || 'Файл');
      }
    }

    return {
      ...chat,
      name: chatName || (partner ? partner.name : 'Личный диалог'),
      avatar: chatAvatar || (partner ? partner.avatar : null),
      partner,
      lastMessage: lastMsg ? {
        id: lastMsg.id,
        sender_id: lastMsg.sender_id,
        sender_name: lastMsg.sender_name,
        type: lastMsg.type,
        text: decryptedLastText,
        created_at: lastMsg.created_at
      } : null,
      unreadCount: unread
    };
  });

  res.json({ chats: enrichedChats });
});

// Start or find Direct 1-to-1 Chat
app.post('/api/chats/direct', authMiddleware, (req, res) => {
  const { targetUserId, targetUsername } = req.body;
  const myId = req.user.id;

  let targetUser;
  if (targetUserId) {
    targetUser = db.prepare('SELECT id, name, username, avatar FROM users WHERE id = ?').get(targetUserId);
  } else if (targetUsername) {
    const clean = targetUsername.trim().toLowerCase().replace(/^@/, '');
    targetUser = db.prepare('SELECT id, name, username, avatar FROM users WHERE username = ?').get(clean);
  }

  if (!targetUser) {
    return res.status(404).json({ error: 'Пользователь не найден' });
  }

  const existingChat = db.prepare(`
    SELECT c.id FROM chats c
    JOIN chat_members cm1 ON c.id = cm1.chat_id AND cm1.user_id = ?
    JOIN chat_members cm2 ON c.id = cm2.chat_id AND cm2.user_id = ?
    WHERE c.type = 'direct'
  `).get(myId, targetUser.id);

  if (existingChat) {
    return res.json({ chatId: existingChat.id, isNew: false, targetUser });
  }

  const transaction = db.transaction(() => {
    const info = db.prepare(`
      INSERT INTO chats (type, created_by) VALUES ('direct', ?)
    `).run(myId);
    const chatId = info.lastInsertRowid;

    db.prepare(`INSERT INTO chat_members (chat_id, user_id, role) VALUES (?, ?, 'member')`).run(chatId, myId);
    if (myId !== targetUser.id) {
      db.prepare(`INSERT INTO chat_members (chat_id, user_id, role) VALUES (?, ?, 'member')`).run(chatId, targetUser.id);
    }
    return chatId;
  });

  const newChatId = transaction();
  res.json({ chatId: newChatId, isNew: true, targetUser });
});

// Create Group Chat
app.post('/api/chats/group', authMiddleware, (req, res) => {
  const { name, description, avatar, memberIds } = req.body;
  const myId = req.user.id;

  if (!name || !name.trim()) {
    return res.status(400).json({ error: 'Укажите название группы' });
  }

  const inviteCode = crypto.randomBytes(8).toString('hex');

  const transaction = db.transaction(() => {
    const info = db.prepare(`
      INSERT INTO chats (type, name, description, avatar, created_by, invite_code)
      VALUES ('group', ?, ?, ?, ?, ?)
    `).run(name.trim(), description || '', avatar || null, myId, inviteCode);
    
    const chatId = info.lastInsertRowid;
    db.prepare(`INSERT INTO chat_members (chat_id, user_id, role) VALUES (?, ?, 'owner')`).run(chatId, myId);

    if (Array.isArray(memberIds)) {
      const addStmt = db.prepare(`INSERT OR IGNORE INTO chat_members (chat_id, user_id, role) VALUES (?, ?, 'member')`);
      for (const uid of memberIds) {
        if (uid !== myId) {
          addStmt.run(chatId, uid);
        }
      }
    }

    return chatId;
  });

  const chatId = transaction();
  
  // Notify all added members
  const allMembers = [myId, ...(Array.isArray(memberIds) ? memberIds : [])];
  allMembers.forEach(uid => {
    io.to('user_' + uid).emit('new_chat_created', { chatId, name: name.trim(), type: 'group' });
  });

  res.json({ success: true, chatId, inviteCode });
});

// Get Chat Details and Members
app.get('/api/chats/:id', authMiddleware, (req, res) => {
  const chatId = req.params.id;
  const userId = req.user.id;

  const memberRecord = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, userId);
  if (!memberRecord && req.user.role !== 'superadmin') {
    return res.status(403).json({ error: 'Вы не являетесь участником этого чата' });
  }

  const chat = db.prepare('SELECT * FROM chats WHERE id = ?').get(chatId);
  if (!chat) return res.status(404).json({ error: 'Чат не найден' });

  let enrichedChat = { ...chat };
  if (chat.type === 'direct') {
    const otherMember = db.prepare(`
      SELECT u.id, u.name, u.username, u.avatar, u.last_seen
      FROM chat_members cm
      JOIN users u ON cm.user_id = u.id
      WHERE cm.chat_id = ? AND cm.user_id != ?
    `).get(chatId, userId) || db.prepare(`
      SELECT u.id, u.name, u.username, u.avatar, u.last_seen
      FROM chat_members cm
      JOIN users u ON cm.user_id = u.id
      WHERE cm.chat_id = ?
    `).get(chatId);

    if (otherMember) {
      enrichedChat.name = otherMember.name;
      enrichedChat.avatar = otherMember.avatar;
      enrichedChat.partner = otherMember;
    } else {
      enrichedChat.name = 'Личный диалог';
    }
  }

  const members = db.prepare(`
    SELECT u.id, u.name, u.username, u.avatar, u.last_seen, cm.role, cm.joined_at
    FROM chat_members cm
    JOIN users u ON cm.user_id = u.id
    WHERE cm.chat_id = ?
    ORDER BY CASE cm.role WHEN 'owner' THEN 1 WHEN 'admin' THEN 2 ELSE 3 END, u.name ASC
  `).all(chatId);

  let pinnedMessage = null;
  if (chat.pinned_message_id) {
    const pin = db.prepare(`
      SELECT m.id, m.sender_id, m.text_encrypted, m.type, m.file_name, u.name as sender_name
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.id = ?
    `).get(chat.pinned_message_id);
    if (pin) {
      pinnedMessage = {
        ...pin,
        text: pin.type === 'text' ? decryptText(pin.text_encrypted) : pin.file_name || pin.type
      };
    }
  }

  res.json({
    chat: enrichedChat,
    myRole: memberRecord ? memberRecord.role : 'superadmin',
    members,
    pinnedMessage
  });
});

// Update Group Info
app.put('/api/chats/:id', authMiddleware, (req, res) => {
  const chatId = req.params.id;
  const userId = req.user.id;
  const { name, description, avatar } = req.body;

  const currentChat = db.prepare('SELECT * FROM chats WHERE id = ?').get(chatId);
  if (!currentChat) return res.status(404).json({ error: 'Чат не найден' });

  const member = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, userId);
  if ((!member || (member.role !== 'owner' && member.role !== 'admin')) && req.user.role !== 'superadmin') {
    return res.status(403).json({ error: 'У вас нет прав администратора этой группы' });
  }

  const finalName = (name !== undefined && name.trim()) ? name.trim() : currentChat.name;
  const finalDesc = description !== undefined ? description : currentChat.description;
  const finalAvatar = avatar !== undefined ? avatar : currentChat.avatar;

  db.prepare(`
    UPDATE chats SET name = ?, description = ?, avatar = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?
  `).run(finalName, finalDesc, finalAvatar, chatId);

  io.to('chat_' + chatId).emit('chat_info_updated', { chatId, name: finalName, description: finalDesc, avatar: finalAvatar });
  res.json({ success: true, chat: { id: chatId, name: finalName, description: finalDesc, avatar: finalAvatar } });
});

// Assign or Revoke Group Admin role
app.post('/api/chats/:id/admin/:targetUserId', authMiddleware, (req, res) => {
  const { id: chatId, targetUserId } = req.params;
  const { role } = req.body;
  const myId = req.user.id;

  const member = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, myId);
  if ((!member || member.role !== 'owner') && req.user.role !== 'superadmin') {
    return res.status(403).json({ error: 'Только владелец группы или супер-администратор может назначать администраторов' });
  }

  db.prepare('UPDATE chat_members SET role = ? WHERE chat_id = ? AND user_id = ?').run(role, chatId, targetUserId);
  io.to('chat_' + chatId).emit('member_role_changed', { chatId, userId: Number(targetUserId), role });
  res.json({ success: true, role });
});

// Add Members to Group
app.post('/api/chats/:id/members', authMiddleware, (req, res) => {
  const chatId = req.params.id;
  const { userIds } = req.body;
  const myId = req.user.id;

  const member = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, myId);
  if ((!member || (member.role !== 'owner' && member.role !== 'admin')) && req.user.role !== 'superadmin') {
    return res.status(403).json({ error: 'Только администратор группы может добавлять участников' });
  }

  const addStmt = db.prepare(`INSERT OR IGNORE INTO chat_members (chat_id, user_id, role) VALUES (?, ?, 'member')`);
  for (const uid of userIds) {
    addStmt.run(chatId, uid);
  }

  io.to('chat_' + chatId).emit('members_added', { chatId, userIds });
  res.json({ success: true });
});

// Remove Member from Group
app.delete('/api/chats/:id/members/:targetUserId', authMiddleware, (req, res) => {
  const { id: chatId, targetUserId } = req.params;
  const myId = req.user.id;

  const member = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, myId);
  const target = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, targetUserId);

  const canRemove = (Number(targetUserId) === myId) || 
                    (member && member.role === 'owner') ||
                    (member && member.role === 'admin' && target && target.role === 'member') ||
                    (req.user.role === 'superadmin');

  if (!canRemove) {
    return res.status(403).json({ error: 'Недостаточно прав для удаления этого участника' });
  }

  db.prepare('DELETE FROM chat_members WHERE chat_id = ? AND user_id = ?').run(chatId, targetUserId);
  io.to('chat_' + chatId).emit('member_removed', { chatId, userId: Number(targetUserId) });
  res.json({ success: true });
});

// Generate Invite Link for Group
app.post('/api/chats/:id/invite', authMiddleware, (req, res) => {
  const chatId = req.params.id;
  const myId = req.user.id;

  const member = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, myId);
  if ((!member || (member.role !== 'owner' && member.role !== 'admin')) && req.user.role !== 'superadmin') {
    return res.status(403).json({ error: 'Только администраторы группы могут создавать инвайт-ссылки' });
  }

  const newCode = crypto.randomBytes(8).toString('hex');
  db.prepare('UPDATE chats SET invite_code = ? WHERE id = ?').run(newCode, chatId);

  res.json({ success: true, inviteCode: newCode, inviteUrl: `/group/${newCode}` });
});

// Join Group by ID (Direct chat URL join)
app.post('/api/chats/:id/join', authMiddleware, (req, res) => {
  const chatId = req.params.id;
  const userId = req.user.id;

  const chat = db.prepare('SELECT * FROM chats WHERE id = ?').get(chatId);
  if (!chat) return res.status(404).json({ error: 'Чат не найден' });
  if (chat.type !== 'group' && req.user.role !== 'superadmin') {
    return res.status(400).json({ error: 'Присоединиться по ссылке можно только к группе' });
  }

  const existingMember = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, userId);
  if (!existingMember) {
    db.prepare(`INSERT INTO chat_members (chat_id, user_id, role) VALUES (?, ?, 'member')`).run(chatId, userId);
    db.prepare('UPDATE chats SET updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(chatId);

    const sysTextEncrypted = encryptText(`${req.user.name} присоединился к группе по ссылке`);
    db.prepare(`
      INSERT INTO messages (chat_id, sender_id, text_encrypted, type)
      VALUES (?, ?, ?, 'system')
    `).run(chatId, userId, sysTextEncrypted);

    io.to('chat_' + chatId).emit('member_joined', { chatId: Number(chatId), user: sanitizeUser(req.user) });
    io.emit('new_chat_created');

    // Notify all admins and owner of this group in real time
    const groupAdmins = db.prepare("SELECT user_id FROM chat_members WHERE chat_id = ? AND role IN ('owner', 'admin')").all(chatId);
    groupAdmins.forEach(adm => {
      io.to('user_' + adm.user_id).emit('group_join_notification', {
        chatId: Number(chatId),
        chatName: chat.name,
        joinedUser: sanitizeUser(req.user)
      });
    });

    sendTelegramNotification(
      `🔔 <b>Новый участник в группе «${escapeTgHtml(chat.name)}»:</b>\n` +
      `👤 <b>Имя:</b> ${escapeTgHtml(req.user.name)} (@${escapeTgHtml(req.user.username)})\n` +
      `Все администраторы группы оповещены.`
    );
  }

  res.json({ success: true, chatId: Number(chatId), name: chat.name });
});

// Join Group by Invite Code
app.post('/api/chats/join/:code', authMiddleware, (req, res) => {
  const code = req.params.code;
  const userId = req.user.id;

  const chat = db.prepare('SELECT * FROM chats WHERE invite_code = ?').get(code);
  if (!chat) return res.status(404).json({ error: 'Ссылка-приглашение недействительна или устарела' });

  const existingMember = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chat.id, userId);
  if (!existingMember) {
    db.prepare(`INSERT OR IGNORE INTO chat_members (chat_id, user_id, role) VALUES (?, ?, 'member')`).run(chat.id, userId);
    db.prepare('UPDATE chats SET updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(chat.id);

    const sysTextEncrypted = encryptText(`${req.user.name} присоединился к группе по ссылке`);
    db.prepare(`
      INSERT INTO messages (chat_id, sender_id, text_encrypted, type)
      VALUES (?, ?, ?, 'system')
    `).run(chat.id, userId, sysTextEncrypted);

    io.to('chat_' + chat.id).emit('member_joined', { chatId: chat.id, user: sanitizeUser(req.user) });
    io.emit('new_chat_created');

    // Notify all admins and owner of this group in real time
    const groupAdmins = db.prepare("SELECT user_id FROM chat_members WHERE chat_id = ? AND role IN ('owner', 'admin')").all(chat.id);
    groupAdmins.forEach(adm => {
      io.to('user_' + adm.user_id).emit('group_join_notification', {
        chatId: chat.id,
        chatName: chat.name,
        joinedUser: sanitizeUser(req.user)
      });
    });

    sendTelegramNotification(
      `🔔 <b>Новый участник в группе «${escapeTgHtml(chat.name)}»:</b>\n` +
      `👤 <b>Имя:</b> ${escapeTgHtml(req.user.name)} (@${escapeTgHtml(req.user.username)})\n` +
      `Все администраторы группы оповещены.`
    );
  }

  res.json({ success: true, chatId: chat.id, name: chat.name });
});

// ----------------------------------------------------
// USER REPORTS & COMPLAINTS (Пожаловаться)
// ----------------------------------------------------

// Submit a report on a user
app.post('/api/reports', authMiddleware, (req, res) => {
  const reporterId = req.user.id;
  const { reportedUserId, chatId, reasons, comment } = req.body;

  if (!reportedUserId) {
    return res.status(400).json({ error: 'Не указан пользователь' });
  }
  if (Number(reportedUserId) === Number(reporterId)) {
    return res.status(400).json({ error: 'Нельзя пожаловаться на самого себя' });
  }
  if (!reasons || !Array.isArray(reasons) || reasons.length === 0) {
    return res.status(400).json({ error: 'Выберите хотя бы одну причину жалобы' });
  }

  const targetUser = db.prepare('SELECT id, name, username, email, phone FROM users WHERE id = ?').get(reportedUserId);
  if (!targetUser) {
    return res.status(404).json({ error: 'Пользователь не найден' });
  }

  let chatName = 'Личные сообщения / Контакты';
  let groupAdmins = [];
  if (chatId) {
    const chat = db.prepare('SELECT id, name, type FROM chats WHERE id = ?').get(chatId);
    if (chat) {
      chatName = chat.name || 'Диалог';
      groupAdmins = db.prepare("SELECT user_id FROM chat_members WHERE chat_id = ? AND role IN ('owner', 'admin')").all(chatId);
    }
  }

  const reasonsJson = JSON.stringify(reasons);
  const info = db.prepare(`
    INSERT INTO reports (reporter_id, reported_user_id, chat_id, reasons, comment)
    VALUES (?, ?, ?, ?, ?)
  `).run(reporterId, reportedUserId, chatId || null, reasonsJson, comment ? comment.trim() : null);

  const reportId = info.lastInsertRowid;

  // Notify all system superadmins and group admins
  const systemAdmins = db.prepare("SELECT id FROM users WHERE role IN ('superadmin', 'admin')").all();
  const notifyUserIds = new Set([
    ...systemAdmins.map(a => a.id),
    ...groupAdmins.map(g => g.user_id)
  ]);

  const reportPayload = {
    id: reportId,
    reporter: { id: req.user.id, name: req.user.name, username: req.user.username },
    reported_user: { id: targetUser.id, name: targetUser.name, username: targetUser.username },
    chat: { id: chatId, name: chatName },
    reasons,
    comment: comment ? comment.trim() : '',
    created_at: new Date().toISOString()
  };

  notifyUserIds.forEach(uid => {
    io.to('user_' + uid).emit('new_report_alert', reportPayload);
  });

  // Detailed Telegram notification for admin
  const reasonsList = reasons.map(r => `• ${escapeTgHtml(r)}`).join('\n');
  sendTelegramNotification(
    `🚨 <b>НОВАЯ ЖАЛОБА НА ПОЛЬЗОВАТЕЛЯ!</b>\n` +
    `👤 <b>Нарушитель:</b> ${escapeTgHtml(targetUser.name)} (@${escapeTgHtml(targetUser.username)}) [ID: ${targetUser.id}]\n` +
    `👮 <b>Заявитель:</b> ${escapeTgHtml(req.user.name)} (@${escapeTgHtml(req.user.username)})\n` +
    `📌 <b>Контекст:</b> ${escapeTgHtml(chatName)}\n` +
    `📋 <b>Причины:</b>\n${reasonsList}\n` +
    `💬 <b>Комментарий:</b> ${escapeTgHtml(comment || '—')}`
  );

  res.json({ success: true, message: 'Жалоба успешно отправлена администраторам' });
});

// List all reports for Admin
app.get('/api/admin/reports', authMiddleware, requireAdmin, (req, res) => {
  const reports = db.prepare(`
    SELECT r.id, r.reporter_id, r.reported_user_id, r.chat_id, r.reasons, r.comment, r.status, r.created_at,
           u1.name as reporter_name, u1.username as reporter_username, u1.avatar as reporter_avatar,
           u2.name as reported_name, u2.username as reported_username, u2.avatar as reported_avatar, u2.status as reported_status,
           c.name as chat_name, c.type as chat_type
    FROM reports r
    LEFT JOIN users u1 ON r.reporter_id = u1.id
    LEFT JOIN users u2 ON r.reported_user_id = u2.id
    LEFT JOIN chats c ON r.chat_id = c.id
    ORDER BY CASE r.status WHEN 'pending' THEN 0 ELSE 1 END, r.id DESC
  `).all();

  const parsed = reports.map(r => ({
    ...r,
    reasons: (() => { try { return JSON.parse(r.reasons); } catch(e) { return [r.reasons]; } })()
  }));

  res.json({ reports: parsed });
});

// Update report status (resolve / dismiss)
app.post('/api/admin/reports/:id/status', authMiddleware, requireAdmin, (req, res) => {
  const reportId = req.params.id;
  const { status } = req.body;
  if (!['pending', 'resolved', 'dismissed'].includes(status)) {
    return res.status(400).json({ error: 'Неверный статус' });
  }
  db.prepare('UPDATE reports SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(status, reportId);
  res.json({ success: true });
});

// Ban user directly from report
app.post('/api/admin/reports/:id/ban', authMiddleware, requireAdmin, (req, res) => {
  const reportId = req.params.id;
  const report = db.prepare('SELECT reported_user_id FROM reports WHERE id = ?').get(reportId);
  if (!report) return res.status(404).json({ error: 'Жалоба не найдена' });

  db.prepare("UPDATE users SET status = 'banned', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(report.reported_user_id);
  db.prepare("UPDATE reports SET status = 'resolved', updated_at = CURRENT_TIMESTAMP WHERE id = ?").run(reportId);

  io.to('user_' + report.reported_user_id).emit('user_banned');
  sendTelegramNotification(`🚫 <b>Пользователь заблокирован по жалобе #${reportId}!</b>`);
  res.json({ success: true });
});

// Pin / Unpin Message
app.post('/api/chats/:id/pin/:messageId', authMiddleware, (req, res) => {
  const { id: chatId, messageId } = req.params;
  const myId = req.user.id;

  const member = db.prepare('SELECT role FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, myId);
  if ((!member || (member.role !== 'owner' && member.role !== 'admin')) && req.user.role !== 'superadmin') {
    return res.status(403).json({ error: 'Только администратор группы может закреплять сообщения' });
  }

  const newPin = messageId === '0' || messageId === 'null' ? null : Number(messageId);
  db.prepare('UPDATE chats SET pinned_message_id = ? WHERE id = ?').run(newPin, chatId);

  io.to('chat_' + chatId).emit('message_pinned', { chatId, messageId: newPin });
  res.json({ success: true, pinnedMessageId: newPin });
});

// ----------------------------------------------------
// MESSAGES, REACTIONS, EDIT & DELETE ROUTES
// ----------------------------------------------------

// Get Messages for Chat
app.get('/api/chats/:id/messages', authMiddleware, (req, res) => {
  const chatId = req.params.id;
  const userId = req.user.id;
  const limit = parseInt(req.query.limit) || 150;
  const beforeId = req.query.beforeId ? parseInt(req.query.beforeId) : null;

  const member = db.prepare('SELECT 1 FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, userId);
  if (!member && req.user.role !== 'superadmin') {
    return res.status(403).json({ error: 'Вы не состоите в этом чате' });
  }

  let query = `
    SELECT m.*, u.name as sender_name, u.username as sender_username, u.avatar as sender_avatar,
           ru.name as reply_sender_name, r.text_encrypted as reply_text_encrypted, r.type as reply_type
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    LEFT JOIN messages r ON m.reply_to_id = r.id
    LEFT JOIN users ru ON r.sender_id = ru.id
    WHERE m.chat_id = ? AND (m.scheduled_at IS NULL OR m.scheduled_at <= CURRENT_TIMESTAMP)
  `;
  const params = [chatId];

  if (beforeId) {
    query += ` AND m.id < ?`;
    params.push(beforeId);
  }

  query += ` ORDER BY m.id DESC LIMIT ?`;
  params.push(limit);

  const rawMessages = db.prepare(query).all(...params);

  db.exec(`
    INSERT OR IGNORE INTO message_reads (message_id, user_id)
    SELECT id, ${userId} FROM messages WHERE chat_id = ${chatId} AND sender_id != ${userId}
  `);

  const messageIds = rawMessages.map(m => m.id);
  let reactionsMap = {};
  if (messageIds.length > 0) {
    const reactions = db.prepare(`
      SELECT r.message_id, r.emoji, r.user_id, u.name as user_name
      FROM reactions r
      JOIN users u ON r.user_id = u.id
      WHERE r.message_id IN (${messageIds.join(',')})
    `).all();

    for (const r of reactions) {
      if (!reactionsMap[r.message_id]) reactionsMap[r.message_id] = {};
      if (!reactionsMap[r.message_id][r.emoji]) reactionsMap[r.message_id][r.emoji] = [];
      reactionsMap[r.message_id][r.emoji].push({ userId: r.user_id, name: r.user_name });
    }
  }

  const messages = rawMessages.reverse().map(m => {
    return {
      id: m.id,
      chat_id: m.chat_id,
      sender_id: m.sender_id,
      sender: {
        id: m.sender_id,
        name: m.sender_name,
        username: m.sender_username,
        avatar: m.sender_avatar
      },
      text: m.type === 'text' ? decryptText(m.text_encrypted) : '',
      type: m.type,
      file_url: m.file_url,
      file_name: m.file_name,
      file_size: m.file_size,
      file_duration: m.file_duration,
      reply_to: m.reply_to_id ? {
        id: m.reply_to_id,
        sender_name: m.reply_sender_name,
        text: m.reply_type === 'text' ? decryptText(m.reply_text_encrypted) : m.reply_type
      } : null,
      reactions: reactionsMap[m.id] || {},
      is_edited: !!m.is_edited,
      created_at: m.created_at
    };
  });

  res.json({ messages });
});

// Edit Message (Author or Admin)
app.put('/api/chats/:chatId/messages/:messageId', authMiddleware, (req, res) => {
  const { chatId, messageId } = req.params;
  const { text } = req.body;
  const userId = req.user.id;

  if (!text || !text.trim()) {
    return res.status(400).json({ error: 'Текст сообщения не может быть пустым' });
  }

  const msg = db.prepare('SELECT * FROM messages WHERE id = ? AND chat_id = ?').get(messageId, chatId);
  if (!msg) return res.status(404).json({ error: 'Сообщение не найдено' });

  const canEdit = (msg.sender_id === userId) || (req.user.role === 'superadmin') || (req.user.role === 'admin');
  if (!canEdit) {
    return res.status(403).json({ error: 'У вас нет прав на редактирование этого сообщения' });
  }

  const encryptedText = encryptText(text.trim());
  db.prepare(`
    UPDATE messages 
    SET text_encrypted = ?, is_edited = 1, updated_at = CURRENT_TIMESTAMP 
    WHERE id = ?
  `).run(encryptedText, messageId);

  io.to('chat_' + chatId).emit('message_edited', {
    chatId: Number(chatId),
    messageId: Number(messageId),
    text: text.trim(),
    is_edited: true
  });

  res.json({ success: true, messageId: Number(messageId), text: text.trim() });
});

// Delete Message (Author or Admin)
app.delete('/api/chats/:chatId/messages/:messageId', authMiddleware, (req, res) => {
  const { chatId, messageId } = req.params;
  const userId = req.user.id;

  const msg = db.prepare('SELECT * FROM messages WHERE id = ? AND chat_id = ?').get(messageId, chatId);
  if (!msg) return res.status(404).json({ error: 'Сообщение не найдено' });

  const canDelete = (msg.sender_id === userId) || (req.user.role === 'superadmin') || (req.user.role === 'admin');
  if (!canDelete) {
    return res.status(403).json({ error: 'У вас нет прав на удаление этого сообщения' });
  }

  db.prepare('DELETE FROM messages WHERE id = ?').run(messageId);
  io.to('chat_' + chatId).emit('message_deleted', {
    chatId: Number(chatId),
    messageId: Number(messageId)
  });

  res.json({ success: true, messageId: Number(messageId) });
});

// Upload File / Voice / Image
app.post('/api/upload', authMiddleware, upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Файл не прикреплен' });

  const fileUrl = `/uploads/${req.file.filename}`;
  let type = 'file';

  if (req.file.mimetype.startsWith('image/')) {
    type = 'image';
  } else if (req.file.mimetype.startsWith('audio/') || req.file.originalname.endsWith('.webm') || req.file.originalname.endsWith('.ogg')) {
    type = 'voice';
  }

  res.json({
    url: fileUrl,
    type,
    name: req.file.originalname,
    size: req.file.size
  });
});

// Upload Avatar (WebP / JPEG / PNG)
app.post('/api/upload/avatar', authMiddleware, upload.single('avatar'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Файл аватара не прикреплен' });
  const avatarUrl = `/uploads/${req.file.filename}`;
  res.json({
    success: true,
    url: avatarUrl,
    size: req.file.size
  });
});

// Search Approved Users
app.get('/api/users/search', authMiddleware, (req, res) => {
  const myId = req.user.id;
  const q = req.query.q ? req.query.q.trim().toLowerCase().replace(/^@/, '') : '';

  let users;
  if (q) {
    users = db.prepare(`
      SELECT id, name, username, avatar, bio, last_seen
      FROM users
      WHERE status = 'approved' AND id != ? AND (LOWER(username) LIKE ? OR LOWER(name) LIKE ?)
      ORDER BY name ASC LIMIT 60
    `).all(myId, `%${q}%`, `%${q}%`);
  } else {
    users = db.prepare(`
      SELECT id, name, username, avatar, bio, last_seen
      FROM users
      WHERE status = 'approved' AND id != ?
      ORDER BY name ASC LIMIT 60
    `).all(myId);
  }

  res.json({ users });
});

// ----------------------------------------------------
// SCHEDULED MESSAGES WORKER (Delayed send)
// ----------------------------------------------------

setInterval(() => {
  try {
    const dueMessages = db.prepare(`
      SELECT m.*, u.name as sender_name, u.username as sender_username, u.avatar as sender_avatar
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.scheduled_at IS NOT NULL AND m.scheduled_at <= CURRENT_TIMESTAMP
    `).all();

    if (dueMessages.length > 0) {
      const updateStmt = db.prepare('UPDATE messages SET scheduled_at = NULL WHERE id = ?');
      for (const msg of dueMessages) {
        updateStmt.run(msg.id);
        db.prepare('UPDATE chats SET updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(msg.chat_id);

        let replyTo = null;
        if (msg.reply_to_id) {
          const replyMsg = db.prepare(`
            SELECT m.id, u.name as sender_name, m.text_encrypted, m.type
            FROM messages m JOIN users u ON m.sender_id = u.id WHERE m.id = ?
          `).get(msg.reply_to_id);
          if (replyMsg) {
            replyTo = {
              id: replyMsg.id,
              sender_name: replyMsg.sender_name,
              text: replyMsg.type === 'text' ? decryptText(replyMsg.text_encrypted) : replyMsg.type
            };
          }
        }

        const payload = {
          id: msg.id,
          chat_id: msg.chat_id,
          sender_id: msg.sender_id,
          sender: {
            id: msg.sender_id,
            name: msg.sender_name,
            username: msg.sender_username,
            avatar: msg.sender_avatar
          },
          text: msg.type === 'text' ? decryptText(msg.text_encrypted) : '',
          type: msg.type,
          file_url: msg.file_url,
          file_name: msg.file_name,
          file_size: msg.file_size,
          file_duration: msg.file_duration,
          reply_to: replyTo,
          reactions: {},
          is_edited: false,
          created_at: new Date().toISOString()
        };

        io.to('chat_' + msg.chat_id).emit('new_message', payload);
      }
    }
  } catch (err) {
    console.error('Scheduled messages worker error:', err);
  }
}, 5000);

// ----------------------------------------------------
// SOCKET.IO REAL-TIME LOGIC
// ----------------------------------------------------

const onlineUsers = new Map();

io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (!token) return next(new Error('Authentication error'));
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = db.prepare('SELECT id, name, username, role, status FROM users WHERE id = ?').get(decoded.id);
    if (!user || (user.status !== 'approved' && user.role !== 'superadmin')) {
      return next(new Error('User not approved'));
    }
    socket.user = user;
    next();
  } catch (err) {
    return next(new Error('Invalid token'));
  }
});

io.on('connection', (socket) => {
  const user = socket.user;
  const userId = user.id;

  if (!onlineUsers.has(userId)) {
    onlineUsers.set(userId, new Set());
    io.emit('user_status', { userId, status: 'online' });
  }
  onlineUsers.get(userId).add(socket.id);

  socket.join('user_' + userId);
  const userChats = db.prepare('SELECT chat_id FROM chat_members WHERE user_id = ?').all(userId);
  userChats.forEach(c => socket.join('chat_' + c.chat_id));

  socket.on('join_chat', ({ chatId }) => {
    socket.join('chat_' + chatId);
  });

  socket.on('send_message', async (data, callback) => {
    try {
      const { chatId, text, type = 'text', fileUrl, fileName, fileSize, fileDuration, replyToId, scheduledAt } = data;

      const member = db.prepare('SELECT 1 FROM chat_members WHERE chat_id = ? AND user_id = ?').get(chatId, userId);
      if (!member && user.role !== 'superadmin') {
        if (callback) callback({ error: 'Нет доступа к чату' });
        return;
      }

      const encryptedText = type === 'text' ? encryptText(text) : null;
      const scheduledValue = scheduledAt ? new Date(scheduledAt).toISOString().replace('T', ' ').substring(0, 19) : null;

      const info = db.prepare(`
        INSERT INTO messages (chat_id, sender_id, text_encrypted, reply_to_id, type, file_url, file_name, file_size, file_duration, scheduled_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(chatId, userId, encryptedText, replyToId || null, type, fileUrl || null, fileName || null, fileSize || null, fileDuration || null, scheduledValue);

      const messageId = info.lastInsertRowid;

      if (!scheduledValue) {
        db.prepare('UPDATE chats SET updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(chatId);

        const sender = db.prepare('SELECT id, name, username, avatar FROM users WHERE id = ?').get(userId);

        let replyTo = null;
        if (replyToId) {
          const replyMsg = db.prepare(`
            SELECT m.id, u.name as sender_name, m.text_encrypted, m.type
            FROM messages m JOIN users u ON m.sender_id = u.id WHERE m.id = ?
          `).get(replyToId);
          if (replyMsg) {
            replyTo = {
              id: replyMsg.id,
              sender_name: replyMsg.sender_name,
              text: replyMsg.type === 'text' ? decryptText(replyMsg.text_encrypted) : replyMsg.type
            };
          }
        }

        const messagePayload = {
          id: messageId,
          chat_id: chatId,
          sender_id: userId,
          sender,
          text: type === 'text' ? text : '',
          type,
          file_url: fileUrl,
          file_name: fileName,
          file_size: fileSize,
          file_duration: fileDuration,
          reply_to: replyTo,
          reactions: {},
          is_edited: false,
          created_at: new Date().toISOString()
        };

        io.to('chat_' + chatId).emit('new_message', messagePayload);
        if (callback) callback({ success: true, message: messagePayload });
      } else {
        if (callback) callback({ success: true, scheduled: true, scheduledAt: scheduledValue });
      }
    } catch (err) {
      console.error('Socket send_message error:', err);
      if (callback) callback({ error: 'Ошибка отправки' });
    }
  });

  socket.on('forward_message', async ({ messageId, targetChatIds }, callback) => {
    try {
      if (!targetChatIds || !Array.isArray(targetChatIds) || targetChatIds.length === 0) {
        if (callback) callback({ error: 'Не выбраны получатели' });
        return;
      }

      const origMsg = db.prepare('SELECT * FROM messages WHERE id = ?').get(messageId);
      if (!origMsg) {
        if (callback) callback({ error: 'Сообщение не найдено' });
        return;
      }

      const origSender = db.prepare('SELECT name, username FROM users WHERE id = ?').get(origMsg.sender_id);
      const origSenderName = origSender ? origSender.name : 'Пользователь';
      const textDecrypted = origMsg.type === 'text' && origMsg.text_encrypted ? decryptText(origMsg.text_encrypted) : '';
      const forwardText = origMsg.type === 'text' ? `↪️ Переслано от ${origSenderName}:\n${textDecrypted}` : (origMsg.text_encrypted ? decryptText(origMsg.text_encrypted) : null);
      const encryptedForwardText = forwardText ? encryptText(forwardText) : null;

      const sender = db.prepare('SELECT id, name, username, avatar FROM users WHERE id = ?').get(userId);
      let forwardedCount = 0;

      for (const targetChatId of targetChatIds) {
        const member = db.prepare('SELECT 1 FROM chat_members WHERE chat_id = ? AND user_id = ?').get(targetChatId, userId);
        if (!member && user.role !== 'superadmin') continue;

        const info = db.prepare(`
          INSERT INTO messages (chat_id, sender_id, text_encrypted, reply_to_id, type, file_url, file_name, file_size, file_duration)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(targetChatId, userId, encryptedForwardText, null, origMsg.type, origMsg.file_url, origMsg.file_name, origMsg.file_size, origMsg.file_duration);

        db.prepare('UPDATE chats SET updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(targetChatId);

        const messagePayload = {
          id: info.lastInsertRowid,
          chat_id: targetChatId,
          sender_id: userId,
          sender,
          text: forwardText || '',
          type: origMsg.type,
          file_url: origMsg.file_url,
          file_name: origMsg.file_name,
          file_size: origMsg.file_size,
          file_duration: origMsg.file_duration,
          reply_to: null,
          reactions: {},
          is_edited: false,
          created_at: new Date().toISOString()
        };

        io.to('chat_' + targetChatId).emit('new_message', messagePayload);
        forwardedCount++;
      }

      if (callback) callback({ success: true, count: forwardedCount });
    } catch (err) {
      console.error('Socket forward_message error:', err);
      if (callback) callback({ error: 'Ошибка пересылки сообщения' });
    }
  });

  socket.on('edit_message', ({ messageId, chatId, text }, callback) => {
    try {
      const msg = db.prepare('SELECT * FROM messages WHERE id = ? AND chat_id = ?').get(messageId, chatId);
      if (!msg) return callback && callback({ error: 'Сообщение не найдено' });

      if (msg.sender_id !== userId && user.role !== 'superadmin' && user.role !== 'admin') {
        return callback && callback({ error: 'Нет прав на редактирование' });
      }

      const encryptedText = encryptText(text.trim());
      db.prepare('UPDATE messages SET text_encrypted = ?, is_edited = 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(encryptedText, messageId);

      io.to('chat_' + chatId).emit('message_edited', {
        chatId: Number(chatId),
        messageId: Number(messageId),
        text: text.trim(),
        is_edited: true
      });
      if (callback) callback({ success: true });
    } catch (err) {
      if (callback) callback({ error: 'Ошибка сохранения' });
    }
  });

  socket.on('delete_message', ({ messageId, chatId }, callback) => {
    try {
      const msg = db.prepare('SELECT * FROM messages WHERE id = ? AND chat_id = ?').get(messageId, chatId);
      if (!msg) return callback && callback({ error: 'Сообщение не найдено' });

      if (msg.sender_id !== userId && user.role !== 'superadmin' && user.role !== 'admin') {
        return callback && callback({ error: 'Нет прав на удаление' });
      }

      db.prepare('DELETE FROM messages WHERE id = ?').run(messageId);
      io.to('chat_' + chatId).emit('message_deleted', {
        chatId: Number(chatId),
        messageId: Number(messageId)
      });
      if (callback) callback({ success: true });
    } catch (err) {
      if (callback) callback({ error: 'Ошибка удаления' });
    }
  });

  socket.on('typing', ({ chatId, isTyping }) => {
    socket.to('chat_' + chatId).emit('user_typing', {
      chatId,
      userId,
      username: user.username,
      name: user.name,
      isTyping
    });
  });

  socket.on('mark_read', ({ chatId, messageIds }) => {
    if (!Array.isArray(messageIds) || messageIds.length === 0) return;
    const stmt = db.prepare(`INSERT OR IGNORE INTO message_reads (message_id, user_id) VALUES (?, ?)`);
    for (const mid of messageIds) {
      stmt.run(mid, userId);
    }
    socket.to('chat_' + chatId).emit('messages_read', { chatId, userId, messageIds });
  });

  socket.on('toggle_reaction', ({ messageId, emoji, chatId }) => {
    const existing = db.prepare('SELECT id FROM reactions WHERE message_id = ? AND user_id = ? AND emoji = ?').get(messageId, userId, emoji);
    if (existing) {
      db.prepare('DELETE FROM reactions WHERE id = ?').run(existing.id);
    } else {
      db.prepare('INSERT INTO reactions (message_id, user_id, emoji) VALUES (?, ?, ?)').run(messageId, userId, emoji);
    }

    const allReactions = db.prepare(`
      SELECT r.emoji, r.user_id, u.name as user_name
      FROM reactions r JOIN users u ON r.user_id = u.id
      WHERE r.message_id = ?
    `).all(messageId);

    const map = {};
    for (const r of allReactions) {
      if (!map[r.emoji]) map[r.emoji] = [];
      map[r.emoji].push({ userId: r.user_id, name: r.user_name });
    }

    io.to('chat_' + chatId).emit('reaction_updated', { messageId, reactions: map });
  });

  socket.on('disconnect', () => {
    if (onlineUsers.has(userId)) {
      onlineUsers.get(userId).delete(socket.id);
      if (onlineUsers.get(userId).size === 0) {
        onlineUsers.delete(userId);
        db.prepare('UPDATE users SET last_seen = CURRENT_TIMESTAMP WHERE id = ?').run(userId);
        io.emit('user_status', { userId, status: 'offline', last_seen: new Date().toISOString() });
      }
    }
  });
});

// Serve frontend for all SPA routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 GIN-Chat running on http://0.0.0.0:${PORT}`);
  sendTelegramNotification('🚀 <b>GIN-Chat сервер v019 запущен:</b>\nhttps://4at.gincz.com');
  pollTelegramUpdates();
});
