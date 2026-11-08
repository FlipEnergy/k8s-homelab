context := homelab
action := --apply

# CLI tools (helm, helmsman, kubectl, ...) are pinned in mise.toml.
# Run them through mise so the pinned versions are used even when mise
# isn't activated in the current shell.
mise := mise exec --

helm_diff_version := 3.15.15
helm_secrets_version := 4.7.10
helm_diff_url := https://github.com/databus23/helm-diff/releases/download/v$(helm_diff_version)
helm_secrets_url := https://github.com/jkroepke/helm-secrets/releases/download/v$(helm_secrets_version)

# Install the mise-managed tools and the helm plugins helmsman needs.
# Plugins are installed from their signed release packages and verified
# against the maintainers' GPG keys as published on their GitHub profiles.
# helm-secrets ships three separate plugins for Helm 4.
tools:
	mise install
	@keyring=$$(mktemp) && trap 'rm -f $$keyring' EXIT && \
	for u in databus23 jkroepke; do curl -fsSL https://github.com/$$u.gpg | gpg --dearmor >> $$keyring || exit 1; done && \
	installed=$$($(mise) helm plugin list) && \
	{ echo "$$installed" | grep -q '^diff\s' || \
		$(mise) helm plugin install $(helm_diff_url)/diff-$(helm_diff_version)-linux-amd64.tgz --keyring $$keyring; } && \
	for p in secrets secrets-getter secrets-post-renderer; do \
		echo "$$installed" | grep -q "^$$p\s" || \
			$(mise) helm plugin install $(helm_secrets_url)/$$p-$(helm_secrets_version).tgz --keyring $$keyring || exit 1; \
	done

deploy:
	$(mise) helmsman $(options) -p 12 --show-diff $(action) -f $(context).yaml

destroy: action := --destroy
destroy: deploy

.PHONY: tools deploy destroy
