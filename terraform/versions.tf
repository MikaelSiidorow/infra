terraform {
  required_version = ">= 1.12.2"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.52.0"
    }
  }
}
