#!/bin/sh
set -e

IMAGE="visitor-server:stable"
NAME="visitor-server"
APP_DIR="/volume1/docker/visitor-app"
DATA_DIR="$APP_DIR/data"

# 스크립트 시작 시 sudo 비밀번호를 미리 입력받아 캐시
sudo -v
# 타이머 대기 중 sudo 캐시가 만료되지 않도록 갱신
_keep_sudo_alive() {
  while true; do
    sudo -n true 2>/dev/null
    sleep 50
  done
}

# 인자로 "몇 분 후" 실행 지정 가능: ./restart_docker.sh 30  (30분 후 실행)
if [ -n "$1" ]; then
  DELAY_MIN="$1"
  TARGET_EPOCH=$(( $(date +%s) + DELAY_MIN * 60 ))
  TARGET_TIME=$(date -d "@$TARGET_EPOCH" "+%H:%M:%S" 2>/dev/null || date -r "$TARGET_EPOCH" "+%H:%M:%S")
  echo "[restart] scheduled in ${DELAY_MIN}min (around ${TARGET_TIME})"
  _keep_sudo_alive &
  SUDO_KEEPER_PID=$!
  trap "kill $SUDO_KEEPER_PID 2>/dev/null" EXIT
  while true; do
    NOW_EPOCH=$(date +%s)
    if [ "$NOW_EPOCH" -ge "$TARGET_EPOCH" ]; then
      break
    fi
    REMAIN=$(( TARGET_EPOCH - NOW_EPOCH ))
    echo "[restart] waiting... ${REMAIN}s remaining"
    sleep 30
  done
  echo "[restart] time reached, proceeding"
fi

echo "[restart] stopping old container"
sudo docker rm -f "$NAME" 2>/dev/null || true

echo "[restart] building image"
cd "$APP_DIR"
sudo docker build --no-cache -t "$IMAGE" -f Dockerfile .

echo "[restart] starting container with bind mount"
sudo docker run -d \
  --name "$NAME" \
  -p 8803:8803 \
  -e TZ=Asia/Seoul \
  -e PORT=8803 \
  -v "$DATA_DIR":/app/data \
  "$IMAGE"

echo "[restart] done"
