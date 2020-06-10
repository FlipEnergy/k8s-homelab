# Dennis' Homelab k8s playground
Just repo that holds stuff for my personal homelab k8s environment.

# Documentation Resources
- Docker Post-install: https://docs.docker.com/engine/install/linux-postinstall/
- install MicroK8s: https://microk8s.io/docs
- MicroK8s Add ons: https://microk8s.io/docs/addons#heading--list
    - must haves:
        - dns
        - ingress
        - metrics-server
    - blog about k8s dashboard and fluentd logging: https://logz.io/blog/getting-started-with-kubernetes-using-microk8s/
- remote kubectl access to cluster: https://microk8s.io/docs/ports

# MicroK8s

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
