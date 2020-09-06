monitoring_namespace := monitoring
syncthing_namespace := syncthing

deploy:
	kubectl apply -f coredns_configmap.yaml
	helmsman --apply -f homelab.yaml

destroy:
	make clean-influx
	make clean-bit
	make clean-concourse
	make clean-mattermost
	make clean-wire
	kubectl delete namespace bitwarden
	kubectl delete namespace concourse
	kubectl delete namespace folding-at-home
	kubectl delete namespace invidious
	kubectl delete namespace mattermost
	kubectl delete namespace $(syncthing_namespace)
	kubectl delete namespace wireguard
	kubectl delete namespace whoogle
	kubectl delete namespace $(monitoring_namespace)

# InfluxDB

clean-influx:
	kubectl delete -n $(monitoring_namespace) pvc influxdb-data-influxdb-0
	kubectl delete pv influxdb

# Bitwarden

clean-bit:
	kubectl delete pv bitwarden

# Concourse
clean-concourse:
	kubectl delete pv concourse-postgresql

# Mattermost
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
clean-wire:
	kubectl delete pv wireguard
