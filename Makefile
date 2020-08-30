SHELL := /bin/bash
bitwarden_namespace := bitwarden
folding_namespace := folding-at-home
mattermost_namespace := mattermost
monitoring_namespace := monitoring
my_site_namespace := dennis-site
syncthing_namespace := syncthing
wireguard_namespace := wireguard

deploy:
	helmsman --apply -f homelab.yaml

up:
	make init
	make deploy

init:
	make influx-init
	make graf-init
	make bit-init
	make concourse-init
	make f@h-init
	make mattermost-init
	make wire-init

destroy:
	make clean-influx
	make clean-graf
	make clean-concourse
	make clean-bit
	make clean-f@h
	make clean-mattermost
	make clean-wire
	kubectl delete namespace $(bitwarden_namespace)
	kubectl delete namespace $(folding_namespace)
	kubectl delete namespace $(mattermost_namespace)
	kubectl delete namespace $(monitoring_namespace)
	kubectl delete namespace $(my_site_namespace)
	kubectl delete namespace $(syncthing_namespace)
	kubectl delete namespace $(wireguard_namespace)

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
	kubectl apply -f bitwarden/persistencevolume.yaml

clean-bit:
	kubectl delete pv bitwarden

# Concourse
concourse-init:
	kubectl apply -f concourse/persistencevolume.yaml

clean-concourse:
	kubectl delete pv concourse-postgresql

# Mattermost
mattermost-init:
	kubectl apply -f mattermost/persistencevolumes.yaml

clean-mattermost:
	kubectl delete pv mattermost-data
	kubectl delete pv mattermost-plugins
	kubectl delete pv mattermost-mysql

# Syncthing
save-sync-config:
	mkdir -p config
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/config.xml config/config.xml
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/cert.pem config/cert.pem
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/key.pem config/key.pem
	gpg-zip --encrypt --output syncthing/syncthing_config --recipient $$USER config
	rm -rf config

# WireGuard
wire-init:
	kubectl apply -f wireguard/persistencevolume.yaml

clean-wire:
	kubectl delete pv wireguard
