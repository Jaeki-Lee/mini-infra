#!/bin/bash

set -e

# 복원할 스냅샷 경로 지정 (입력받거나 기본 사용)
SNAPSHOT_PATH="${1:-/root/k8s/etcd/etcd-backup-latest.db}"
ETCD_DATA_DIR="/var/lib/etcd"
BACKUP_DIR="/var/lib/etcd-backup-$(date +%Y%m%d-%H%M%S)"

# etcdctl 환경변수 제거 (옵션 충돌 방지)
unset ETCDCTL_CACERT ETCDCTL_CERT ETCDCTL_KEY

echo "🛑 기존 etcd 데이터 디렉토리를 백업합니다: $BACKUP_DIR"
mv "$ETCD_DATA_DIR" "$BACKUP_DIR"

echo "📦 etcd snapshot에서 복원합니다: $SNAPSHOT_PATH"

ETCDCTL_API=3 etcdctl snapshot restore "$SNAPSHOT_PATH" \
  --data-dir "$ETCD_DATA_DIR"

echo "🔄 etcd 및 kube-apiserver 재시작 중..."
systemctl restart etcd
systemctl restart kube-apiserver

echo "✅ 복원이 완료되었습니다!"
