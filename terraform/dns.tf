locals {
  account_id = "0d7cd4f74493972b3d64775916c9f6ed"
}

resource "cloudflare_zone" "draftkingdom_lol" {
  account = { id = local.account_id }
  name    = "draftkingdom.lol"
}

resource "cloudflare_zone" "m12w_me" {
  account = { id = local.account_id }
  name    = "m12w.me"
}

resource "cloudflare_zone" "miksu_app" {
  account = { id = local.account_id }
  name    = "miksu.app"
}

resource "cloudflare_zone" "miksu_link" {
  account = { id = local.account_id }
  name    = "miksu.link"
}

resource "cloudflare_zone" "pluck_pics" {
  account = { id = local.account_id }
  name    = "pluck.pics"
}

resource "cloudflare_zone" "seiska_lol" {
  account = { id = local.account_id }
  name    = "seiska.lol"
}

resource "cloudflare_zone" "siidorow_com" {
  account = { id = local.account_id }
  name    = "siidorow.com"
}

resource "cloudflare_zone" "siidorow_dev" {
  account = { id = local.account_id }
  name    = "siidorow.dev"
}

resource "cloudflare_zone" "sweepmail_app" {
  account = { id = local.account_id }
  name    = "sweepmail.app"
}
