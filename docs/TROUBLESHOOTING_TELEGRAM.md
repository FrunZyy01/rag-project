# Troubleshooting Telegram Trigger di n8n

## Masalah: Telegram Trigger Tidak Berfungsi

Jika Telegram trigger di n8n tidak merespons pesan dari bot, ikuti langkah-langkah berikut:

### 1. Pastikan Workflow Aktif ✅
- Buka workflow di n8n
- Pastikan tombol **"Active"** (toggle switch) di pojok kanan atas **HIDUP** (berwarna hijau)
- Jika mati, klik untuk mengaktifkannya

### 2. Periksa Status ngrok Tunnel 🌐
Telegram memerlukan webhook URL yang dapat diakses dari internet. Pastikan:
- ngrok tunnel sedang berjalan
- URL di `docker-compose.yml` masih valid: `nonrhyming-geoffrey-thermoclnal.ngrok-free.dev`
- Jika menggunakan ngrok gratis, URL berubah setiap kali restart - **update di docker-compose.yml**

**Cara cek ngrok:**
```bash
# Jika ngrok berjalan, cek status
curl http://localhost:4040/api/tunnels
```

**Jika ngrok tidak berjalan:**
```bash
# Jalankan ngrok (di terminal terpisah)
ngrok http 5678
# Copy URL baru ke docker-compose.yml
```

### 3. Restart n8n Container 🔄
Setelah update ngrok URL, restart container:
```bash
docker-compose down
docker-compose up -d
```

### 4. Periksa Kredensial Telegram Bot 🤖
- Pastikan **Access Token** bot benar
- Dapatkan dari [@BotFather](https://t.me/botfather) di Telegram
- Pastikan credential "Mei" di n8n menggunakan token yang benar

### 5. Batasan Telegram API ⚠️
**PENTING:** Telegram hanya mengizinkan **SATU webhook per bot** pada satu waktu.
- Jika ada workflow lain yang menggunakan bot yang sama, nonaktifkan yang lain
- Atau gunakan bot berbeda untuk workflow berbeda

### 6. Test Webhook URL 🔍
Cek apakah webhook URL dapat diakses:
```bash
# Ganti dengan webhook URL dari n8n
curl https://nonrhyming-geoffrey-thermoclnal.ngrok-free.dev/webhook/...
```

### 7. Periksa Log n8n 📋
Cek log untuk error:
```bash
# Windows PowerShell
Get-Content n8n/n8nEventLog.log -Tail 100 | Select-String -Pattern "telegram|error"
```

### 8. Re-register Webhook 🔄
Di n8n:
1. Buka node Telegram Trigger
2. Klik **"Stop Listening"** jika sedang listening
3. Klik **"Listen for test event"** lagi
4. Atau nonaktifkan lalu aktifkan workflow

### 9. Verifikasi Bot di Telegram 💬
- Pastikan bot sudah di-start dengan `/start`
- Kirim pesan test ke bot
- Pastikan bot tidak di-block

### 10. Cek Firewall/Network 🔒
- Pastikan port 5678 tidak di-block
- Pastikan ngrok dapat mengakses localhost:5678

## Langkah Cepat (Quick Fix)

1. **Stop Listening** di Telegram Trigger node
2. **Nonaktifkan** workflow (toggle Active OFF)
3. **Aktifkan** workflow lagi (toggle Active ON)
4. **Start Listening** lagi di Telegram Trigger node
5. Kirim pesan test ke bot

## Jika Masih Tidak Berfungsi

1. Buat workflow baru dengan Telegram Trigger
2. Gunakan bot Telegram yang berbeda untuk test
3. Cek apakah ada error di Execution History di n8n
4. Pastikan n8n container berjalan: `docker ps`

