# FleetDM on Kubernetes

Deploys FleetDM with MySQL and Redis on a local [kind](https://kind.sigs.k8s.io/) cluster using Helm.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm 3](https://helm.sh/docs/intro/install/)

## Install
```bash
make cluster   # creates a 3-node kind cluster with ingress port mappings
make install   # deploys FleetDM, MySQL and Redis via Helm
```

On first install, database migrations run automatically before Fleet starts — allow ~60s for MySQL to initialise.

## Access

Via port-forward:
```bash
kubectl port-forward svc/fleetdm-fleetdm 8080:8080 -n fleet
# open http://localhost:8080
```

Via ingress (enabled by default in `values.dev.yaml`):
```bash
echo "127.0.0.1 fleet.local" | sudo tee -a /etc/hosts
# open http://fleet.local
```

Both the Fleet UI and osquery agent enrollment (`/api/v1/osquery/...`) are served through the same ingress.

## Verify
```bash
# all three pods should show Running and Ready
kubectl get pods -n fleet

# Fleet health check
curl http://fleet.local/healthz

# Agent enrollment endpoint — 405 confirms Fleet is reachable
curl -v http://fleet.local/api/v1/osquery/enroll
```

## Teardown
```bash
make uninstall
```

## Configuration

The chart has two values files:
- `values.yaml` — defaults and structure.
- `values.dev.yaml` — local overrides (ingress, credentials). 

MySQL and Redis addresses are auto-computed from the Helm release name so you don't need to set them manually. Override `fleet.mysqlAddress` or `fleet.redisAddress` only if using external services.

In production, don't put credentials in values files — use [External Secrets Operator](https://external-secrets.io) or [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) to provision the secret before deploying. The chart skips creating the secret when no password is set, expecting it to already exist in the cluster.

## CI

The GitHub Actions pipeline lints the chart on every PR. Merging to `main` triggers a release if `version` in `Chart.yaml` has changed

The chart is published to GitHub Pages and can be installed directly:
```bash
helm repo add fleetdm https://swif2er.github.io/fleetdm-deploy
helm repo update
helm install fleetdm fleetdm/fleetdm -f values.dev.yaml
```

To release a new version — bump `version` in `Chart.yaml` and merge to `main`.
