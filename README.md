# Dennis' Homelab k8s playground
Just repo that holds stuff for my personal homelab k8s environment.

# Client requirements
- Kubectl
- Helm3
- Helm-secrets https://github.com/zendesk/helm-secrets

# K8s Node requirements
- MicroK8s
- MicroK8s Add ons: https://microk8s.io/docs/addons#heading--list
    - must haves:
        - dns
        - ingress
        - metrics-server
- remote kubectl access to cluster: https://microk8s.io/docs/ports

# Get Kubectl config
```microk8s kubectl config view --raw```

Change `server: https://127.0.0.1:16443` to the ip or hostname of the node

# Install all Helm Charts
```
make
```

# Install Helm Charts
## K8s Dashboards
https://kubernetes.github.io/dashboard/

https://github.com/kubernetes/dashboard

Initial install
```
make add-repos
kubectl create namespace kubernetes-manage
make k8s-dashboard-init
```

Go to website and login using token.

# Install Kubernetes Operational View
https://github.com/hjacobs/kube-ops-view

https://hub.kubeapps.com/charts/stable/kube-ops-view

Initial install
```
make add-repos
kubectl create namespace kubernetes-manage
make kube-ops-view-init
```
