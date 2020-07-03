SHELL := /bin/bash
dash_namespace := kubernetes-dashboard
kube_namespace := kube-ops-view
folding_namespace := folding-at-home
vpn_namespace := openvpn
vpn_device1 := pixel3
vpn_device2 := surfacego2
site_namespace := dennis-site
statping_namespace := statping
syncthing_namespace := syncthing
monitoring_namespace := monitoring

init:
	kubectl apply -f coredns/coredns.yml
	make add-update-repos
	make vpn
	make kube
	make dash
	make site
	make stat
	make sync

add-update-repos:
	helm repo add my-helm-charts-repo https://flipenergy.github.io/helm-charts-repo/
	helm repo add stable https://kubernetes-charts.storage.googleapis.com
	helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
	helm repo add pcktdmp https://pcktdmp.github.io/charts
	helm repo update

# Dashboards
kube:
	helm upgrade my-kube-ops-view my-helm-charts-repo/kube-ops-view -n $(kube_namespace) -f kube-ops-view/kube-ops-view-values.yaml --install --create-namespace --wait

uninstall-kube:
	helm uninstall -n $(kube_namespace) my-kube-ops-view

dash:
	helm upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -n $(dash_namespace) -f kubernetes-dashboard/k8s-dashboard-values.yaml --install --create-namespace --wait

uninstall-dash:
	helm uninstall -n $(dash_namespace) my-k8s-dashboard

# Compute
f@h:
	kubectl apply -f folding-at-home/persistentvolume.yaml
	helm secrets upgrade folding-at-home pcktdmp/fahclient -n $(folding_namespace) -f folding-at-home/folding-at-home-values.yaml -f folding-at-home/secrets.folding-at-home.yaml --install --create-namespace --wait

uninstall-f@h:
	helm uninstall -n $(folding_namespace) folding-at-home
	kubectl delete pv folding-at-home

# OpenVPN
gen-vpn-keys:
	openvpn/generate_openvpn_client_key.sh $(vpn_device1) $(vpn_namespace) my-openvpn
	openvpn/generate_openvpn_client_key.sh $(vpn_device2) $(vpn_namespace) my-openvpn

freeze-vpn-certs:
	kubectl cp -n $(vpn_namespace) `kubectl get pod -n $(vpn_namespace) -o jsonpath='{.items..metadata.name}'`:/etc/openvpn/certs/pki/private/server.key server.key
	kubectl cp -n $(vpn_namespace) `kubectl get pod -n $(vpn_namespace) -o jsonpath='{.items..metadata.name}'`:/etc/openvpn/certs/pki/ca.crt ca.crt
	kubectl cp -n $(vpn_namespace) `kubectl get pod -n $(vpn_namespace) -o jsonpath='{.items..metadata.name}'`:/etc/openvpn/certs/pki/issued/server.crt server.crt
	kubectl cp -n $(vpn_namespace) `kubectl get pod -n $(vpn_namespace) -o jsonpath='{.items..metadata.name}'`:/etc/openvpn/certs/pki/dh.pem dh.pem
	kubectl create secret generic -n $(vpn_namespace) openvpn-keystore-secret --from-file=./server.key --from-file=./ca.crt --from-file=./server.crt --from-file=./dh.pem
	rm -fv *.key *.crt *.pem

vpn:
	helm upgrade my-openvpn my-helm-charts-repo/openvpn -n $(vpn_namespace) -f openvpn/openvpn-values.yaml --install --create-namespace --wait --timeout=15m0s

uninstall-vpn:
	helm uninstall -n $(vpn_namespace) my-openvpn

# My website
site:
	helm upgrade dennis-site ./flipenergy -n $(site_namespace) --install --create-namespace --wait

uninstall-site:
	helm uninstall -n $(site_namespace) dennis-site

# Statping
save-stat-db:
	kubectl cp -n $(statping_namespace) `kubectl get pod -n $(statping_namespace) -o jsonpath='{.items..metadata.name}'`:/app app
	rm -vrf app/logs/* ~/ansible-playground/roles/site_node/files/statping-app-data
	mv -v app ~/ansible-playground/roles/site_node/files/statping-app-data

stat:
	helm upgrade statping ./statping -n $(statping_namespace) --install --create-namespace --wait

uninstall-stat:
	helm uninstall -n $(statping_namespace) statping

# Syncthing
save-sync-config:
	mkdir -p config
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/config.xml config/config.xml
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/cert.pem config/cert.pem
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/key.pem config/key.pem
	gpg-zip --encrypt --output syncthing/syncthing_config --recipient $$USER config
	rm -rf config

sync:
	helm upgrade syncthing ./syncthing -n $(syncthing_namespace) --install --create-namespace --wait

uninstall-sync:
	helm uninstall -n $(syncthing_namespace) syncthing

# InfluxDB
influx:
	kubectl get ns $(monitoring_namespace) > /dev/null || kubectl create ns $(monitoring_namespace)
	kubectl apply -n $(monitoring_namespace) -f influxdb/persistencevolume.yaml
	helm secrets dec influxdb/secrets.influxdb-creds.yaml
	kubectl apply -n $(monitoring_namespace) -f influxdb/secrets.influxdb-creds.yaml.dec
	rm -fv influxdb/secrets.influxdb-creds.yaml.dec
	helm upgrade influxdb my-helm-charts-repo/influxdb -n $(monitoring_namespace) -f influxdb/influxdb-values.yaml --install --wait

uninstall-influx:
	helm uninstall -n $(monitoring_namespace) influxdb
	kubectl delete secret -n $(monitoring_namespace) influxdb-creds
	kubectl delete persistentvolume influxdb

# Grafana
graf:
	kubectl get ns $(monitoring_namespace) > /dev/null || kubectl create ns $(monitoring_namespace)
	kubectl apply -n $(monitoring_namespace) -f grafana/persistencevolume.yaml
	helm secrets dec grafana/secrets.grafana-creds.yaml
	kubectl apply -n $(monitoring_namespace) -f grafana/secrets.grafana-creds.yaml.dec
	rm -fv grafana/secrets.grafana-creds.yaml.dec
	helm secrets upgrade grafana stable/grafana -n $(monitoring_namespace) -f grafana/grafana-values.yaml -f grafana/secrets.grafana-datasource.yaml --install --create-namespace --wait

uninstall-graf:
	helm uninstall -n $(monitoring_namespace) grafana
	kubectl delete secret -n $(monitoring_namespace) grafana-creds
	kubectl delete persistentvolume grafana

# clean
clean:
	kubectl delete namespace $(dash_namespace)
	kubectl delete namespace $(kube_namespace)
	kubectl delete namespace $(folding_namespace)
	kubectl delete namespace $(vpn_namespace)
	kubectl delete namespace $(site_namespace)
	kubectl delete namespace $(statping_namespace)
	kubectl delete namespace $(syncthing_namespace)
