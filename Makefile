SHELL := /bin/bash
dash_namespace := kubernetes-dashboard
kube_namespace := kube-ops-view
folding_namespace := folding-at-home
vpn_namespace := openvpn
vpn_device1 := pixel3
vpn_device2 := surfacego2
site_namespace := dennis-site
statping_namespace := statping
airsonic_namespace := airsonic

init:
	kubectl apply -f config_maps/coredns.yml
	make add-update-repos
	make vpn
	make kube
	make dash
	make f@h

add-update-repos:
	helm repo add my-helm-charts-repo https://flipenergy.github.io/helm-charts-repo/
	helm repo add stable https://kubernetes-charts.storage.googleapis.com
	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	helm repo add brannon https://helm.brannon.online
	helm repo update

# Dashboards

kube:
	helm upgrade my-kube-ops-view my-helm-charts-repo/kube-ops-view -n $(kube_namespace) -f helm_vars/kube-ops-view-values.yaml --install --create-namespace --wait

uninstall-kube:
	helm uninstall -n $(kube_namespace) my-kube-ops-view

dash:
	helm upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -n $(dash_namespace) -f helm_vars/k8s-dashboard-values.yaml --install --create-namespace --wait

uninstall-dash:
	helm uninstall -n $(dash_namespace) my-k8s-dashboard

# Compute

f@h:
	helm secrets upgrade folding-at-home brannon/folding-at-home -n $(folding_namespace) -f helm_vars/folding-at-home-values.yaml -f helm_secrets/secrets.folding-at-home.yaml --install --create-namespace --wait

uninstall-f@h:
	helm uninstall -n $(folding_namespace) folding-at-home

# OpenVPN

gen-vpn-keys:
	openvpn_scripts/generate_openvpn_client_key.sh $(vpn_device1) $(vpn_namespace) my-openvpn
	openvpn_scripts/generate_openvpn_client_key.sh $(vpn_device2) $(vpn_namespace) my-openvpn

freeze_vpn_certs:
	kubectl cp -n $(vpn_namespace) `kubectl get pod -n $(vpn_namespace) -o jsonpath='{.items..metadata.name}'`:/etc/openvpn/certs/pki/private/server.key server.key
	kubectl cp -n $(vpn_namespace) `kubectl get pod -n $(vpn_namespace) -o jsonpath='{.items..metadata.name}'`:/etc/openvpn/certs/pki/ca.crt ca.crt
	kubectl cp -n $(vpn_namespace) `kubectl get pod -n $(vpn_namespace) -o jsonpath='{.items..metadata.name}'`:/etc/openvpn/certs/pki/issued/server.crt server.crt
	kubectl cp -n $(vpn_namespace) `kubectl get pod -n $(vpn_namespace) -o jsonpath='{.items..metadata.name}'`:/etc/openvpn/certs/pki/dh.pem dh.pem
	kubectl create secret generic -n $(vpn_namespace) openvpn-keystore-secret --from-file=./server.key --from-file=./ca.crt --from-file=./server.crt --from-file=./dh.pem
	rm -fv *.key *.crt *.pem

vpn:
	helm upgrade my-openvpn stable/openvpn -n $(vpn_namespace) -f helm_vars/openvpn-values.yaml --install --create-namespace --wait --timeout=15m0s

uninstall-vpn:
	helm uninstall -n $(vpn_namespace) my-openvpn

site:
	helm upgrade dennis-site ./flipenergy -n $(site_namespace) --install --create-namespace --wait

uninstall-site:
	helm uninstall -n $(site_namespace) dennis-site

stat:
	helm upgrade statping ./statping -n $(statping_namespace) --install --create-namespace --wait

uninstall-stat:
	helm uninstall -n $(statping_namespace) statping

air:
	helm upgrade airsonic ./airsonic -n $(airsonic_namespace) --install --create-namespace --wait

uninstall-air:
	helm uninstall -n $(airsonic_namespace) airsonic

clean:
	kubectl delete namespace $(dash_namespace)
	kubectl delete namespace $(kube_namespace)
	kubectl delete namespace $(folding_namespace)
	kubectl delete namespace $(vpn_namespace)
	kubectl delete namespace $(site_namespace)
