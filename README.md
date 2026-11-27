# Dennis' Homelab k8s playground
Just the repo that holds stuff for my personal homelab k8s environment. There's a lot of encrypted files for storing my secrets in addition to override values files for helm charts.

Most apps use the [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts) chart. A few use upstream charts, and some use local charts in this repo. Deploy with `make deploy`.