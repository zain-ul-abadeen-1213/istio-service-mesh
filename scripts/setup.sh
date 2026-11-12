#!/usr/bin/env bash
# Setup: download Istio 1.24.0 (if needed), install demo profile on the
# kind cluster, enable sidecar injection on the default namespace and
# deploy the Bookinfo sample app + gateway.
set -e
cd "$(dirname "$0")/.."

ISTIO_VERSION=1.24.0
ISTIO_HOME="$HOME/istio-$ISTIO_VERSION"
ISTIOCTL="$ISTIO_HOME/bin/istioctl"

echo "== 1/5 Istio download (skipped if already present) =="
if [ ! -x "$ISTIOCTL" ]; then
  (cd "$HOME" && curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -)
fi
"$ISTIOCTL" version --remote=false

echo "== 2/5 Install Istio (demo profile) on the cluster =="
kubectl config use-context kind-zaintech
"$ISTIOCTL" install --set profile=demo -y
kubectl -n istio-system get pods

echo "== 3/5 Sidecar injection ON for the default namespace =="
kubectl label namespace default istio-injection=enabled --overwrite
kubectl get namespace -L istio-injection

echo "== 4/5 Deploy Bookinfo sample app =="
kubectl apply -f "$ISTIO_HOME/samples/bookinfo/platform/kube/bookinfo.yaml"
echo "waiting for Bookinfo pods (first image pulls can take a while)..."
# Wait on the deployment first: a bare `kubectl wait` on pods errors out with
# "no matching resources found" if it runs before the pod object exists.
kubectl rollout status deployment/productpage-v1 -n default --timeout=600s
kubectl wait --for=condition=ready pod -l app=productpage -n default --timeout=120s
kubectl get pods -n default

echo "== 5/5 Gateway + VirtualService for outside access =="
kubectl apply -f manifests/bookinfo-gateway.yaml

echo
echo "Done. Bookinfo page (via port-forward):"
echo "  kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80"
echo "  then open http://localhost:8080/productpage"
echo "Next: bash scripts/install-addons.sh   (Kiali/Jaeger - heavy downloads)"
