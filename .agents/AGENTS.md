# k8s-homelab — agent context

Helmsman desired-state config for a personal homelab Kubernetes cluster (Talos Linux, 3 control plane nodes; owner: FlipEnergy / Dennis Zhang).
Public domain `pleasenoddos.com`; internal/admin services on `computersbarely.work`.

## Ground rules for agents (read first)

**Secrets**
- Never commit secrets: credentials, tokens, private keys, kubeconfigs, `.tfvars`, decrypted sops output, or anything that looks like one. If a change would add one, stop and ask.
- Before committing, review the staged diff (`git diff --cached`) for secret-looking values and for files that should be ignored. Never use `git add -f` on an ignored file, and never weaken `.gitignore` to make a file committable.
- Never put secret values into tracked files, commit messages, PR descriptions, logs, or chat output — not even partially or "redacted by hand".
- Encrypted files (`*.enc.yml`, sops `*-secrets.yaml`) may be read as-is, but only change them with the proper tool (`sops`); never decrypt them unless asked.

**Public repo**
- This repository is public, so anyone can read everything committed: code, comments, docs, commit messages, PR descriptions, and this file.
- Don't reveal more than a change needs, especially details that would help an attacker: internal network layout (LAN IPs, subnets, VIPs, gateway/DNS servers), internal machine names, hardware models, serials and disk IDs, open ports and port forwards, exposed service versions, disabled hardening or other security trade-offs, backup locations and schedules, and personal details beyond what is already public.
- When a config file must contain such a detail for things to work (e.g. an IP the system reads), keep it in that file only. Don't repeat or explain it in docs, comments or commit messages; in prose, say "the NAS" or "the API VIP" instead.
- If you're unsure whether something is too revealing, leave it out or ask the owner.

**Git-ignored files**
- Do not read, print, search, or open git-ignored files directly unless the user specifically asks for that file. They are often local secrets or decrypted copies (e.g. `*.dec.yml`, `*.yaml.dec`, `terraform.tfvars`, `backend.tf`, `*.key`, `*.pem`).
- Exclude them from searches (prefer `git ls-files` / `git grep`, or tools that respect `.gitignore`). Check with `git check-ignore -v <path>` if unsure.
- Generated build output that is ignored (e.g. `public/`, `.terraform/`) may be listed, but still don't read its contents unless needed for the task and asked.

## Deployment model

- `homelab.yaml` is the Helmsman desired state file (DSF): namespaces, helm repos, and every app (chart, version, values, secrets, hooks, priority). It targets kube context `homelab`. Talos enforces Pod Security `baseline` by default; namespaces whose pods need more carry a `pod-security.kubernetes.io/enforce` label under `namespaces:`. There is no LoadBalancer implementation, so ingress-nginx and wireguard bind host ports.
- Deployed by CI: pushes to `main` trigger the `deploy-k8s-homelab` pipeline in the sibling `concourse-pipelines` repo (`helmsman -apply -f homelab.yaml`). Non-main branches get an automatic `-show-diff` pipeline, posted to Discord. **Opening a branch is the normal way to preview a change.** Concourse itself runs in this cluster (`concourse` app); its worker needs Talos-specific settings (see `concourse/concourse-values.yaml` and `talos/patches/all.yaml`).
- Local: `make deploy` (= `mise exec -- helmsman -p 12 --show-diff --apply -f homelab.yaml`), `make destroy`. These mutate the live cluster — never run without explicit approval. For a dry run: `mise exec -- helmsman --show-diff -f homelab.yaml` (no `--apply`).
- Tooling: CLI tools (helm 4, helmsman, kubectl, k9s, talosctl) are pinned in `mise.toml` and installed with mise — there are no system copies. Run them via `mise exec -- <tool>` (or with mise activated in the shell); a bare `helm`/`helmsman` may not be on PATH in a non-interactive shell. To bump a tool, change its version in `mise.toml`.
- Setup: `make tools` runs `mise install` and installs the helm plugins helmsman needs (helm-diff, helm-secrets; versions pinned in the `Makefile`). sops is not managed by mise yet.

