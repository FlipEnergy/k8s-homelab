# Dennis' Homelab k8s playground
Just repo that holds stuff for my personal homelab k8s environment.

# Client requirements
- Kubectl
- Helm3
- Helm-secrets https://github.com/zendesk/helm-secrets
- Helm-diff https://github.com/databus23/helm-diff
- Helmsman https://github.com/Praqma/helmsman

# K8s Node requirements
- MicroK8s
- MicroK8s Add ons: https://microk8s.io/docs/addons#heading--list
    - enabled:
        - dns
        - metrics-server
        - metallb
        - storage

# Get Kubectl config
```sudo microk8s config```

# Bring all charts up according to helmsman file
```make```
