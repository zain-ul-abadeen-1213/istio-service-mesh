#!/usr/bin/env bash
# Generate traffic through the ingress gateway so Kiali's graph lights up.
# Starts its own temporary port-forward, sends N requests, cleans up.
set -e
N="${1:-200}"

kubectl -n istio-system port-forward svc/istio-ingressgateway 18080:80 >/dev/null 2>&1 &
PF_PID=$!
sleep 4
trap 'kill $PF_PID 2>/dev/null' EXIT

echo "Sending $N requests to /productpage ..."
for i in $(seq 1 "$N"); do
  curl -s -o /dev/null "http://localhost:18080/productpage"
done
echo "Done. Open Kiali and look at the Graph for the default namespace."
