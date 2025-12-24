# Panduan Cepat: Memperbaiki Telegram Trigger yang Tidak Berfungsi

## Masalah
Telegram trigger di n8n tidak merespons pesan dari bot "Mei".

## Solusi Cepat (Coba Langkah Ini Dulu!)

### Langkah 1: Pastikan Workflow Aktif ✅
1. Buka n8n di browser
2. Buka workflow yang berisi Telegram Trigger
3. Pastikan tombol **"Active"** di pojok kanan atas **HIDUP** (hijau)
4. Jika mati, klik untuk mengaktifkan

### Langkah 2: Cek dan Update ngrok URL 🔄
**Masalah paling umum:** URL ngrok berubah setiap kali restart (jika pakai ngrok gratis)

1. **Cek URL ngrok saat ini:**
   - Buka browser ke: `http://localhost:4040`
   - Atau jalankan: `curl http://localhost:4040/api/tunnels`
   - Copy URL yang muncul (contoh: `https://abc123.ngrok-free.dev`)

2. **Update docker-compose.yml:**
   - Buka file `docker-compose.yml`
   - Ganti semua URL yang ada dengan URL ngrok baru
   - Simpan file

3. **Restart n8n:**
   ```bash
   docker-compose restart
   ```

### Langkah 3: Re-register Webhook di n8n 🔄
1. Di n8n, buka node **Telegram Trigger**
2. Klik **"Stop Listening"** (jika sedang listening)
3. **Nonaktifkan** workflow (toggle Active OFF)
4. **Aktifkan** workflow lagi (toggle Active ON)
5. Klik **"Listen for test event"** lagi
6. Kirim pesan test ke bot di Telegram

### Langkah 4: Pastikan Hanya Satu Workflow Menggunakan Bot yang Sama ⚠️
Telegram hanya mengizinkan **SATU webhook per bot**!

1. Cek semua workflow di n8n
2. Pastikan hanya **SATU** workflow yang menggunakan bot "Mei"
3. Nonaktifkan workflow lain yang menggunakan bot yang sama

## Script Otomatis untuk Cek Status

Jalankan script ini untuk mengecek semua status sekaligus:

```powershell
.\docs\check-telegram-status.ps1
```

Script akan mengecek:
- ✅ Status Docker container
- ✅ Status ngrok tunnel
- ✅ Kesesuaian URL
- ✅ Log error

## Troubleshooting Lanjutan

Jika masih tidak berfungsi, lihat: `docs/TROUBLESHOOTING_TELEGRAM.md`

## Checklist Cepat

- [ ] Workflow **AKTIF** (toggle hijau)
- [ ] ngrok tunnel **BERJALAN**
- [ ] URL di docker-compose.yml **SESUAI** dengan ngrok
- [ ] n8n container sudah **DI-RESTART** setelah update URL
- [ ] Hanya **SATU** workflow menggunakan bot "Mei"
- [ ] Bot sudah di-start dengan `/start` di Telegram
- [ ] Kredensial Telegram bot **BENAR** (token dari @BotFather)

## Tips

1. **Gunakan ngrok Pro** jika sering restart - URL tidak berubah
2. **Simpan workflow** sebelum mengubah-ubah
3. **Cek Execution History** di n8n untuk melihat error detail
4. **Test dengan bot berbeda** untuk memastikan masalahnya spesifik ke bot tertentu

