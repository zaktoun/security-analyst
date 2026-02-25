#!/usr/bin/env python3
"""
elisar_analyzer.py – Menganalisis data server dengan ELISAR
Penggunaan: python3 elisar_analyzer.py <folder_data> [--type <tipe>]
Tipe: system, network, logs, full (default)
"""

import os
import sys
import argparse
import subprocess
import glob
from pathlib import Path

# Konfigurasi – sesuaikan dengan path llama.cpp dan model Anda
LLAMA_CPP = "/path/to/llama.cpp/main"          # Ganti!
MODEL_PATH = "/path/to/elisar_merged.Q4_K_M.gguf"  # Ganti!
TEMP = 0.3
MAX_TOKENS = 2000

# Template prompt untuk berbagai tipe analisis
PROMPT_TEMPLATES = {
    "system": """### Instruction:
Anda adalah ELISAR, ahli keamanan sistem. Berikut adalah data konfigurasi sistem, user, izin file, dan layanan dari sebuah server Linux. Analisis data ini dan berikan rekomendasi untuk meningkatkan keamanan (hardening) berdasarkan praktik terbaik (CIS benchmarks, principle of least privilege). Fokus pada:

- Izin file kritis (/etc/passwd, /etc/shadow, dll.)
- User yang tidak perlu atau memiliki privilege berlebihan
- Layanan yang sebaiknya dimatikan
- Potensi privilege escalation (SUID, sudoers)
- Cron job mencurigakan

Data:
{data}

### Response:""",

    "network": """### Instruction:
Anda adalah ELISAR, ahli keamanan jaringan. Berikut adalah data port terbuka, koneksi aktif, dan aturan firewall dari sebuah server. Analisis data ini dan identifikasi:

- Port yang terbuka ke publik yang seharusnya tidak terbuka
- Layanan dengan versi usang/rentan (berdasarkan banner jika ada)
- Aturan firewall yang terlalu longgar
- Koneksi mencurigakan ke IP asing
- Rekomendasi untuk membatasi akses (misal: dengan iptables atau fail2ban)

Data:
{data}

### Response:""",

    "logs": """### Instruction:
Anda adalah ELISAR, ahli respons insiden. Berikut adalah cuplikan log sistem (auth, kernel, syslog) dari 1 jam terakhir. Analisis dan cari indikasi:

- Percobaan brute force (banyak gagal login)
- Aktivitas sudo mencurigakan
- Error pada layanan penting
- Potensi serangan (misal: SQL injection, file inclusion dari log web – jika ada)
- Rekomendasi tindakan cepat

Data:
{data}

### Response:""",

    "full": """### Instruction:
Anda adalah ELISAR, konsultan keamanan senior. Berikut adalah data lengkap dari sebuah server Linux: informasi sistem, user, izin, layanan, jaringan, cron, log, dan indikator mencurigakan. Lakukan analisis komprehensif:

1. **Temuan kritis** (critical): segera diperbaiki.
2. **Temuan sedang** (medium): perlu dijadwalkan perbaikan.
3. **Temuan rendah** (low): best practice yang belum diterapkan.
4. **Rekomendasi konkret** (sertakan perintah jika perlu).
5. **Kesimpulan** tingkat keamanan server secara umum.

Data:
{data}

### Response:"""
    }
}

def read_data_folder(folder):
    """Membaca semua file .txt dalam folder dan menggabungkannya."""
    files = sorted(glob.glob(os.path.join(folder, "*.txt")))
    data = []
    for f in files:
        with open(f, 'r', encoding='utf-8', errors='ignore') as fp:
            content = fp.read().strip()
            if content:
                data.append(f"--- {os.path.basename(f)} ---\n{content}")
    return "\n\n".join(data)

def call_elisar(prompt):
    """Memanggil ELISAR via llama.cpp dan mengembalikan output."""
    prompt_file = "/tmp/elisar_prompt.txt"
    with open(prompt_file, 'w') as f:
        f.write(prompt)
    
    cmd = [
        LLAMA_CPP,
        "-m", MODEL_PATH,
        "--file", prompt_file,
        "--temp", str(TEMP),
        "-n", str(MAX_TOKENS),
        "--no-display-prompt"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        return "Error: Analisis memakan waktu terlalu lama."
    except Exception as e:
        return f"Error: {str(e)}"
    finally:
        if os.path.exists(prompt_file):
            os.remove(prompt_file)

def main():
    parser = argparse.ArgumentParser(description="Analisis data server dengan ELISAR")
    parser.add_argument("folder", help="Folder hasil ekstraksi data (berisi file .txt)")
    parser.add_argument("--type", choices=PROMPT_TEMPLATES.keys(), default="full",
                        help="Tipe analisis: system, network, logs, full (default)")
    args = parser.parse_args()

    if not os.path.isdir(args.folder):
        print(f"Error: folder '{args.folder}' tidak ditemukan.")
        sys.exit(1)

    print(f"📂 Membaca data dari {args.folder}...")
    data = read_data_folder(args.folder)
    if not data:
        print("Tidak ada data ditemukan.")
        sys.exit(1)
    
    print(f"🧠 Membangun prompt untuk analisis tipe: {args.type}")
    prompt = PROMPT_TEMPLATES[args.type].format(data=data)
    
    print("⏳ Memanggil ELISAR... (bisa memakan waktu beberapa detik hingga menit)")
    response = call_elisar(prompt)
    
    print("\n" + "="*60)
    print("📋 HASIL ANALISIS ELISAR")
    print("="*60)
    print(response)
    print("="*60)

    # Simpan hasil ke file
    out_file = f"elisar_result_{args.type}_{os.path.basename(args.folder)}.txt"
    with open(out_file, 'w') as f:
        f.write(response)
    print(f"\n💾 Hasil juga disimpan di: {out_file}")

if __name__ == "__main__":
    main()
