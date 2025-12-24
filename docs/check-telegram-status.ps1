# Script untuk mengecek status Telegram Trigger di n8n
# Jalankan dengan: .\docs\check-telegram-status.ps1

Write-Host "=== Pengecekan Status Telegram Trigger n8n ===" -ForegroundColor Cyan
Write-Host ""

# 1. Cek apakah Docker container n8n berjalan
Write-Host "1. Mengecek status Docker container..." -ForegroundColor Yellow
$container = docker ps --filter "name=n8n" --format "{{.Names}}"
if ($container -eq "n8n") {
    Write-Host "   [OK] Container n8n berjalan" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Container n8n TIDAK berjalan!" -ForegroundColor Red
    Write-Host "   Jalankan: docker-compose up -d" -ForegroundColor Yellow
    exit
}

# 2. Cek ngrok tunnel
Write-Host ""
Write-Host "2. Mengecek ngrok tunnel..." -ForegroundColor Yellow
try {
    $ngrokResponse = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
    if ($ngrokResponse.tunnels) {
        $publicUrl = $ngrokResponse.tunnels[0].public_url
        Write-Host "   [OK] Ngrok tunnel aktif: $publicUrl" -ForegroundColor Green
        
        # Bandingkan dengan docker-compose.yml
        $dockerCompose = Get-Content "docker-compose.yml" -Raw
        $hostMatch = [regex]::Match($dockerCompose, "N8N_HOST=([^\r\n]+)")
        if ($hostMatch.Success) {
            $configuredHost = $hostMatch.Groups[1].Value
            if ($publicUrl -like "*$configuredHost*") {
                Write-Host "   [OK] URL di docker-compose.yml sesuai" -ForegroundColor Green
            } else {
                Write-Host "   [WARNING] URL di docker-compose.yml TIDAK sesuai!" -ForegroundColor Red
                Write-Host "   URL di docker-compose: $configuredHost" -ForegroundColor Yellow
                Write-Host "   URL ngrok saat ini: $publicUrl" -ForegroundColor Yellow
                Write-Host "   Update docker-compose.yml dengan URL baru!" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "   [ERROR] Tidak ada tunnel aktif" -ForegroundColor Red
    }
} catch {
    Write-Host "   [ERROR] Ngrok tidak berjalan atau tidak dapat diakses" -ForegroundColor Red
    Write-Host "   Jalankan ngrok: ngrok http 5678" -ForegroundColor Yellow
}

# 3. Cek log terakhir untuk error Telegram
Write-Host ""
Write-Host "3. Mengecek log n8n untuk error Telegram..." -ForegroundColor Yellow
if (Test-Path "n8n/n8nEventLog.log") {
    $telegramLogs = Get-Content "n8n/n8nEventLog.log" -Tail 200 | Select-String -Pattern "telegram|Telegram" -CaseSensitive:$false
    if ($telegramLogs) {
        Write-Host "   Log Telegram terakhir:" -ForegroundColor Cyan
        $telegramLogs | Select-Object -Last 3 | ForEach-Object {
            Write-Host "   $_" -ForegroundColor Gray
        }
    } else {
        Write-Host "   [INFO] Tidak ada log Telegram ditemukan" -ForegroundColor Yellow
    }
} else {
    Write-Host "   [WARNING] File log tidak ditemukan" -ForegroundColor Yellow
}

# 4. Cek apakah port 5678 dapat diakses
Write-Host ""
Write-Host "4. Mengecek akses ke n8n..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   [OK] n8n dapat diakses di localhost:5678" -ForegroundColor Green
} catch {
    Write-Host "   [ERROR] n8n tidak dapat diakses di localhost:5678" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Rekomendasi ===" -ForegroundColor Cyan
Write-Host "1. Pastikan workflow Telegram Trigger AKTIF di n8n" -ForegroundColor White
Write-Host "2. Pastikan ngrok tunnel berjalan dan URL sesuai" -ForegroundColor White
Write-Host "3. Restart n8n container setelah update URL: docker-compose restart" -ForegroundColor White
Write-Host "4. Cek di n8n UI apakah webhook URL terdaftar dengan benar" -ForegroundColor White
Write-Host "5. Pastikan hanya SATU workflow yang menggunakan bot yang sama" -ForegroundColor White
Write-Host ""
Write-Host "Lihat docs/TROUBLESHOOTING_TELEGRAM.md untuk detail lebih lanjut" -ForegroundColor Cyan
