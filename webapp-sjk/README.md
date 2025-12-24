# WebApp SJK

WebApp SJK dengan authentication dan chat history database.

## Fitur

- ✅ Login & Register dengan session
- ✅ Chat history tersimpan di database (MySQL/MariaDB)
- ✅ Setiap user punya data chat terpisah
- ✅ Endpoint chat dilindungi dengan authentication
- ✅ UI Gemini-style (tidak diubah)

## Tech Stack

- Node.js + Express
- MySQL/MariaDB
- express-session
- bcrypt

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Setup Database

Buat database MySQL/MariaDB:

```sql
CREATE DATABASE webapp_sjk;
```

### 3. Konfigurasi Environment

Copy `.env.example` ke `.env` dan edit sesuai konfigurasi database Anda:

```bash
cp .env.example .env
```

Edit `.env`:
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=webapp_sjk
SESSION_SECRET=your-secret-key
N8N_WEBHOOK_URL=your-n8n-webhook-url
```

### 4. Run Server

```bash
npm start
```

Server akan berjalan di `http://localhost:3000`

## API Endpoints

### Authentication

- `POST /auth/register` - Register user baru
- `POST /auth/login` - Login user
- `POST /auth/logout` - Logout user
- `GET /auth/me` - Get current user info

### Chat

- `GET /conversations` - Get semua conversations user
- `POST /conversations` - Buat conversation baru
- `GET /conversations/:id/messages` - Get messages dari conversation
- `POST /ask` - Kirim pertanyaan ke n8n dan simpan ke DB (requires auth)

## Struktur Project

```
webapp-sjk/
├── src/
│   └── server/
│       ├── app.js              # Main application
│       ├── db/
│       │   └── index.js        # Database connection
│       ├── middleware/
│       │   └── auth.js         # Auth middleware
│       └── routes/
│           ├── auth.js          # Auth routes
│           └── chat.js         # Chat routes
├── .env.example
├── package.json
└── README.md
```

## Dokumentasi Lengkap

Lihat `docs/BACKEND_AUTH_CHAT_GUIDE.md` untuk dokumentasi lengkap termasuk:
- Arsitektur sistem
- Database schema
- Setup database
- Testing endpoints
- Troubleshooting

