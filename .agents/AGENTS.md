# k8s-homelab — agent context

Helmsman desired-state config for a personal homelab Kubernetes cluster (k3s; owner: FlipEnergy / Dennis Zhang).
Public domain `pleasenoddos.com`; internal/admin services on `computersbarely.work`.

## Ground rules for agents (read first)

**Secrets**
- Never commit secrets: credentials, tokens, private keys, kubeconfigs, `.tfvars`, decrypted sops output, or anything that looks like one. If a change would add one, stop and ask.
- Before committing, review the staged diff (`git diff --cached`) for secret-looking values and for files that should be ignored. Never use `git add -f` on an ignored file, and never weaken `.gitignore` to make a file committable.
- Never put secret values into tracked files, commit messages, PR descriptions, logs, or chat output — not even partially or "redacted by hand".
- Encrypted files (`*.enc.yml`, sops `*-secrets.yaml`) may be read as-is, but only change them with the proper tool (`sops`); never decrypt them unless asked.

**Git-ignored files**
- Do not read, print, search, or open git-ignored files directly unless the user specifically asks for that file. They are often local secrets or decrypted copies (e.g. `*.dec.yml`, `*.yaml.dec`, `terraform.tfvars`, `backend.tf`, `*.key`, `*.pem`).
- Exclude them from searches (prefer `git ls-files` / `git grep`, or tools that respect `.gitignore`). Check with `git check-ignore -v <path>` if unsure.
- Generated build output that is ignored (e.g. `public/`, `.terraform/`) may be listed, but still don't read its contents unless needed for the task and asked.

## Deployment model

- `homelab.yaml` is the Helmsman desired state file (DSF): namespaces, helm repos, and every app (chart, version, values, secrets, hooks, priority).
- Deployed by CI: pushes to `main` trigger the `deploy-k8s-homelab` pipeline in the sibling `concourse-pipelines` repo (`helmsman -apply -f homelab.yaml`). Non-main branches get an automatic `-show-diff` pipeline, posted to Discord. **Opening a branch is the normal way to preview a change.**
- Local: `make deploy` (= `mise exec -- helmsman -p 12 --show-diff --apply -f homelab.yaml`), `make destroy`. These mutate the live cluster — never run without explicit approval. For a dry run: `mise exec -- helmsman --show-diff -f homelab.yaml` (no `--apply`).
- Tooling: CLI tools (helm 4, helmsman, kubectl, k9s, talosctl) are pinned in `mise.toml` and installed with mise — there are no system copies. Run them via `mise exec -- <tool>` (or with mise activated in the shell); a bare `helm`/`helmsman` may not be on PATH in a non-interactive shell. To bump a tool, change its version in `mise.toml`.
- Setup: `make tools` runs `mise install` and installs the helm plugins helmsman needs (helm-diff, helm-secrets; versions pinned in the `Makefile`). sops is not managed by mise yet.

## Layout

One directory per app, named after the app/namespace:

- `<app>/<app>-values.yaml` — override values (plain).
- `<app>/<app>-secrets.yaml` — **sops-encrypted** (PGP) values, passed via `secretsFile`. Edit only with `sops <file>`; never hand-edit `ENC[...]` blocks or commit decrypted content (`*.yaml.dec` is gitignored).
- `<app>/persistenceVolume.yaml` — a static NFS `PersistentVolume`, applied as a Helmsman `preInstall`/`preUpgrade` hook. The PV's `storageClassName` matches the `storageClass` in the app's values.
- `<app>/homelab/...` — cluster-specific override layered after the shared values (`valuesFiles:` list).
- `<app>/chart/` or `<app>/<app>/` — local Helm charts (gonic, kube-ops-view, vaultwarden use vendored `common-4.5.2.tgz` from the old k8s-at-home library; restic, wireguard, nextcloud-news-updater, cert-manager-secrets are hand-written).

Charts in use:
- Most apps: `bjw-s/app-template` (currently 5.3.0) — values use the `controllers.main.containers.main`, `service.main`, `ingress.main`, `persistence` schema.
- Upstream charts: ingress-nginx, cert-manager, headlamp, descheduler, concourse, nextcloud, bitnami postgresql/redis.

## Conventions

- Ingress: nginx with `cert-manager.io/cluster-issuer: "letsencrypt-homelab"` (DNS-01 via Cloudflare, `cert-manager/ClusterIssuer.yaml`) and `nginx.ingress.kubernetes.io/force-ssl-redirect: "true"`. TLS secret named `<app>-tls`.
- Storage: NFS from `truenas-1.tgp` under `/mnt/ZFS-3.6TB/tank/<app>-data`. Apps that need it are in Helmsman `group: uses-nfs`.
- Scheduling: `nodeSelector: performance: medium|high` on pods.
- Pin image tags explicitly in values; set resource requests/limits.
- Priority (lower = earlier): foundation (ingress, cert-manager, cf-ddns, monitoring) -200/-199, databases -100, apps that depend on them -99, default 0.
- Shared DBs: `postgresql` and `redis` namespaces serve other apps (e.g. nextcloud).
- Renovate (`renovate.json`) bumps chart versions in `homelab.yaml` and image tags in `*-values.yaml`; many commits/PRs are Renovate's.

## Adding an app (typical)

1. Create `<app>/` with `<app>-values.yaml` (app-template), optional `<app>-secrets.yaml` (create with `sops`), optional `persistenceVolume.yaml`.
2. Add the namespace under `namespaces:` and the app under `apps:` in `homelab.yaml`, in the matching section.
3. Public hostnames need a DNS record in the sibling `tf-playground` repo (`homelab/dns_records.tf`); `*.computersbarely.work` hosts are handled separately.

## Known drift (as of 2026-11)

- `oracle.yaml` DSF was removed, but `influxdb2/oracle/`, `ingress-nginx/oracle/`, `wireguard/oracle/` remain, and `renovate.json` still matches `oracle.yaml`. The concourse diff pipeline still has a `diff-oracle` job.

## Related repos

- `concourse-pipelines` — deploys this repo (`k8s-homelab/` pipelines); Concourse itself runs from `concourse/` here.
- `container-images` — builds `flipenergy/restic` and `flipenergy/nextcloud-news-updater` used here.
- `tf-playground` — Cloudflare DNS for the hostnames used in ingresses.
- `personal-website` — deployed to this cluster by CI, but not managed through `homelab.yaml`.
