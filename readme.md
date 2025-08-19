# Hetzner + Debian + Coolify — Infra-as-Code

This repo provisions a Hetzner Cloud VM running **Debian 12**, installs **Docker** and **Coolify**, and leaves you ready to deploy containerized apps (e.g., your Python + LightGBM inference API).

## Prerequisites

- Hetzner Cloud account and **API token**
- An **SSH key** already uploaded to Hetzner Cloud (Project → Security → SSH keys)
- Local tools: `terraform` (>= 1.5), `ansible` (>= 2.14), `ssh`, `make`, `bash`

## Quick Start

1. **Clone + configure**

   ```bash
   git clone <this-repo> infra-ml
   cd infra-ml
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # edit terraform.tfvars: set hcloud_token, ssh_key_name, desired server_type/location
   ```

2. **Provision VM + firewall**

   ```bash
   make tf-init
   make tf-apply
   ```

   Save the outputs printed (especially `ipv4_address`).

3. **Generate Ansible inventory**

   ```bash
   make inventory
   cat ansible/inventory.ini
   ```

4. **Install Docker + Coolify** (via Ansible)

   ```bash
   make provision
   ```

   When it finishes, open `http://<ipv4_address>:8000` to access Coolify first-run UI.

   > **Tip**: After initial setup, add a domain in Coolify for your apps; Coolify will auto-provision SSL.

5. **(Optional) SSH in**

   ```bash
   make ssh
   ```

## Rebuild / Tear down

- **Re-run provisioning**: `make provision`
- **Destroy infra**: `make tf-destroy`

## Security Notes

- This is a minimal baseline: Hetzner firewall allows 22/80/443. Adjust to your needs.
- Consider adding a Cloudflare proxy and enabling Coolify’s OAuth integrations for the UI.

## Where to put app definitions?

- Export your Coolify app configs from the UI and commit them under `coolify/app-configs/` so you can re-import later.
