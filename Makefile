context := homelab
syncthing_namespace := syncthing

deploy:
	sops -d ingress-nginx/secret.default-ssl-certs.yaml | kubectl --context $(context) -n default apply -f -
	docker run --rm -it \
	-v $$(pwd):/k8s-homelab \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /k8s-homelab \
	praqma/helmsman:latest \
	helmsman $(options) -p 3 -show-diff --apply -f ${context}.yaml
