# Talos machine configs for the homelab cluster. See README.md.
#
# Generated machine configs and talosconfig are written to _out/, which is
# git-ignored: they embed the cluster CA keys and tokens. Regenerate them any
# time from talos-secrets.yaml (sops) + patches/ + nodes/.

mise := mise exec --
talosctl := $(mise) talosctl

cluster := homelab
# Kubernetes API via the Layer2 VIP shared by the control plane nodes.
endpoint := https://10.69.69.100:6443
out := _out

# One line per node (name -> IP), plus nodes/<name>.yaml.
# Set role.<name> := worker for worker nodes (default: controlplane).
ip.k8s-med-1 := 10.69.69.101
ip.k8s-med-2 := 10.69.69.102
ip.k8s-high-1 := 10.69.69.51

controlplanes := k8s-med-1 k8s-med-2 k8s-high-1

node ?=
ip = $(ip.$(node))
role = $(or $(role.$(node)),controlplane)
cp_ips = $(foreach n,$(controlplanes),$(ip.$(n)))
tc := $(talosctl) --talosconfig $(out)/talosconfig

define require_node
	@test -n "$(node)" || { echo "usage: make $@ node=<name>"; exit 1; }
	@test -n "$(ip)" || { echo "no ip.$(node) defined in Makefile"; exit 1; }
	@test -f nodes/$(node).yaml || { echo "missing nodes/$(node).yaml"; exit 1; }
endef

# Base controlplane/worker configs + talosconfig, from the encrypted secrets.
gen:
	@mkdir -p $(out)
	sops exec-file --no-fifo talos-secrets.yaml '$(talosctl) gen config $(cluster) $(endpoint) \
		--with-secrets {} --output $(out) --force --with-docs=false --with-examples=false \
		--config-patch @patches/all.yaml \
		--config-patch-control-plane @patches/controlplane.yaml'
	$(tc) config endpoint $(cp_ips)
	$(tc) config node $(ip.$(firstword $(controlplanes)))

# Per-node config: base config for the node's role + nodes/<node>.yaml.
config: gen
	$(require_node)
	$(talosctl) machineconfig patch $(out)/$(role).yaml --patch @nodes/$(node).yaml --output $(out)/$(node).yaml
	$(talosctl) validate --mode metal --strict --config $(out)/$(node).yaml

# First install: node is booted from the ISO/PXE and sitting in maintenance mode.
install: config
	$(talosctl) apply-config --insecure --nodes $(ip) --file $(out)/$(node).yaml

# Config change on an installed node. Use mode=no-reboot|reboot|staged|try to override.
mode ?= auto
apply: config
	$(tc) apply-config --nodes $(ip) --file $(out)/$(node).yaml --mode $(mode)

# Preview what `make apply` would change.
diff: config
	$(tc) apply-config --nodes $(ip) --file $(out)/$(node).yaml --dry-run

# Run ONCE for the lifetime of the cluster, on the first control plane node only.
bootstrap:
	$(tc) bootstrap --nodes $(ip.$(firstword $(controlplanes)))

# Admin kubeconfig to _out/kubeconfig (context admin@homelab). Not merged into
# ~/.kube/config automatically, since that already has a "homelab" context.
kubeconfig:
	$(tc) kubeconfig $(out)/kubeconfig --force --nodes $(ip.$(firstword $(controlplanes)))

health:
	$(tc) health --nodes $(ip.$(firstword $(controlplanes)))

.PHONY: gen config install apply diff bootstrap kubeconfig health
