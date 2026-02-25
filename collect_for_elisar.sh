#!/bin/bash
# ======================================================================
# collect_for_elisar.sh – Otomatisasi pengumpulan data untuk ELISAR
# ======================================================================
# Fungsi: Mengumpulkan informasi sistem, konfigurasi, layanan, log,
#         dan data keamanan lainnya dari server Linux.
# Output: Folder terkompresi berisi file-file teks terstruktur.
# ======================================================================

set -e  # Hentikan jika ada error

OUTPUT_BASE="elisar_$(hostname)_$(date +%Y%m%d_%H%M%S)"
OUTPUT_DIR="./$OUTPUT_BASE"
mkdir -p "$OUTPUT_DIR"

echo "[1/9] Mengumpulkan informasi dasar sistem..."
{
    echo "=== SISTEM ==="
    uname -a
    echo "---"
    cat /etc/os-release
    echo "---"
    uptime
    echo "---"
    df -h
    echo "---"
    free -h
} > "$OUTPUT_DIR/01_system_info.txt"

echo "[2/9] Mengumpulkan informasi user dan grup..."
{
    echo "=== USER & GRUP ==="
    echo "--- /etc/passwd (hanya yg bash) ---"
    grep bash /etc/passwd
    echo "--- /etc/group ---"
    cat /etc/group
    echo "--- Sudoers (hanya entri efektif) ---"
    sudo cat /etc/sudoers | grep -v '^#' | grep -v '^$' 2>/dev/null || echo "Tidak bisa membaca sudoers"
} > "$OUTPUT_DIR/02_users_groups.txt"

echo "[3/9] Mengumpulkan izin file kritis..."
{
    echo "=== IZIN FILE KRITIS ==="
    for file in /etc/passwd /etc/shadow /etc/sudoers /etc/ssh/sshd_config /etc/crontab /etc/hosts.allow /etc/hosts.deny; do
        ls -la "$file" 2>/dev/null || echo "$file: tidak ditemukan"
    done
} > "$OUTPUT_DIR/03_critical_perms.txt"

echo "[4/9] Mengumpulkan daftar layanan dan proses..."
{
    echo "=== LAYANAN AKTIF (systemctl) ==="
    systemctl list-units --type=service --state=running --no-pager
    echo ""
    echo "=== SEMUA PROSES (ps auxf) ==="
    ps auxf
} > "$OUTPUT_DIR/04_services_processes.txt"

echo "[5/9] Mengumpulkan informasi jaringan..."
{
    echo "=== PORTER YANG TERBUKA (ss -tulpn) ==="
    ss -tulpn
    echo ""
    echo "=== KONEKSI AKTIF (ss -tunap) ==="
    ss -tunap
    echo ""
    echo "=== ATURAN FIREWALL ==="
    if command -v iptables &>/dev/null; then
        sudo iptables -L -n -v 2>/dev/null || echo "iptables: tidak bisa membaca"
    else
        echo "iptables tidak terinstall"
    fi
    if command -v nft &>/dev/null; then
        sudo nft list ruleset 2>/dev/null || echo "nftables: tidak bisa membaca"
    fi
} > "$OUTPUT_DIR/05_network.txt"

echo "[6/9] Mengumpulkan jadwal cron..."
{
    echo "=== CRON SISTEM ==="
    cat /etc/crontab 2>/dev/null || echo "Tidak ada /etc/crontab"
    echo ""
    echo "=== CRON DI /etc/cron.d/ ==="
    ls -la /etc/cron.d/ 2>/dev/null | while read line; do
        if [[ "$line" =~ ^- ]]; then
            file="/etc/cron.d/$(echo $line | awk '{print $9}')"
            echo "--- $file ---"
            cat "$file" 2>/dev/null
        fi
    done
    echo ""
    echo "=== CRON USER (semua user dengan bash) ==="
    while IFS=: read user _; do
        crontab -u "$user" -l 2>/dev/null && echo "--- $user ---"
    done < <(grep bash /etc/passwd)
} > "$OUTPUT_DIR/06_cron_jobs.txt"

echo "[7/9] Mengumpulkan log penting (1 jam terakhir)..."
{
    echo "=== LOG AUTH (gagal login, sudo) ==="
    journalctl --since "1 hour ago" | grep -iE "fail|error|invalid|unauthorized|authentication failure" | tail -200
    echo ""
    echo "=== LOG KERNEL (error) ==="
    dmesg | grep -i error | tail -50
    echo ""
    echo "=== 10 BARIS TERAKHIR LOG UTAMA ==="
    tail -20 /var/log/syslog 2>/dev/null || echo "syslog tidak ada"
} > "$OUTPUT_DIR/07_logs_recent.txt"

echo "[8/9] Memeriksa indikasi awal rootkit/backdoor..."
{
    echo "=== FILE SUID/SGID MENYELURUH ==="
    find / -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null | head -50
    echo ""
    echo "=== DIREKTORI YANG BISA DITULIS SEMUA ORANG (world-writable) ==="
    find / -type d -perm -0002 -ls 2>/dev/null | head -20
    echo ""
    echo "=== FILE .bash_history USER ==="
    for user_home in /home/*; do
        if [ -f "$user_home/.bash_history" ]; then
            echo "--- $user_home/.bash_history (10 terakhir) ---"
            tail -10 "$user_home/.bash_history"
        fi
    done
    if [ -f "/root/.bash_history" ]; then
        echo "--- /root/.bash_history (10 terakhir) ---"
        sudo tail -10 /root/.bash_history 2>/dev/null || echo "tidak bisa membaca root history"
    fi
} > "$OUTPUT_DIR/08_suspicious_indicators.txt"

echo "[9/9] Membuat ringkasan dan kompresi..."
tree "$OUTPUT_DIR" > "$OUTPUT_DIR/00_structure.txt"
tar -czf "${OUTPUT_BASE}.tar.gz" -C "$(dirname "$OUTPUT_DIR")" "$OUTPUT_BASE"
rm -rf "$OUTPUT_DIR"

echo "✅ Selesai! Data tersimpan di: ${OUTPUT_BASE}.tar.gz"
echo "   Ukuran: $(du -h ${OUTPUT_BASE}.tar.gz | cut -f1)"
