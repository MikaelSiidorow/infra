# Infrastructure

Infrastructure as Code for personal projects.

## Architecture

```
NixOS (k3s.nix)                              Terraform (terraform/k8s/)
  |                                             |
  |-- Traefik (ingress)                         |-- refinery namespace
  |-- cert-manager (TLS)                        |-- refinery-secrets
  |-- ArgoCD (GitOps)
  |-- Bootstrap Application
  |
  v
ArgoCD auto-syncs from git
  |
  |-- k8s/apps/refinery.yaml  -->  k8s/refinery/*.yaml
```

**Separation of concerns:**

- **Terraform** (`terraform/`) provisions cloud infrastructure (Hetzner server, Cloudflare DNS)
- **NixOS** (`nixos/`) manages the server OS and cluster platform (K3s, Traefik, cert-manager, ArgoCD)
- **Terraform K8s** (`terraform/k8s/`) manages application secrets (the part that can't be in Git)
- **ArgoCD** syncs application manifests from `k8s/` in Git to the cluster

## Structure

```
infra/
├── terraform/               # Cloud resources (Hetzner, Cloudflare)
│   └── k8s/                 # K8s secrets (Terraform + kubernetes provider)
├── nixos/                   # NixOS server configurations
├── k8s/
│   ├── apps/                # ArgoCD Application manifests
│   ├── refinery/            # Refinery K8s manifests
│   ├── headscale/           # Headscale ingress
│   └── argocd-ingress/      # ArgoCD ingress
├── docs/                    # Architecture & observability docs
├── bin/                     # Utility scripts (ssh)
└── .github/workflows/
    ├── deploy.yml           # CI pipeline
    └── k8s-rollout.yml      # K8s rollout restart (reusable)
```

## Deploying

Push to `main` triggers deploys automatically based on changed paths. Manual deploys via workflow dispatch (select component: `terraform`, `nixos`, `k8s-terraform`, or `all`).

### Deploy pipeline ordering

```
terraform  →  nixos  →  k8s-terraform
(infra)       (OS)      (app secrets)
                           ↓
                     ArgoCD auto-syncs
                     (app manifests from git)
```

1. **`terraform`** — creates/updates cloud resources (server, DNS)
2. **`nixos`** — deploys NixOS config via deploy-rs (installs K3s, ArgoCD, etc.)
3. **`k8s-terraform`** — creates namespaces and secrets via SSH tunnel to K3s API
4. **ArgoCD** — automatically syncs `k8s/apps/` → application workloads (no CI needed)

K8s manifest changes (`k8s/refinery/`) are deployed by ArgoCD within ~3 minutes of pushing to `main`. No CI job is needed for these.

### Initial setup (new server)

1. Provision server with Terraform:

   ```bash
   cd terraform && terraform apply
   terraform output k3s_ipv4_address
   ```

2. Update `flake.nix` with the new IP.

3. Install NixOS via nixos-anywhere:

   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#k8s-server --target-host root@<IP>
   ```

4. Wait for ArgoCD to start:

   ```bash
   ssh root@<IP> "kubectl get pods -n argocd"
   ```

5. Apply K8s secrets via Terraform:

   ```bash
   cd terraform/k8s
   terraform init
   terraform apply
   ```

6. Verify ArgoCD synced the apps:
   ```bash
   ssh root@<IP> "kubectl get applications -n argocd"
   ```

### Local kubectl access

The K3s API (port 6443) is not exposed to the internet. Use an SSH tunnel:

```bash
ssh -L 6443:127.0.0.1:6443 root@$(terraform -chdir=terraform output -raw k3s_ipv4_address)
```

Then in another terminal:

```bash
# Fetch kubeconfig (one-time)
ssh root@<IP> cat /etc/rancher/k3s/k3s.yaml > ~/.kube/k3s-config

# Use it
KUBECONFIG=~/.kube/k3s-config kubectl get pods -n refinery
```

## Secrets

- **GitHub Actions secrets**: provider tokens (`HCLOUD_TOKEN`, `CLOUDFLARE_API_TOKEN`), SSH keys, R2 credentials, app secrets (`REFINERY_*`)
- **GitHub Actions variables**: `K3S_HOST`
- **K8s secrets**: managed by `terraform/k8s/`, passed as `TF_VAR_*` env vars in CI. `k8s/**/secrets.yaml` is gitignored.
