{{- define "argocd.app" }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ .app.name }}-app
  namespace: {{ .global.argoCD }}
spec:
  project: default
  source:
    repoURL: {{ .global.repoUrl }}
    targetRevision: {{ .global.targetRevision }}
    path: {{ .app.gitrepoPath }}
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ .global.namespace }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
{{- end }}
