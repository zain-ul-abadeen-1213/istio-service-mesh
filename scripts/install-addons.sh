#!/usr/bin/env bash
# Install the observability addons (Prometheus, Grafana, Jaeger, Kiali)
# from the Istio samples folder and wait for Kiali.
set -e
ISTIO_HOME="$HOME/istio-1.24.0"

kubectl apply -f "$ISTIO_HOME/samples/addons"
kubectl rollout status deployment/kiali -n istio-system --timeout=600s
kubectl -n istio-system get pods
echo
echo "Open Kiali:  $ISTIO_HOME/bin/istioctl dashboard kiali"
echo "Open Jaeger: $ISTIO_HOME/bin/istioctl dashboard jaeger"
