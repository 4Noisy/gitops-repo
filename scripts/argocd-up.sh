#!/usr/bin/env bash
# Levanta un cluster local (minikube), instala Argo CD, crea la Application
# scoring-api-dev y deja la UI en http://localhost:8080.
# Pensado para GitHub Codespaces (ver .devcontainer/); sirve igual en cualquier
# maquina con Docker, kubectl y minikube.
set -euo pipefail

minikube status >/dev/null 2>&1 || minikube start --cpus=2 --memory=4096

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Antes de reiniciar argocd-server se espera a que el primer pod genere la
# contrasena de admin; si se reinicia antes, dos pods pueden generar contrasenas
# distintas y la que se muestra al final no sirve para entrar.
kubectl -n argocd rollout status deployment argocd-server --timeout=300s
until kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; do sleep 5; done

# UI por HTTP: el port-forward del Codespace no maneja bien el certificado autofirmado.
# Solo para el cluster local del lab; en un cluster real se deja TLS.
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge \
  -p '{"data":{"server.insecure":"true"}}'
kubectl -n argocd rollout restart deployment argocd-server
kubectl -n argocd rollout status deployment argocd-server --timeout=300s

kubectl apply -f argocd/application.yaml

echo "Esperando Synced/Healthy (hasta 10 min)..."
estado=""
for _ in $(seq 1 60); do
  estado=$(kubectl -n argocd get application scoring-api-dev \
    -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null || true)
  echo "  ${estado:-sin estado aun}"
  [ "$estado" = "Synced/Healthy" ] && break
  sleep 10
done
[ "$estado" = "Synced/Healthy" ] || echo "No llego a Synced/Healthy: revisa 'kubectl -n crediscore get pods'."

echo
echo "Usuario: admin"
printf "Contrasena: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
echo "UI en http://localhost:8080/applications (en Codespaces: pestana PORTS -> 8080). Ctrl+C para cerrar."
echo "Si la contrasena no funciona, ver README (seccion Argo CD)."
kubectl port-forward svc/argocd-server -n argocd 8080:80
