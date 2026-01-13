terraform {
  required_version = ">= 1.12.2"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.52.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">=5.8.0"
    }
  }
}
