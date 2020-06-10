SHELL := /bin/bash
helm := microk8s helm3
kubectl := microk8s kubectl
manage_namespace := kubernetes-manage

init:
	$(kubectl) apply -f config-maps/coredns.yml 
	make add-repos
	$(kubectl) create namespace $(manage_namespace)
	make k8s-dashboard-upgrade
	make kube-ops-view-upgrade

add-repos:
	$(helm) repo add stable https://kubernetes-charts.storage.googleapis.com
	$(helm) repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	$(helm) repo update
	
k8s-dashboard-upgrade:
	$(helm) -n $(manage_namespace) upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -f helm-charts/k8s-dashboard-values.yaml --install --wait

dash:
	@make k8s-dashboard-upgrade

token:
	@$(kubectl) -n $(manage_namespace) describe secret $$($(kubectl) -n $(manage_namespace) get secret | grep default-token | awk '{print $$1}') | grep token: | awk '{print $$2}'

kube-ops-view-upgrade:
	$(helm) -n $(manage_namespace) upgrade my-kube-ops-dash stable/kube-ops-view -f helm-charts/kube-ops-dash-values.yaml --install --wait

kube:
	@make kube-ops-view-upgrade

clean:
	$(helm) -n $(manage_namespace) uninstall $$($(helm) -n $(manage_namespace) list --all | grep -v NAME | awk '{print $$1}')
