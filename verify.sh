#!/usr/bin/env bash
# Verify the Istio service mesh setup end to end.
pass=0; fail=0
check() { if eval "$2" >/dev/null 2>&1; then echo "PASS: $1"; pass=$((pass+1)); else echo "FAIL: $1"; fail=$((fail+1)); fi }

check "istiod is available in istio-system" \
  "kubectl -n istio-system get deployment istiod -o jsonpath='{.status.availableReplicas}' | grep -E '^[1-9]'"
check "default namespace has istio-injection=enabled" \
  "kubectl get namespace default -L istio-injection --no-headers | grep -q enabled"
check "all Bookinfo pods are 2/2 (app + Envoy sidecar)" \
  "[ \$(kubectl get pods -n default --no-headers | grep -cE '^[a-z-]+-v[0-9]-[a-z0-9-]+ +2/2 +Running') -ge 6 ]"
check "traffic split objects exist (DestinationRule + VirtualService reviews)" \
  "kubectl -n default get destinationrule reviews && kubectl -n default get virtualservice reviews"
check "mTLS PeerAuthentication exists in default" \
  "kubectl -n default get peerauthentication default"
check "Kiali is available in istio-system" \
  "kubectl -n istio-system get deployment kiali -o jsonpath='{.status.availableReplicas}' | grep -E '^[1-9]'"

# The productpage check goes through a temporary port-forward of the
# ingress gateway (kind only maps ports declared at cluster creation).
kubectl -n istio-system port-forward svc/istio-ingressgateway 18081:80 >/dev/null 2>&1 &
PF_PID=$!
sleep 4
if curl -s http://localhost:18081/productpage | grep -q 'Simple Bookstore App'; then
  echo "PASS: productpage answers through the gateway (Simple Bookstore App)"; pass=$((pass+1))
else
  echo "FAIL: productpage answers through the gateway (Simple Bookstore App)"; fail=$((fail+1))
fi
kill $PF_PID 2>/dev/null

echo
echo "Passed: $pass  Failed: $fail"
[ "$fail" -eq 0 ]
