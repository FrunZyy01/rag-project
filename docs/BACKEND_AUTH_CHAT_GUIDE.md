# Backend Authentication & Chat Guide

Dokumentasi lengkap untuk sistem authentication dan chat history dengan database di WebApp SJK.

## 📋 Daftar Isi

1. [Arsitektur Sistem](#arsitektur-sistem)
2. [Database Schema](#database-schema)
3. [Setup Database](#setup-database)
4. [Environment Variables](#environment-variables)
5. [Cara Run Server](#cara-run-server)
6. [API Endpoints](#api-endpoints)
7. [Testing Endpoints](#testing-endpoints)
8. [Troubleshooting](#troubleshooting)

---

## 🏗️ Arsitektur Sistem

### Struktur Folder

```
webapp-sjk/
├── src/
│   └── server/
│       ├── app.js                  # Main application entry point
│       ├── db/
│       │   └── index.js           # Database connection & initialization
│       ├── middleware/
│       │   └── auth.js            # Authentication middleware
│       └── routes/
│           ├── auth.js             # Authentication routes
│           └── chat.js             # Chat & conversation routes
├── .env.example                   # Environment variables template
├── package.json
└── README.md
```

### Flow Authentication

1. **Register/Login** → Session dibuat dengan `userId` dan `username`
2. **Protected Routes** → Middleware `requireAuth` mengecek session
3. **Chat Operations** → Semua query filter by `user_id` dari session

### Flow Chat

1. User mengirim pertanyaan → `POST /ask`
2. Backend:
   - Cek authentication (session)
   - Buat/update conversation
   - Simpan pesan user ke database
   - Forward ke n8n webhook
   - Simpan response AI ke database
   - Return response ke frontend

---

## 🗄️ Database Schema

### Tabel: `users`

Menyimpan data user untuk authentication.

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255),
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Kolom:**
- `id` - Primary key, auto increment
- `username` - Username unik untuk login
- `email` - Email (optional)
- `password_hash` - Password yang sudah di-hash dengan bcrypt
- `created_at` - Timestamp saat user dibuat

### Tabel: `conversations`

Menyimpan data conversation per user.

```sql
CREATE TABLE conversations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Kolom:**
- `id` - Primary key, auto increment
- `user_id` - Foreign key ke `users.id`
- `title` - Judul conversation (dari pertanyaan pertama)
- `created_at` - Timestamp saat conversation dibuat
- `updated_at` - Timestamp saat conversation terakhir diupdate

**Index:**
- `idx_user_id` - Untuk query cepat berdasarkan user
- `idx_updated_at` - Untuk sorting conversation terbaru

### Tabel: `messages`

Menyimpan pesan user dan AI dalam conversation.

```sql
CREATE TABLE messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  conversation_id INT NOT NULL,
  role ENUM('user', 'ai') NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  INDEX idx_conversation_id (conversation_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Kolom:**
- `id` - Primary key, auto increment
- `conversation_id` - Foreign key ke `conversations.id`
- `role` - Role pesan: 'user' atau 'ai'
- `content` - Isi pesan
- `created_at` - Timestamp saat pesan dibuat

**Index:**
- `idx_conversation_id` - Untuk query pesan per conversation
- `idx_created_at` - Untuk sorting pesan

### Relasi

```
users (1) ──< (many) conversations (1) ──< (many) messages
```

- Satu user bisa punya banyak conversations
- Satu conversation bisa punya banyak messages
- ON DELETE CASCADE: Jika user dihapus, conversations dan messages ikut terhapus
- Jika conversation dihapus, messages ikut terhapus

---

## 🛠️ Setup Database

### 1. Install MySQL/MariaDB

**Windows:**
- Download dari [MySQL Downloads](https://dev.mysql.com/downloads/mysql/) atau
- Install XAMPP yang sudah include MySQL

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install mysql-server
```

**macOS:**
```bash
brew install mysql
```

### 2. Buat Database

Login ke MySQL:
```bash
mysql -u root -p
```

Buat database:
```sql
CREATE DATABASE webapp_sjk CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Atau jika sudah ada, gunakan:
```sql
USE webapp_sjk;
```

### 3. Tabel Akan Dibuat Otomatis

Tabel akan dibuat otomatis saat server pertama kali dijalankan melalui fungsi `initDatabase()` di `src/server/db/index.js`.

Jika ingin membuat manual, jalankan SQL di atas.

### 4. Buat User Database (Optional)

Untuk keamanan, buat user khusus untuk aplikasi:

```sql
CREATE USER 'webapp_sjk_user'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON webapp_sjk.* TO 'webapp_sjk_user'@'localhost';
FLUSH PRIVILEGES;
```

Gunakan user ini di `.env`:
```
DB_USER=webapp_sjk_user
DB_PASSWORD=your_secure_password
```

---

## 🔐 Environment Variables

Buat file `.env` di root folder `webapp-sjk/`:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password_here
DB_NAME=webapp_sjk

# Server Configuration
PORT=3000
NODE_ENV=development

# Session Secret (GANTI DI PRODUCTION!)
# Generate random string: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
SESSION_SECRET=your-super-secret-session-key-change-this-in-production

# CORS Configuration (optional)
CORS_ORIGIN=true

# N8N Webhook URL
N8N_WEBHOOK_URL=https://nonrhyming-geoffrey-thermoclinal.ngrok-free.dev/webhook/webapp-sjk-ask
```

### Penjelasan Variables

| Variable | Deskripsi | Default |
|----------|-----------|---------|
| `DB_HOST` | Host database MySQL | `localhost` |
| `DB_PORT` | Port database MySQL | `3306` |
| `DB_USER` | Username database | `root` |
| `DB_PASSWORD` | Password database | (required) |
| `DB_NAME` | Nama database | `webapp_sjk` |
| `PORT` | Port server Express | `3000` |
| `NODE_ENV` | Environment (development/production) | `development` |
| `SESSION_SECRET` | Secret key untuk session encryption | (required) |
| `CORS_ORIGIN` | CORS origin (true = allow all) | `true` |
| `N8N_WEBHOOK_URL` | URL webhook n8n | (required) |

**⚠️ PENTING:**
- `SESSION_SECRET` harus diubah di production!
- Generate random secret: `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`

---

## 🚀 Cara Run Server

### 1. Install Dependencies

```bash
cd webapp-sjk
npm install
```

Dependencies yang akan diinstall:
- `express` - Web framework
- `mysql2` - MySQL driver
- `express-session` - Session management
- `bcrypt` - Password hashing
- `dotenv` - Environment variables
- `cors` - CORS middleware
- `axios` - HTTP client untuk n8n webhook

### 2. Setup Environment

```bash
cp .env.example .env
# Edit .env dengan konfigurasi database Anda
```

### 3. Run Server

```bash
npm start
```

Atau:

```bash
node src/server/app.js
```

Output yang diharapkan:
```
✅ Database connected successfully
✅ Database schema initialized
🚀 WebApp running on http://localhost:3000
📝 Environment: development
```

### 4. Akses Aplikasi

Buka browser: `http://localhost:3000`

---

## 📡 API Endpoints

### Authentication Endpoints

#### POST /auth/register

Register user baru.

**Request:**
```json
{
  "username": "john_doe",
  "email": "john@example.com",  // optional
  "password": "password123"
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com"
  }
}
```

**Response (Error - 409):**
```json
{
  "error": "Conflict",
  "message": "Username sudah digunakan"
}
```

#### POST /auth/login

Login user.

**Request:**
```json
{
  "username": "john_doe",
  "password": "password123"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Login berhasil",
  "user": {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com"
  }
}
```

**Response (Error - 401):**
```json
{
  "error": "Unauthorized",
  "message": "Username atau password salah"
}
```

#### POST /auth/logout

Logout user (clear session).

**Request:** (tidak perlu body)

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Logout berhasil"
}
```

#### GET /auth/me

Get current user info dari session.

**Request:** (tidak perlu body, session cookie otomatis)

**Response (Success - 200):**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "username": "john_doe"
  }
}
```

**Response (Error - 401):**
```json
{
  "error": "Unauthorized",
  "message": "Anda belum login"
}
```

### Chat Endpoints

**⚠️ Semua endpoint chat memerlukan authentication!**

#### GET /conversations

Get semua conversations milik user yang login.

**Query Parameters:**
- `limit` (optional) - Jumlah conversations per page (default: 50)
- `offset` (optional) - Offset untuk pagination (default: 0)

**Response (Success - 200):**
```json
{
  "success": true,
  "conversations": [
    {
      "id": 1,
      "title": "Apa itu JavaScript?",
      "created_at": "2025-12-15T10:00:00.000Z",
      "updated_at": "2025-12-15T10:05:00.000Z"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

#### POST /conversations

Buat conversation baru.

**Request:**
```json
{
  "title": "Percakapan baru"  // optional
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "conversation": {
    "id": 1,
    "user_id": 1,
    "title": "Percakapan baru"
  }
}
```

#### GET /conversations/:id/messages

Get semua messages dari conversation tertentu.

**Response (Success - 200):**
```json
{
  "success": true,
  "messages": [
    {
      "id": 1,
      "role": "user",
      "content": "Apa itu JavaScript?",
      "created_at": "2025-12-15T10:00:00.000Z"
    },
    {
      "id": 2,
      "role": "ai",
      "content": "JavaScript adalah bahasa pemrograman...",
      "created_at": "2025-12-15T10:00:05.000Z"
    }
  ]
}
```

**Response (Error - 404):**
```json
{
  "error": "Not found",
  "message": "Conversation tidak ditemukan atau bukan milik Anda"
}
```

#### POST /ask

Kirim pertanyaan ke n8n dan simpan ke database.

**Request:**
```json
{
  "question": "Apa itu JavaScript?",
  "conversation_id": 1  // optional, jika tidak ada akan buat baru
}
```

**Response (Success - 200):**
```json
{
  "output": "JavaScript adalah bahasa pemrograman..."
}
```

**Response (Error - 401):**
```json
{
  "error": "Unauthorized",
  "message": "Anda harus login terlebih dahulu"
}
```

**Flow:**
1. Cek authentication
2. Buat/update conversation
3. Simpan pesan user
4. Forward ke n8n webhook
5. Simpan response AI
6. Return response (format sama seperti sebelumnya untuk kompatibilitas frontend)

---

## 🧪 Testing Endpoints

### Menggunakan cURL

#### 1. Register User

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }' \
  -c cookies.txt
```

**Note:** `-c cookies.txt` menyimpan session cookie untuk request berikutnya.

#### 2. Login

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }' \
  -c cookies.txt
```

#### 3. Get Current User

```bash
curl -X GET http://localhost:3000/auth/me \
  -b cookies.txt
```

#### 4. Get Conversations

```bash
curl -X GET http://localhost:3000/conversations \
  -b cookies.txt
```

#### 5. Send Question (Ask)

```bash
curl -X POST http://localhost:3000/ask \
  -H "Content-Type: application/json" \
  -d '{
    "question": "Apa itu JavaScript?"
  }' \
  -b cookies.txt
```

#### 6. Get Messages from Conversation

```bash
curl -X GET http://localhost:3000/conversations/1/messages \
  -b cookies.txt
```

#### 7. Logout

```bash
curl -X POST http://localhost:3000/auth/logout \
  -b cookies.txt \
  -c cookies.txt
```

### Menggunakan Postman

1. **Setup Collection:**
   - Buat collection baru: "WebApp SJK API"
   - Set base URL: `http://localhost:3000`

2. **Register:**
   - Method: `POST`
   - URL: `{{baseUrl}}/auth/register`
   - Body (JSON):
     ```json
     {
       "username": "testuser",
       "password": "password123"
     }
     ```

3. **Login:**
   - Method: `POST`
   - URL: `{{baseUrl}}/auth/login`
   - Body (JSON):
     ```json
     {
       "username": "testuser",
       "password": "password123"
     }
     ```
   - **Important:** Enable "Save Cookies" di Postman settings

4. **Get Conversations:**
   - Method: `GET`
   - URL: `{{baseUrl}}/conversations`
   - Cookies akan otomatis terkirim jika sudah login

5. **Ask:**
   - Method: `POST`
   - URL: `{{baseUrl}}/ask`
   - Body (JSON):
     ```json
     {
       "question": "Apa itu JavaScript?"
     }
     ```

### Menggunakan Browser (JavaScript)

```javascript
// Register
fetch('http://localhost:3000/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  credentials: 'include', // Penting untuk session cookies
  body: JSON.stringify({
    username: 'testuser',
    password: 'password123'
  })
})
.then(res => res.json())
.then(data => console.log(data));

// Login
fetch('http://localhost:3000/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  credentials: 'include',
  body: JSON.stringify({
    username: 'testuser',
    password: 'password123'
  })
})
.then(res => res.json())
.then(data => console.log(data));

// Get Conversations
fetch('http://localhost:3000/conversations', {
  method: 'GET',
  credentials: 'include'
})
.then(res => res.json())
.then(data => console.log(data));

// Ask
fetch('http://localhost:3000/ask', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  credentials: 'include',
  body: JSON.stringify({
    question: 'Apa itu JavaScript?'
  })
})
.then(res => res.json())
.then(data => console.log(data));
```

---

## 🔧 Troubleshooting

### Database Connection Error

**Error:**
```
❌ Database connection failed: ER_ACCESS_DENIED_ERROR
```

**Solusi:**
1. Cek username dan password di `.env`
2. Pastikan MySQL service berjalan
3. Test koneksi manual:
   ```bash
   mysql -u root -p
   ```

### Table Doesn't Exist

**Error:**
```
Error: Table 'webapp_sjk.users' doesn't exist
```

**Solusi:**
1. Pastikan database sudah dibuat
2. Cek `initDatabase()` di `src/server/db/index.js` berjalan
3. Buat tabel manual dengan SQL di atas

### Session Not Working

**Error:**
```
401 Unauthorized
```

**Solusi:**
1. Pastikan `credentials: 'include'` di frontend fetch
2. Cek `SESSION_SECRET` di `.env` sudah di-set
3. Pastikan CORS configuration benar:
   ```javascript
   app.use(cors({
     origin: true,
     credentials: true
   }));
   ```

### N8N Webhook Error

**Error:**
```
Error: connect ECONNREFUSED
```

**Solusi:**
1. Cek `N8N_WEBHOOK_URL` di `.env` benar
2. Pastikan n8n webhook berjalan
3. Test webhook manual:
   ```bash
   curl -X POST https://your-webhook-url \
     -H "Content-Type: application/json" \
     -d '{"question": "test"}'
   ```

### Password Hash Error

**Error:**
```
Error: data and hash must be strings
```

**Solusi:**
1. Pastikan password di-hash dengan bcrypt
2. Cek password tidak null/undefined saat register

### Foreign Key Constraint Error

**Error:**
```
Error: Cannot add or update a child row: a foreign key constraint fails
```

**Solusi:**
1. Pastikan `user_id` valid saat membuat conversation
2. Pastikan `conversation_id` valid saat membuat message
3. Cek foreign key constraints di database

### Port Already in Use

**Error:**
```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solusi:**
1. Ganti `PORT` di `.env`
2. Atau kill process yang menggunakan port 3000:
   ```bash
   # Windows
   netstat -ano | findstr :3000
   taskkill /PID <PID> /F
   
   # Linux/Mac
   lsof -ti:3000 | xargs kill
   ```

---

## 📝 Catatan Penting

1. **Security:**
   - Selalu gunakan HTTPS di production
   - Ganti `SESSION_SECRET` dengan random string yang kuat
   - Jangan commit `.env` ke git
   - Gunakan prepared statements (sudah diimplementasi dengan mysql2)

2. **Performance:**
   - Connection pooling sudah diimplementasi
   - Index sudah dibuat untuk query cepat
   - Consider pagination untuk conversations yang banyak

3. **Data Isolation:**
   - Semua query chat filter by `user_id` dari session
   - User tidak bisa akses conversation milik user lain
   - Foreign key constraints memastikan data integrity

4. **Session Management:**
   - Session expire setelah 24 jam
   - Session disimpan di memory (default)
   - Untuk production, consider menggunakan Redis atau database session store

---

## 📚 Referensi

- [Express.js Documentation](https://expressjs.com/)
- [MySQL2 Documentation](https://github.com/sidorares/node-mysql2)
- [express-session Documentation](https://github.com/expressjs/session)
- [bcrypt Documentation](https://github.com/kelektiv/node.bcrypt.js)

---

**Dokumentasi ini dibuat untuk WebApp SJK Backend System v1.0.0**

