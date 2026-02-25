#!/bin/bash
# collect_cicd.sh – Mengumpulkan data keamanan pipeline CI/CD

REPO_PATH="${1:-.}"  # Path ke repository, default current dir
OUTPUT_DIR="./cicd_data_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "[1/5] Mengumpulkan pipeline definition files..."
find "$REPO_PATH" -name ".gitlab-ci.yml" -o -name "Jenkinsfile" -o -name "*.github/workflows/*.yml" 2>/dev/null | while read file; do
    cp "$file" "$OUTPUT_DIR/$(basename $(dirname $file))_$(basename $file)" 2>/dev/null
done

echo "[2/5] Mengumpulkan dependency files..."
find "$REPO_PATH" -name "package.json" -o -name "requirements.txt" -o -name "pom.xml" -o -name "Gemfile" 2>/dev/null | while read file; do
    cp "$file" "$OUTPUT_DIR/deps_$(basename $(dirname $file))_$(basename $file)" 2>/dev/null
done

echo "[3/5] Mengekstrak credential usage (tanpa nilai)..."
grep -r -E "(password|secret|token|key|PASSWORD|SECRET|TOKEN|KEY)" "$REPO_PATH" 2>/dev/null | grep -v "node_modules" | grep -v "\.git" > "$OUTPUT_DIR/credential_patterns.txt"

echo "[4/5] Mengecek file .env atau konfigurasi sensitif..."
find "$REPO_PATH" -name ".env" -o -name "*.env" -o -name "secrets.yml" 2>/dev/null | while read file; do
    echo "File sensitif ditemukan: $file" >> "$OUTPUT_DIR/sensitive_files.txt"
    head -5 "$file" 2>/dev/null | sed 's/=.*/=REDACTED/' >> "$OUTPUT_DIR/sensitive_files.txt"
done

echo "[5/5] Membuat ringkasan struktur pipeline..."
find "$REPO_PATH" -type f -name "*.yml" -o -name "*.yaml" | grep -E "(gitlab|github|jenkins)" > "$OUTPUT_DIR/pipeline_files_list.txt"

tar -czf "cicd_data_$(date +%Y%m%d_%H%M%S).tar.gz" "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
echo "✅ Data CI/CD terkumpul"
