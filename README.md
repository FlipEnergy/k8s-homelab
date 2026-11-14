# Dennis' Homelab k8s playground
Just repo that holds stuff for my personal homelab k8s environment. There's a lot of encrypted files for storing my secrets in addition to override values files for helm charts.

Most apps use the [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts) chart. A few use upstream charts, and some use local charts in this repo. Deploy with `make deploy`.

# Publicly accessable services that I don't mind you using
- check out my website which has info and posts about my homelab: https://pleasenoddos.com

# Requirements
- Kubectl
- Helm3
- Sops https://github.com/getsops/sops
- Helm-secrets https://github.com/jkroepke/helm-secrets
- Helm-diff https://github.com/databus23/helm-diff
- Helmsman https://github.com/mkubaczyk/helmsman
