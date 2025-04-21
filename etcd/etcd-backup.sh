#!/bin/bash

set -e

# 백업 저장 경로
BACKUP_DIR="/root/k8s/etcd"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/etcd-backup-${TIMESTAMP}.db"

# etcd 인증 경로 (kubeadm 기준)
# export ETCDCTL_API=3
# export ETCDCTL_CACERT="/etc/kubernetes/pki/etcd/ca.crt"
# export ETCDCTL_CERT="/etc/kubernetes/pki/etcd/server.crt"
# export ETCDCTL_KEY="/etc/kubernetes/pki/etcd/server.key"

# 디렉토리 없으면 생성
mkdir -p "$BACKUP_DIR"

echo "📦 etcd snapshot을 저장합니다: $BACKUP_FILE"

# 스냅샷 저장
etcdctl snapshot save "$BACKUP_FILE" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert="/etc/kubernetes/pki/etcd/ca.crt" \
  --cert="/etc/kubernetes/pki/etcd/server.crt" \
  --key="/etc/kubernetes/pki/etcd/server.key"

echo "✅ etcd snapshot 저장 완료!"
