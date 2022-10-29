# Soft-serve

## View the TUI
1. port-forward to the container with port 23231
2. run `ssh -p 23231 -i ~/.ssh/homelab localhost`

## Update config
clone the repo with
`GIT_SSH_COMMAND='ssh -p 23231 -i ~/.ssh/homelab' git clone ssh://localhost:23231/config`
