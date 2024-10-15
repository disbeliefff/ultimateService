GOLANG          := golang:1.22.7
ALPINE          := alpine:3.20
KIND            := kindest/node:v1.31.0
POSTGRES        := postgres:16.4
GRAFANA         := grafana/grafana:11.1.0
PROMETHEUS      := prom/prometheus:v2.54.0
TEMPO           := grafana/tempo:2.5.0
LOKI            := grafana/loki:3.1.0
PROMTAIL        := grafana/promtail:3.1.0

KIND_CLUSTER    := starter-cluster
NAMESPACE       := sales-system
SERVICE-NAME    := sales-api
AUTH_APP        := auth
BASE_IMAGE_NAME := localhost/disbeliefff
VERSION         := 0.0.1
SERVICE_IMAGE   := $(BASE_IMAGE_NAME)/service:$(VERSION)
METRICS_IMAGE   := $(BASE_IMAGE_NAME)/metrics:$(VERSION)
#AUTH_IMAGE      := $(BASE_IMAGE_NAME)/$(AUTH_APP):$(VERSION)


run:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go

dev-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \

		--config zarf/k8s/dev/kind-config.yaml

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

dev-status-all:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

dev-status:
	watch -n 2 kubectl get pods -o wide --all-namespaces

all: service

service:
	docker build \
        -f zarf/docker/service.Dockerfile \
        -t localhost/disbeliefff:0.0.1 \
        --build-arg BUILD_REF=0.0.1 \
        --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
        .
dev-load:
	kind load docker-image localhost/disbeliefff:0.0.1 --name $(KIND_CLUSTER)

dev-apply:
	kustomize build zarf/k8s/dev/sales | kubectl apply -f -
	kubectl wait pods --namespace=$(NAMESPACE) --selector app=$(SALES_APP) --timeout=120s --for=condition=Ready

dev-logs:
	kubectl logs --namespace=$(NAMESPACE) -l app=$(SALES_APP) -f --tail=100 -c init-migrate-seed

dev-describe-deployment:
	kubectl describe deployment --namespace=$(NAMESPACE) $(SALES_APP)

dev-describe-sales:
	kubectl describe pod --namespace=$(NAMESPACE) -l app=$(SALES_APP)

tidy:
	go mod tidy && go mod vendor

