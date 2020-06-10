SHELL := /bin/bash
helm := microk8s helm3
kubectl := microk8s kubectl

init:
	make add-repos
	make k8s-dashboard-init
	make kube-ops-view-init

add-repos:
	$(helm) repo add stable https://kubernetes-charts.storage.googleapis.com
	$(helm) repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	$(helm) repo update

k8s-dashboard-init:
	$(kubectl) create namespace kubernetes-dashboard
	make k8s-dashboard-upgrade
	
k8s-dashboard-upgrade:
	$(helm) -n kubernetes-dashboard upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -f helm-charts/k8s-dashboard-values.yaml --install --wait

dash:
	@make k8s-dashboard-upgrade

token:
	@$(kubectl) -n kubernetes-dashboard describe secret $$($(kubectl) -n kubernetes-dashboard get secret | grep admin-user | awk '{print $$1}') | grep token: | awk '{print $$2}'

kube-ops-view-init:
	$(kubectl) create namespace kube-ops-dashboard
	make kube-ops-view-upgrade

kube-ops-view-upgrade:
	$(helm) -n kube-ops-dashboard upgrade my-kube-ops-dash stable/kube-ops-view -f helm-charts/kube-ops-dash-values.yaml --install --wait

kube:
	@make kube-ops-view-upgrade
