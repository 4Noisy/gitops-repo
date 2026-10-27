# lospapus-gitops

Repo GitOps de CrediScore (`scoring-api`). Estructura Kustomize: `base/` + `overlays/{dev,prod}`.
Argo CD observa `overlays/dev` y sincroniza el cluster automáticamente.

Instalar Argo CD y crear la app:

    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl apply -f argocd/application.yaml

Probar localmente: `kubectl kustomize overlays/dev`
