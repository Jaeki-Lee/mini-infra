# 🧩 K8s ToyProject - 온프레미스 인프라 워크플로우

이 프로젝트는 Kubernetes 기반 온프레미스 인프라를 구축하고 자동 배포까지 완성하는 과정을 설명합니다.
사용된 주요 노드는 다음과 같습니다:
- `master1`
- `node1`, `node2`, `node3`
- `dnf-dns` (NFS + DNS 서버)
- `harbor` (프라이빗 이미지 레지스트리)

---

## 1. 🚀 Kubernetes 클러스터 구성
- `kubeadm`으로 마스터 초기화
- 워커 노드를 클러스터에 조인
- 네트워크 플러그인: **Calico** 사용

## 2. 🌐 LoadBalancer + Ingress 설정
- **MetalLB**를 통해 외부 접근용 LoadBalancer IP 할당 (예: `192.168.3.100`)
- **NGINX Ingress Controller** 설치
- `www.aws9.pri/shop`, `/blog`, `/news` 경로 기반 Ingress 라우팅 구성

## 3. 🐳 Harbor 레지스트리 구축
- `dnf-dns` 노드에 HTTP 방식으로 Harbor 설치
- 레지스트리 도메인: `hub.aws9.pri`
- Docker의 `insecure-registries` 설정을 통해 이미지 push/pull 가능
- 애플리케이션 이미지를 Harbor에 저장 후 K8s에서 pull하여 사용

## 4. 🌍 내부 DNS 서버 구축 (BIND)
- `dnf-dns`에 BIND 기반 DNS 서버 설정
- Zone: `aws9.pri`
- 주요 레코드: `hub.aws9.pri`, `argocd.aws9.pri`, `www.aws9.pri`
- 각 노드 `/etc/resolv.conf` 수정하여 DNS 서버 지정

## 5. 📦 NFS + CSI 기반 동적 볼륨 구성
- `/shared` 경로를 NFS로 export (`dnf-dns` 서버)
- **nfs-csi-driver** 설치
- StorageClass: `aws9h-storage`, `ReadWriteMany`, `Immediate`
- 각 애플리케이션에서 PVC 생성 시 NFS에 디렉토리 자동 생성 및 마운트됨

## 6. 🔄 ArgoCD를 통한 자동 배포
- `argocd` 네임스페이스에 ArgoCD 설치
- LoadBalancer IP로 `argocd.aws9.pri` 접속 가능
- 각 앱 별로 Application manifest 작성
  - `automated` 동기화
  - `selfHeal` 자가 복구
  - `CreateNamespace=true` 옵션 포함

## 7. ⚖️ KEDA + HPA 오토스케일링 구성
- KEDA 설치
- 각 앱 별로 `ScaledObject` 정의:
  - `minReplica`: 1, `maxReplica`: 10
  - CPU 사용률 60% 초과 시 자동 스케일링
  - `cron` 기반으로 9:00~18:00엔 3개 유지, 그 외 시간은 1개로 줄어듦

## 8. 🧰 InitContainer로 NFS에 콘텐츠 복사
- 문제: NFS 마운트 시 컨테이너 이미지의 기본 콘텐츠(index.html 등)가 덮어써짐
- 해결: `InitContainer`를 이용해 index.html을 NFS로 복사 후 메인 컨테이너 실행

```yaml
initContainers:
- name: copy-index
  image: shop-nginx:v1
  command: ["/bin/sh", "-c"]
  args: ["cp /usr/share/nginx/html/index.html /mnt/index.html"]
  volumeMounts:
  - name: html
    mountPath: /mnt
```

## 9. 💾 etcd 백업 및 복원
- `etcdctl` 수동 설치
- **백업 스크립트:** `etcd-backup.sh`
  - `/root/k8s/etcd/etcd-backup-YYYYMMDD-HHMMSS.db` 형식으로 저장
- 일부 리소스를 삭제 후 복원 테스트
- **복원 스크립트:** `etcd-restore.sh`
  - `/var/lib/etcd` 디렉토리 백업 후 스냅샷 복원 → etcd + kube-apiserver 재시작

---
## 🚀 설치 방법
```bash
helm install mini-infra .
```
> 설치 전 DNS, NFS, Harbor 등은 사전 준비되어 있어야 합니다.

---
## ✅ 정리
이 프로젝트는 다음 기능을 포함한 완전한 온프레미스 Kubernetes 인프라를 구축합니다:
- 프라이빗 레지스트리
- 내부 DNS 도메인 라우팅
- 동적 NFS 볼륨 마운트
- GitOps 자동 배포
- 시간/부하 기반 오토스케일링
- Disaster Recovery (etcd 스냅샷 복원)
