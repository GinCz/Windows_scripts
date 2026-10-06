const { db } = require('./db');
db.prepare("UPDATE users SET username = 'gin', email = 'gin.vladimir@gmail.com' WHERE id = 1").run();
console.log('Updated user 1:', db.prepare("SELECT id, name, username, email FROM users WHERE id = 1").get());
