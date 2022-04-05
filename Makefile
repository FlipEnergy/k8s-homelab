context := homelab
action := --apply

deploy:
	sops -d ingress-nginx/secret.default-ssl-certs.yaml | kubectl --context $(context) -n default apply -f -
	docker run --rm -it \
	-v $$(pwd):/k8s-homelab \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /k8s-homelab \
	praqma/helmsman:latest \
	helmsman $(options) -p 3 --show-diff -f ${context}.yaml

destroy:
	docker run --rm -it \
	-v $$(pwd):/k8s-homelab \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /k8s-homelab \
	praqma/helmsman:latest \
	helmsman $(options) --destroy -f ${context}.yaml
