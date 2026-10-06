const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');

const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

const DB_PATH = path.join(DATA_DIR, 'chat.db');
const db = new Database(DB_PATH);

// Enable Write-Ahead Logging for high concurrency performance
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Encryption key for AES-256-GCM database encryption at rest
const ENCRYPTION_KEY = crypto.createHash('sha256').update(process.env.ENCRYPT_SECRET || 'gin_secret_chat_key_2026').digest();

function encryptText(text) {
  if (!text) return text;
  try {
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', ENCRYPTION_KEY, iv);
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    const authTag = cipher.getAuthTag().toString('hex');
    return `ENC:${iv.toString('hex')}:${authTag}:${encrypted}`;
  } catch (err) {
    console.error('Encryption error:', err);
    return text;
  }
}

function decryptText(cipherText) {
  if (!cipherText || !cipherText.startsWith('ENC:')) return cipherText;
  try {
    const parts = cipherText.split(':');
    if (parts.length !== 4) return cipherText;
    const iv = Buffer.from(parts[1], 'hex');
    const authTag = Buffer.from(parts[2], 'hex');
    const encrypted = parts[3];
    const decipher = crypto.createDecipheriv('aes-256-gcm', ENCRYPTION_KEY, iv);
    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (err) {
    console.error('Decryption error:', err);
    return '[Зашифрованное сообщение]';
  }
}

// Initialize tables
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'user', -- 'superadmin', 'admin', 'user'
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'banned'
    avatar TEXT,
    bio TEXT,
    last_seen DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS chats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL, -- 'direct', 'group'
    name TEXT,
    description TEXT,
    avatar TEXT,
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    invite_code TEXT UNIQUE,
    pinned_message_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS chat_members (
    chat_id INTEGER REFERENCES chats(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'owner', 'admin', 'member'
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (chat_id, user_id)
  );

  CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chat_id INTEGER REFERENCES chats(id) ON DELETE CASCADE,
    sender_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    text_encrypted TEXT,
    reply_to_id INTEGER REFERENCES messages(id) ON DELETE SET NULL,
    type TEXT DEFAULT 'text', -- 'text', 'image', 'file', 'voice', 'system'
    file_url TEXT,
    file_name TEXT,
    file_size INTEGER,
    file_duration REAL,
    is_edited INTEGER DEFAULT 0,
    scheduled_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS message_reads (
    message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    read_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (message_id, user_id)
  );

  CREATE TABLE IF NOT EXISTS reactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    emoji TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, user_id, emoji)
  );

  CREATE TABLE IF NOT EXISTS reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    reporter_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    reported_user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    chat_id INTEGER REFERENCES chats(id) ON DELETE SET NULL,
    reasons TEXT NOT NULL,
    comment TEXT,
    status TEXT DEFAULT 'pending', -- 'pending', 'resolved', 'dismissed'
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
  CREATE INDEX IF NOT EXISTS idx_chat_members_user ON chat_members(user_id);
  CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
  CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
`);

// Migrations for existing databases
try {
  db.exec("ALTER TABLE messages ADD COLUMN is_edited INTEGER DEFAULT 0;");
} catch (e) {}
try {
  db.exec("ALTER TABLE messages ADD COLUMN scheduled_at DATETIME;");
} catch (e) {}

// Seed Superadmin account (Vladimir) if not exists
const adminCount = db.prepare("SELECT COUNT(*) as count FROM users WHERE role = 'superadmin'").get();
if (adminCount.count === 0) {
  const initialPassword = process.env.ADMIN_PASSWORD || 'GinAdmin2026!';
  const salt = bcrypt.genSaltSync(10);
  const hash = bcrypt.hashSync(initialPassword, salt);
  
  db.prepare(`
    INSERT INTO users (name, username, email, phone, password_hash, role, status, bio)
    VALUES (?, ?, ?, ?, ?, 'superadmin', 'approved', 'Главный администратор системы')
  `).run('Владимир Буланцев', 'admin', 'gincz@oracle.local', '+79990000000', hash);

  console.log('✅ Default superadmin created: username: admin / pass: ' + initialPassword);
}

module.exports = {
  db,
  encryptText,
  decryptText
};
