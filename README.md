# gitops-repo

Repo GitOps de CrediScore (`scoring-api`). Estructura Kustomize: `base/` + `overlays/{dev,prod}`.
Argo CD observa `overlays/dev` y sincroniza el cluster automáticamente. El CI del
[repo app](https://github.com/4Noisy/-equipo-lospapus--crediscore-) actualiza el tag de dev con un
commit directo y abre un PR para prod.

Probar localmente: `kubectl kustomize overlays/dev`

## Argo CD

**Sin instalar nada:** Code → Codespaces → Create codespace on main, y en la terminal:

    bash scripts/argocd-up.sh

Al final muestra la contraseña de `admin`. La UI queda en el puerto 8080 (pestaña PORTS) → `/applications`.

**A mano, en un cluster propio:**

    kubectl create namespace argocd
    kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl apply -f argocd/application.yaml

**Si la contraseña de `admin` no funciona**, se reemplaza por una conocida (aquí `crediscore2026`):

    HASH=$(docker run --rm httpd:2.4-alpine htpasswd -nbBC 10 "" crediscore2026 | tr -d ':\n')
    kubectl -n argocd patch secret argocd-secret -p "{\"stringData\":{\"admin.password\":\"$HASH\",\"admin.passwordMtime\":\"$(date +%FT%T%Z)\"}}"
