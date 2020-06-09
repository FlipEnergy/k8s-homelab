SHELL := /bin/bash
helm := microk8s helm3
kubectl := microk8s kubectl

k8s-dashboard-init:
	$(helm) repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/ \
	$(kubectl) create namespace kubernetes-dashboard
	make k8s-dashboard-upgrade
	
k8s-dashboard-upgrade:
	$(helm) -n kubernetes-dashboard upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -f helm-charts/k8s-dashboard-values.yaml --install --wait
