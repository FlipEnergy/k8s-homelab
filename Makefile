SHELL := /bin/bash
manage_namespace := kubernetes-manage

init:
	kubectl apply -f config-maps/coredns.yml
	make add-repos
	make k8s-dashboard-upgrade
	make kube-ops-view-upgrade

add-repos:
	helm repo add stable https://kubernetes-charts.storage.googleapis.com
	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	helm repo update

dash:
	kubectl get namespace $(manage_namespace) || kubectl create namespace $(manage_namespace)
	helm -n $(manage_namespace) upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -f helm-charts/k8s-dashboard-values.yaml --install --wait

token:
	@kubectl -n $(manage_namespace) describe secret $$(kubectl -n $(manage_namespace) get secret | grep default-token | awk '{print $$1}') | grep token: | awk '{print $$2}' | clip.exe

kube:
	kubectl get namespace $(manage_namespace) || kubectl create namespace $(manage_namespace)
	helm -n $(manage_namespace) upgrade my-kube-ops-dash stable/kube-ops-view -f helm-charts/kube-ops-dash-values.yaml --install --wait

clean:
	helm -n $(manage_namespace) uninstall $$(helm -n $(manage_namespace) list --all | grep -v NAME | awk '{print $$1}')
