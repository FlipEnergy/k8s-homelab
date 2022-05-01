context := homelab
action := -apply

deploy:
	docker run --rm -it \
	-v $$(pwd):/k8s-homelab \
	-v ~/.kube/config:/root/.kube/config \
	-v ~/.gnupg:/root/.gnupg \
	-w /k8s-homelab \
	praqma/helmsman:latest \
	helmsman $(options) -p 3 -show-diff ${action} -f ${context}.yaml

destroy: action := -destroy
destroy: deploy
