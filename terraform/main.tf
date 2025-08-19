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
}

resource "hcloud_server" "coolify_server" {
  name        = "coolify-server"
  server_type = "cpx21" # 3 vCPU / 4GB RAM
  image       = "debian-12"
  location    = "hel1"
  ssh_keys    = [data.hcloud_ssh_key.this.id]

  firewall_ids = [hcloud_firewall.default.id]
}
