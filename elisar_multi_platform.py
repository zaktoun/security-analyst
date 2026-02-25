#!/usr/bin/env python3
"""
elisar_multi_platform.py – Analisis multi-platform dengan ELISAR
Fungsi: Memilih platform yang akan dianalisis dan memanggil modul yang sesuai
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path

# Dictionary modul yang tersedia
MODULES = {
    "linux": {
        "collector": "collect_for_elisar.sh",
        "analyzer_type": "system",
        "description": "Server Linux on-premise"
    },
    "docker": {
        "collector": "collect_docker.sh",
        "analyzer_type": "docker",
        "description": "Docker containers dan images"
    },
    "cicd": {
        "collector": "collect_cicd.sh",
        "analyzer_type": "cicd",
        "description": "CI/CD pipeline (GitLab, GitHub, Jenkins)"
    },
    "windows": {
        "collector": "collect_windows.ps1",
        "analyzer_type": "windows",
        "description": "Windows Server"
    },
    "aws": {
        "collector": "collect_aws.sh",
        "analyzer_type": "cloud",
        "description": "AWS Cloud environment"
    },
    "azure": {
        "collector": "collect_azure.sh",
        "analyzer_type": "cloud",
        "description": "Azure Cloud environment"
    }
}

def run_collector(module, target=None):
    """Menjalankan script collector untuk modul tertentu"""
    collector = MODULES[module]["collector"]
    
    if not os.path.exists(collector):
        print(f"❌ Collector {collector} tidak ditemukan")
        return None
    
    print(f"📡 Menjalankan collector untuk {module}...")
    
    if target and module in ["cicd"]:
        cmd = [f"./{collector}", target]
    else:
        cmd = [f"./{collector}"]
    
    try:
        subprocess.run(cmd, check=True)
        # Cari file hasil terbaru
        latest = sorted(Path(".").glob(f"*{module}*.tar.gz"), key=os.path.getmtime)[-1]
        return str(latest)
    except subprocess.CalledProcessError as e:
        print(f"❌ Gagal menjalankan collector: {e}")
        return None
    except IndexError:
        print("❌ Tidak menemukan file hasil")
        return None

def analyze_with_elisar(data_file, module):
    """Menganalisis data dengan ELISAR"""
    # Ekstrak file
    extract_dir = data_file.replace(".tar.gz", "")
    subprocess.run(["tar", "-xzf", data_file])
    
    # Panggil elisar_analyzer.py
    analyzer_type = MODULES[module]["analyzer_type"]
    cmd = ["python3", "elisar_analyzer.py", extract_dir, "--type", analyzer_type]
    
    print(f"🧠 Menganalisis dengan ELISAR (tipe: {analyzer_type})...")
    subprocess.run(cmd)
    
    # Bersihkan
    subprocess.run(["rm", "-rf", extract_dir])

def main():
    parser = argparse.ArgumentParser(description="ELISAR Multi-Platform Analyzer")
    parser.add_argument("--module", choices=MODULES.keys(), required=True,
                       help="Platform yang akan dianalisis")
    parser.add_argument("--target", help="Target spesifik (untuk CI/CD: path repo)")
    parser.add_argument("--skip-collect", action="store_true",
                       help="Lewati koleksi data, gunakan file yang sudah ada")
    parser.add_argument("--data-file", help="File data yang sudah ada (jika skip-collect)")
    
    args = parser.parse_args()
    
    print("="*60)
    print(f"🔐 ELISAR Multi-Platform Analyzer - Modul: {args.module}")
    print("="*60)
    print(f"📋 Deskripsi: {MODULES[args.module]['description']}")
    print()
    
    if not args.skip_collect:
        data_file = run_collector(args.module, args.target)
        if not data_file:
            sys.exit(1)
    else:
        if not args.data_file:
            print("❌ Jika --skip-collect, harus menyertakan --data-file")
            sys.exit(1)
        data_file = args.data_file
    
    analyze_with_elisar(data_file, args.module)
    
    print("\n✅ Analisis selesai!")

if __name__ == "__main__":
    main()
