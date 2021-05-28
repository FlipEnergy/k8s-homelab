# Dennis' Homelab k8s playground
Just repo that holds stuff for my personal homelab k8s environment. There's a lot of encrypted files for storing my secrets in addition to override values files for helm charts.

A lot of the charts I use are from [k8s-at-home](https://github.com/k8s-at-home/charts) and I'm now also a contributer there.

# Publicly accessable services
- check out my website which has info and posts about my homelab: https://pleasenoddos.com
- Search with https://whoogle.pleasenoddos.com/
- Use my instance of Focalboard at https://focal.pleasenoddos.com (I do not guarantee your data will never be lost but I personally use this)
- Watch my stream at https://stream.pleasenoddos.com

# Requirements
- Kubectl
- Helm3
- Helm-secrets https://github.com/databus23/helm-secrets
- Helm-diff https://github.com/databus23/helm-diff
- Helmsman https://github.com/Praqma/helmsman

# Bring all charts up according to helmsman file (Requires Docker and my secret key)
```
make
```
