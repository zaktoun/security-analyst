# Analisis Docker
python3 elisar_multi_platform.py --module docker

# Analisis CI/CD di repository tertentu
python3 elisar_multi_platform.py --module cicd --target /path/to/repo

# Analisis AWS (gunakan file yang sudah dikumpulkan)
python3 elisar_multi_platform.py --module aws --skip-collect --data-file aws_data_20250225.tar.gz