## Layout

One directory per app, named after the app/namespace:

- `<app>/<app>-values.yaml` — override values (plain).
- `<app>/<app>-secrets.yaml` — **sops-encrypted** (PGP) values, passed via `secretsFile`. Edit only with `sops <file>`; never hand-edit `ENC[...]` blocks or commit decrypted content (`*.yaml.dec` is gitignored).
- `<app>/persistenceVolume.yaml` — a static NFS `PersistentVolume`, applied as a Helmsman `preInstall`/`preUpgrade` hook. The PV's `storageClassName` matches the `storageClass` in the app's values.
- `talos/` — Talos Linux machine config for the cluster nodes: `patches/` + `nodes/<name>.yaml` layered onto configs generated from the sops-encrypted `talos-secrets.yaml`; `make -C talos ...` (see `talos/README.md`). Generated output in `talos/_out/` is git-ignored and holds cluster keys — don't read it. `make install`/`apply`/`bootstrap` change real machines — never run them without explicit approval.
- `<app>/chart/` or `<app>/<app>/` — local Helm charts (gonic, kube-ops-view, vaultwarden use vendored `common-4.5.2.tgz` from the old k8s-at-home library; restic, wireguard, nextcloud-news-updater, cert-manager-secrets are hand-written).

Charts in use:
- Most apps: `bjw-s/app-template` (currently 5.3.0) — values use the `controllers.main.containers.main`, `service.main`, `ingress.main`, `persistence` schema.
- Upstream charts: ingress-nginx, cert-manager, headlamp, descheduler, concourse, nextcloud, bitnami postgresql/redis.

## Conventions

- Ingress: nginx with `cert-manager.io/cluster-issuer: "letsencrypt-homelab"` (DNS-01 via Cloudflare, `cert-manager/ClusterIssuer.yaml`) and `nginx.ingress.kubernetes.io/force-ssl-redirect: "true"`. TLS secret named `<app>-tls`.
- Storage: static NFS `PersistentVolume`s on the NAS (copy an existing `persistenceVolume.yaml`). Apps that need it are in Helmsman `group: uses-nfs`.
- Scheduling: `nodeSelector: performance: medium|high` on pods.
- Pin image tags explicitly in values; set resource requests/limits.
- Priority (lower = earlier): foundation (ingress, cert-manager, cf-ddns, monitoring) -200/-199, databases -100, apps that depend on them -99, default 0.
- Shared DBs: `postgresql` and `redis` namespaces serve other apps (e.g. nextcloud).
- Renovate (`renovate.json`) bumps chart versions in `homelab.yaml` and image tags in `*-values.yaml`; many commits/PRs are Renovate's.

## Adding an app (typical)

1. Create `<app>/` with `<app>-values.yaml` (app-template), optional `<app>-secrets.yaml` (create with `sops`), optional `persistenceVolume.yaml`.
2. Add the namespace under `namespaces:` and the app under `apps:` in `homelab.yaml`, in the matching section.
3. Public hostnames need a DNS record in the sibling `tf-playground` repo (`homelab/dns_records.tf`); `*.computersbarely.work` hosts are handled separately.

## Related repos

- `concourse-pipelines` — deploys this repo (`k8s-homelab/` pipelines); Concourse itself runs from `concourse/` here.
- `container-images` — builds `flipenergy/restic`, `flipenergy/nextcloud-news-updater` and `flipenergy/nextcloud` used here. The nextcloud image bakes in the uid-1000 `dennis` user and preview deps; its tags mirror upstream (`<version>-apache`) and the `images-build` pipeline builds one job per Nextcloud major, so a new major needs a pipeline job before `nextcloud-values.yaml` can use it.
- `tf-playground` — Cloudflare DNS for the hostnames used in ingresses.
- `personal-website` — deployed to this cluster by CI, but not managed through `homelab.yaml`.
