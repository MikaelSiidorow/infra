# Infrastructure

Infrastructure as Code for personal projects.

## Structure

```
infra/
├── terraform/           # Cloud resources (Hetzner, Cloudflare)
├── nixos/               # NixOS server configurations
├── k8s/                 # Kubernetes manifests
└── .github/workflows/
    └── deploy.yml       # Unified CI (terraform, nixos, k8s)
```

## Deploying

Push to `main` triggers deploys automatically based on changed paths. Manual deploys via workflow dispatch (select component: `terraform`, `nixos`, `k8s`, or `all`).

### Initial Setup (new server)

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

4. Apply K8s manifests:
   ```bash
   ssh root@<IP> "kubectl apply -f -" < k8s/refinery/namespace.yaml
   ssh root@<IP> "kubectl apply -f -" < k8s/refinery/secrets.yaml
   scp -r k8s/refinery/ root@<IP>:/tmp/k8s-deploy/refinery/
   ssh root@<IP> "kubectl apply -f /tmp/k8s-deploy/refinery/ && rm -rf /tmp/k8s-deploy"
   ```

### Subsequent Changes

Push to `main` or trigger the Deploy workflow manually from GitHub.

### Local kubectl Access

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

Or run kubectl directly on the server via SSH:

```bash
ssh root@<IP> "kubectl get pods -n refinery"
```

## Secrets

Managed via GitHub Actions:

- **Variables**: `K3S_HOST`
- **Secrets**: provider tokens, SSH keys, app secrets (see workflow for full list)

K8s secrets are templated from GitHub secrets during CI. `k8s/**/secrets.yaml` is gitignored.
