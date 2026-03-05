# Variables
CLUSTER_NAME    := local-cluster
CLUSTER_CONFIG  := kind-config.yaml
HELM_RELEASE    := fleetdm
HELM_CHART_PATH := ./fleetdm
NAMESPACE       := fleet
DEV_VALUES      := $(HELM_CHART_PATH)/values.dev.yaml

# Create local cluster (Kind)
.PHONY: cluster
cluster:
	@echo "Creating Kind cluster '$(CLUSTER_NAME)'..."
	kind create cluster --config $(CLUSTER_CONFIG) --name $(CLUSTER_NAME)
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=180s
	@echo "Cluster '$(CLUSTER_NAME)' created."

# Install the Helm chart
.PHONY: install
install:
	@echo "Installing Helm chart '$(HELM_CHART_PATH)' as release '$(HELM_RELEASE)'..."
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART_PATH) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		$(if $(wildcard $(DEV_VALUES)), -f $(DEV_VALUES),)
	@echo "Helm chart installed."

# Remove all deployed resources
.PHONY: uninstall
uninstall:
	@echo "Uninstalling Helm release '$(HELM_RELEASE)'..."
	helm uninstall $(HELM_RELEASE) --namespace $(NAMESPACE) || true
	@echo "Deleting Kind cluster '$(CLUSTER_NAME)'..."
	kind delete cluster --name $(CLUSTER_NAME)
	@echo "Cleanup completed."