SHELL := /bin/bash
dash_namespace := kubernetes-dashboard
kube_namespace := kube-ops-view
folding_namespace := folding-at-home
vpn_namespace := openvpn
vpn_device1 := pixel3
vpn_device2 := surfacego2

init:
	kubectl apply -f config_maps/coredns.yml
	make add-repos
	make vpn
	make kube
	make dash
	make f@h

add-repos:
	helm repo add stable https://kubernetes-charts.storage.googleapis.com
	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	helm repo add brannon https://helm.brannon.online
	helm repo update

# Dashboards

kube:
	kubectl get namespace $(kube_namespace) || kubectl create namespace $(kube_namespace)
	helm upgrade my-kube-ops-dash stable/kube-ops-view -n $(kube_namespace) -f helm_vars/kube-ops-dash-values.yaml --install --wait

uninstall-kube:
	helm uninstall -n $(kube_namespace) my-kube-ops-dash

dash:
	kubectl get namespace $(dash_namespace) || kubectl create namespace $(dash_namespace)
	helm upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -n $(dash_namespace) -f helm_vars/k8s-dashboard-values.yaml --install --wait

uninstall-dash:
	helm uninstall -n $(dash_namespace) my-k8s-dashboard

# Compute

f@h:
	kubectl get namespace $(folding_namespace) || kubectl create namespace $(folding_namespace)
	helm secrets upgrade folding-at-home brannon/folding-at-home -n $(folding_namespace) -f helm_vars/folding-at-home-values.yaml -f helm_secrets/secrets.folding-at-home.yaml --install --wait

uninstall-f@h:
	helm uninstall -n $(folding_namespace) folding-at-home

# OpenVPN

gen_vpn_keys:
	openvpn_scripts/generate_openvpn_client_key.sh $(vpn_device1) $(vpn_namespace) my-openvpn
	openvpn_scripts/generate_openvpn_client_key.sh $(vpn_device2) $(vpn_namespace) my-openvpn

vpn:
	kubectl get namespace $(vpn_namespace) || kubectl create namespace $(vpn_namespace)
	helm upgrade my-openvpn stable/openvpn -n $(vpn_namespace) -f helm_vars/openvpn-values.yaml --install --wait --timeout=10m0s
	make gen_vpn_keys

uninstall-vpn:
	helm uninstall -n $(vpn_namespace) my-openvpn

clean:
	kubectl delete namespace $(dash_namespace)
	kubectl delete namespace $(kube_namespace)
	kubectl delete namespace $(folding_namespace)
	kubectl delete namespace $(vpn_namespace)
