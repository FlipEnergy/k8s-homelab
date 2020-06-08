# Dennis' Homelab k8s playground
Just repo that holds stuff for my personal homelab k8s environment.

# Documentation Resources
- Docker Post-install: https://docs.docker.com/engine/install/linux-postinstall/
- install MicroK8s: https://microk8s.io/docs
- MicroK8s Add ons: https://microk8s.io/docs/addons#heading--list
    - must haves:
        - helm3
        - dns
        - ingress
    - blog about k8s dashboard and fluentd logging: https://logz.io/blog/getting-started-with-kubernetes-using-microk8s/
- remote kubectl access to cluster: https://microk8s.io/docs/ports

# MicroK8s
## update cluster DNS upstream nameserver
```microk8s kubectl -n kube-system edit configmap/coredns```

## add custom DNS name for node to alt_names
```vi /var/snap/microk8s/current/certs/csr.conf.template```

# Install Helm Charts
## K8s Dashboards
https://kubernetes.github.io/dashboard/
https://github.com/kubernetes/dashboard
```
# install helm repo
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

# install it with ingress
kubectl create namespace kubernetes-dashboard
helm -n kubernetes-dashboard upgrade my-k8s-dashboard kubernetes-dashboard/kubernetes-dashboard -f helm-charts/k8s-dashboard-values.yaml --install --wait
```

Get token and copy to clipboard on windows ubuntu WSL:
```
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}') | grep token: | awk '{print $2}' | clip.exe
```

Go to website and login using token
