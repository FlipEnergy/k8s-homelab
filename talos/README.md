# Talos

Machine config for the Talos Linux nodes that run the homelab cluster. Run everything from this directory; `talosctl` is pinned in `../mise.toml`.

| Path | What |
| --- | --- |
| `talos-secrets.yaml` | Cluster secrets bundle (`talosctl gen secrets`), **sops-encrypted**. Edit only with `sops`. |
| `patches/all.yaml` | Every node: installer image (Image Factory schematic with `nfs-utils`), install wipe, DNS. |
| `patches/controlplane.yaml` | Control plane nodes: drop the NoSchedule taint so they also run workloads. |
| `nodes/<name>.yaml` | Per node: hostname, static IP, VIP, install disk, node labels. |
| `_out/` | Generated configs and `talosconfig`. Git-ignored because they contain the cluster keys. |

## Cluster

- Name `homelab`. The Kubernetes API is served on a Layer2 VIP that floats between the control plane nodes (`endpoint` in the `Makefile`).
- Nodes: `k8s-med-1`, `k8s-med-2` and `k8s-high-1` (`performance: high`). All are control plane nodes and all run workloads; their IPs are in the `Makefile`.

## First node

1. Boot the node from the Talos ISO/PXE using the default entry. It comes up in maintenance mode.
2. `make install node=k8s-med-1` generates the config, validates it, and installs Talos to disk. The node reboots, so **remove the USB stick** at that point.
3. `make bootstrap` starts etcd. Run it **once ever**, and only on the first control plane node.
4. `make health`, then `make kubeconfig`, which writes `_out/kubeconfig` with context `admin@homelab`. Your `~/.kube/config` uses that same cluster under the context name `homelab`, which `../homelab.yaml` targets. To refresh it, delete the old `homelab` entries, merge `_out/kubeconfig`, and rename the context `admin@homelab` to `homelab`.

Use the generated talosconfig with `export TALOSCONFIG=$PWD/_out/talosconfig`, or merge it into your default config with `talosctl config merge _out/talosconfig`.

## Adding a node

1. Add `ip.<name> := <ip>` to the `Makefile`. For a control plane node, also add it to `controlplanes`; for a worker, set `role.<name> := worker`.
2. Copy `nodes/k8s-med-1.yaml` to `nodes/<name>.yaml` and change the hostname, IP and disk. Find the disk's `wwid` and the NIC name with `talosctl get disks --insecure -n <ip>` and `talosctl get links --insecure -n <ip>`. Keep the `Layer2VIPConfig` only on control plane nodes.
3. Boot the node into maintenance mode, then run `make install node=<name>`. It joins the cluster on its own. **Do not bootstrap again.**

Keep an odd number of control plane nodes (1 or 3) so etcd keeps quorum.

## Day 2

- Config change: edit the patches, run `make diff node=<name>` to preview, then `make apply node=<name>`.
- Talos upgrade: bump `talosctl` in `../mise.toml` and the installer tag in `patches/all.yaml`, then upgrade one node at a time with `talosctl --talosconfig _out/talosconfig upgrade -n <ip> --image <installer image>`.
- Back up etcd: `talosctl --talosconfig _out/talosconfig etcd snapshot etcd.snapshot`.
