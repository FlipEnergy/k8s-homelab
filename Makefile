syncthing_namespace := syncthing

deploy:
	docker run --rm -it \
	-v $$(pwd):/k8s-homelab \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /k8s-homelab \
	praqma/helmsman:v3.6.9 \
	helmsman $(options) -p 3 -show-diff --apply -f homelab.yaml

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
	kubectl delete namespace influxdb

# InfluxDB

clean-influx:
	kubectl delete -n influxdb pvc influxdb-data-influxdb-0
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
	kubectl delete pv mattermost-mysql

# Syncthing
save-sync-config:
	mkdir -p config
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/config.xml config/config.xml
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/cert.pem config/cert.pem
	kubectl cp -n $(syncthing_namespace) `kubectl get pod -n $(syncthing_namespace) -l app.kubernetes.io/name=syncthing -o jsonpath='{.items..metadata.name}'`:/var/syncthing/config/key.pem config/key.pem
	gpg-zip --encrypt --output syncthing_config_dir --recipient $$USER config
	rm -rf config

# WireGuard
clean-wire:
	kubectl delete pv wireguard
