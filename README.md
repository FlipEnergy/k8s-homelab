# Dennis' Homelab k8s playground
Just repo that holds stuff for my personal homelab k8s environment. There's a lot of encrypted files for storing my secrets in addition to override values files for helm charts.

# Helm charts repo
[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/flipenergy)](https://artifacthub.io/packages/search?repo=flipenergy)

Served as github page from branch gh-pages. Check out my charts on Artifact Hub or you can add the repo with
```
helm repo add flipenergy https://flipenergy.github.io/k8s-homelab/
```

# Requirements
- Kubectl
- Helm3
- Helm-secrets https://github.com/zendesk/helm-secrets
- Helm-diff https://github.com/databus23/helm-diff
- Helmsman https://github.com/Praqma/helmsman

# Bring all charts up according to helmsman file (Requires Docker)
```
make
```
