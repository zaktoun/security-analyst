#!/bin/bash
# collect_docker.sh – Mengumpulkan data keamanan Docker

OUTPUT_DIR="./docker_data_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "[1/6] Mengumpulkan informasi Docker system..."
docker version > "$OUTPUT_DIR/docker_version.txt"
docker info > "$OUTPUT_DIR/docker_info.txt"

echo "[2/6] Mengumpulkan daftar images..."
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" > "$OUTPUT_DIR/images_list.txt"
docker image ls --digests >> "$OUTPUT_DIR/images_list.txt"

echo "[3/6] Mengumpulkan informasi containers..."
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" > "$OUTPUT_DIR/containers_list.txt"
docker ps -a --format json > "$OUTPUT_DIR/containers_detail.json"

echo "[4/6] Mengumpulkan konfigurasi container (inspect)..."
for container in $(docker ps -a --format "{{.Names}}"); do
    docker inspect "$container" > "$OUTPUT_DIR/inspect_$container.json" 2>/dev/null
done

echo "[5/6] Mengumpulkan Docker Compose files (jika ada)..."
find / -name "docker-compose.yml" -o -name "docker-compose.yaml" 2>/dev/null | while read file; do
    cp "$file" "$OUTPUT_DIR/compose_$(basename $(dirname $file)).yaml" 2>/dev/null
done

echo "[6/6] Memeriksa kerentanan dengan Trivy (jika tersedia)..."
if command -v trivy &>/dev/null; then
    for image in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>"); do
        trivy image --severity HIGH,CRITICAL --no-progress "$image" > "$OUTPUT_DIR/trivy_$(echo $image | tr /: _).txt" 2>/dev/null &
    done
    wait
else
    echo "Trivy tidak ditemukan, lewati scan kerentanan" > "$OUTPUT_DIR/trivy_not_available.txt"
fi

tar -czf "docker_data_$(date +%Y%m%d_%H%M%S).tar.gz" "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
echo "✅ Data Docker terkumpul"
