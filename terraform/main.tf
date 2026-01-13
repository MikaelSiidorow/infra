data "hcloud_ssh_key" "this" {
  name = "mikaelsiidorow@pop-os"
}

resource "hcloud_firewall" "default" {
  name = "coolify-fw"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # These are used for Coolify configuration in Web UI, 
  # until custom domain and SSL Certs are set up
  # rule {
  #   direction  = "in"
  #   protocol   = "tcp"
  #   port       = "8000"
  #   source_ips = ["0.0.0.0/0", "::/0"]
  # }

  # rule {
  #   direction  = "in"
  #   protocol   = "tcp"
  #   port       = "6001"
  #   source_ips = ["0.0.0.0/0", "::/0"]
  # }

  # rule {
  #   direction  = "in"
  #   protocol   = "tcp"
  #   port       = "6002"
  #   source_ips = ["0.0.0.0/0", "::/0"]
  # }

  # Postgres
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "5432"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "coolify_server" {
  name        = "coolify-server"
  server_type = "cpx21" # 3 vCPU / 4GB RAM
  image       = "debian-12"
  location    = "hel1"
  ssh_keys    = [data.hcloud_ssh_key.this.id]

  firewall_ids = [hcloud_firewall.default.id]
}

# =============================================================================
# K3s Server (NixOS)
# =============================================================================

resource "hcloud_firewall" "k3s" {
  name = "k3s-fw"

  # SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTP
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # K3s API (restrict to your IP in production)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "hcloud_server" "k3s_server" {
  name        = "k3s-server"
  server_type = "cx23" # 2 vCPU / 4GB RAM / 40GB (shared cost optimized)
  image       = "debian-12" # Will be replaced with NixOS via nixos-anywhere
  location    = "hel1"
  ssh_keys    = [data.hcloud_ssh_key.this.id]

  firewall_ids = [hcloud_firewall.k3s.id]

  lifecycle {
    ignore_changes = [image] # Image changes after nixos-anywhere install
  }
}

resource "cloudflare_r2_bucket" "coolify_backups" {
  account_id = "0d7cd4f74493972b3d64775916c9f6ed"
  name       = "coolify-backups"
}

resource "cloudflare_r2_bucket" "terraform_state" {
  account_id   = "0d7cd4f74493972b3d64775916c9f6ed"
  name         = "terraform-state"
  jurisdiction = "eu"
}
