SHELL := /bin/bash
monitoring_namespace := monitoring
bitwarden_namespace := bitwarden
folding_namespace := folding-at-home
site_namespace := dennis-site
syncthing_namespace := syncthing
wireguard_namespace := wireguard

up:
	make init
	make deploy

init:
	kubectl apply -f coredns/coredns.yml
	make influx-init
	make graf-init
	make f@h-init

deploy:
	helmsman --apply -f homelab.yaml

# Statping
save-stat-db:
	kubectl cp -n $(monitoring_namespace) `kubectl get pod -n $(monitoring_namespace) -l app.kubernetes.io/name=statping -o jsonpath='{.items..metadata.name}'`:/app app
	rm -vrf app/logs/* ~/ansible-playground/roles/site_node/files/statping-app-data
	mv -v app ~/ansible-playground/roles/site_node/files/statping-app-data

# Syncthing
save-sync-config:
	mkdir -p config
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/config.xml config/config.xml
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/cert.pem config/cert.pem
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/key.pem config/key.pem
	gpg-zip --encrypt --output syncthing/syncthing_config --recipient $$USER config
	rm -rf config

# InfluxDB
influx-init:
	kubectl get ns $(monitoring_namespace) > /dev/null || kubectl create ns $(monitoring_namespace)
	kubectl apply -f influxdb/persistencevolume.yaml
	helm secrets dec influxdb/secrets.influxdb-creds.yaml
	-kubectl apply -n $(monitoring_namespace) -f influxdb/secrets.influxdb-creds.yaml.dec
	rm -fv influxdb/secrets.influxdb-creds.yaml.dec

clean-influx:
	kubectl delete -n $(monitoring_namespace) secret influxdb-creds
	kubectl delete -n $(monitoring_namespace) pvc influxdb-data-influxdb-0
	kubectl delete pv influxdb

# Grafana
graf-init:
	kubectl get ns $(monitoring_namespace) > /dev/null || kubectl create ns $(monitoring_namespace)
	kubectl apply -f grafana/persistencevolume.yaml
	helm secrets dec grafana/secrets.grafana-creds.yaml
	-kubectl apply -n $(monitoring_namespace) -f grafana/secrets.grafana-creds.yaml.dec
	rm -fv grafana/secrets.grafana-creds.yaml.dec

clean-graf:
	kubectl delete -n $(monitoring_namespace) secret grafana-creds
	kubectl delete pv grafana

# Bitwarden
bit-init:
	kubectl get ns $(bitwarden_namespace) > /dev/null || kubectl create ns $(bitwarden_namespace)
	kubectl apply -f bitwarden/persistencevolume.yaml

clean-bit:
	kubectl delete pv bitwarden

# Folding-at-home
f@h-init:
	kubectl apply -f folding-at-home/persistentvolume.yaml

clean-f@h:
	kubectl delete -n $(folding_namespace) pvc fah-folding-at-home-fahclient-0
	kubectl delete pv folding-at-home

# WireGuard
wire-init:
	kubectl get ns $(wireguard_namespace) > /dev/null || kubectl create ns $(wireguard_namespace)
	kubectl apply -f wireguard/persistencevolume.yaml

clean-wire:
	kubectl delete pv wireguard

# clean
clean:
	make clean-influx
	make clean-graf
	make clean-bit
	make clean-f@h
	make clean-wire
	kubectl delete namespace $(bitwarden_namespace)
	kubectl delete namespace $(folding_namespace)
	kubectl delete namespace $(site_namespace)
	kubectl delete namespace $(syncthing_namespace)
	kubectl delete namespace $(wireguard_namespace)
	kubectl delete namespace $(monitoring_namespace)
