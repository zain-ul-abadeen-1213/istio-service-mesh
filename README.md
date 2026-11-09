# Service Mesh with Istio — mTLS, Traffic Splitting and Tracing

An Istio service mesh running on a local 3-node [kind](https://kind.sigs.k8s.io/)
cluster: automatic Envoy sidecar injection, encrypted service-to-service
traffic with **strict mTLS**, an **80/20 traffic split** between two versions
of a service, and the whole mesh made visible in the **Kiali** dashboard.

The workload is **Bookinfo**, Istio's official sample application
(productpage → details / ratings / reviews v1–v3) — the standard learning
application for Istio, used the same way in the official documentation.

## Architecture

```
User ──► Istio Ingress Gateway (Envoy)
                    │
              VirtualService ── productpage
                    │
        ┌───────────┼────────────┐
     details     reviews        ratings
               v1 (80%) · v3 (20%)
        every pod: app container + Envoy sidecar
        all service-to-service traffic: mTLS (STRICT)

Control plane: istiod · Observability: Kiali graph + Jaeger traces
```

## What the mesh adds — without touching app code

- **Sidecar injection** — label the namespace `istio-injection=enabled` and
  every new pod automatically gets an Envoy proxy next to the app (pods show
  READY **2/2**). All traffic in and out flows through the proxy.
- **mTLS STRICT** — a `PeerAuthentication` policy makes encryption mandatory
  inside the namespace. The proxies hold certificates and do the TLS
  handshake; a client without a sidecar is rejected. The application itself
  knows nothing about it.
- **Traffic splitting** — a `DestinationRule` names the versions (subsets)
  of `reviews`; a `VirtualService` then sends **80%** of requests to v1
  (no stars) and **20%** to v3 (red stars). Refreshing the product page
  shows roughly 2 red-star reviews in every 10 — weighted routing is
  probabilistic, not exact.
- **Kiali** — renders the live service graph (which service calls which,
  with traffic rates) from the proxies' telemetry; **Jaeger** shows
  individual request traces across services.

## Run it

```bash
bash scripts/setup.sh            # Istio install + Bookinfo + gateway
bash scripts/install-addons.sh   # Prometheus, Grafana, Jaeger, Kiali
kubectl apply -f manifests/reviews-split.yaml   # 80/20 split
kubectl apply -f manifests/mtls-strict.yaml     # mTLS STRICT
bash scripts/generate-traffic.sh                # light up the Kiali graph
~/istio-1.24.0/bin/istioctl dashboard kiali     # the mesh map
bash verify.sh
```

The Bookinfo page itself is reached through the ingress gateway — on kind
that means a port-forward (kind only maps ports declared at cluster
creation):

```bash
kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80
# open http://localhost:8080/productpage  →  "Simple Bookstore App"
```

## Layout

```
manifests/   bookinfo-gateway.yaml · reviews-split.yaml · mtls-strict.yaml
scripts/     setup.sh · install-addons.sh · generate-traffic.sh
verify.sh    seven checks: control plane, injection, 2/2 pods, split
             objects, mTLS policy, Kiali, productpage via gateway
docs/        run screenshots
```

## Cleanup

```bash
kubectl delete -f ~/istio-1.24.0/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f manifests/
~/istio-1.24.0/bin/istioctl uninstall --purge -y
kubectl delete namespace istio-system
```

## Author

Zain Ul Abdin — Zain Tech Automation Solutions
