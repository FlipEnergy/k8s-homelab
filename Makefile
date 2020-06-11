SHELL := /bin/bash
manage_namespace := kubernetes-manage
folding_namespace := folding-at-home

init:
	kubectl apply -f config_maps/coredns.yml
	make add-repos
	make k8s-dashboard-upgrade
	make kube-ops-view-upgrade

add-repos:
	helm repo add stable https://kubernetes-charts.storage.googleapis.com
	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	helm repo add brannon https://helm.brannon.online
	helm repo update

# Dashboards

dash:
	kubectl get namespace $(manage_namespace) || kubectl create namespace $(manage_namespace)
	helm upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -n $(manage_namespace) -f helm_vars/k8s-dashboard-values.yaml --install --wait

token:
	@kubectl  describe secret -n $(manage_namespace) $$(kubectl -n $(manage_namespace) get secret | grep default-token | awk '{print $$1}') | grep token: | awk '{print $$2}' | clip.exe

kube:
	kubectl get namespace $(manage_namespace) || kubectl create namespace $(manage_namespace)
	helm upgrade my-kube-ops-dash stable/kube-ops-view -n $(manage_namespace) -f helm_vars/kube-ops-dash-values.yaml --install --wait

# Compute

f@h:
	kubectl get namespace $(folding_namespace) || kubectl create namespace $(folding_namespace)
	helm secrets upgrade folding-at-home brannon/folding-at-home -n $(folding_namespace) -f helm_vars/folding-at-home-values.yaml -f helm_secrets/secrets.folding-at-home.yaml --install --wait

clean:
	helm uninstall -n $(manage_namespace) $$(helm -n $(manage_namespace) list --all | grep -v NAME | awk '{print $$1}')
