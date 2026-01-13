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

# =============================================================================
# siidorow.dev records
# =============================================================================

resource "cloudflare_dns_record" "siidorow_dev_root_a" {
  zone_id = cloudflare_zone.siidorow_dev.id
  type    = "A"
  name    = "siidorow.dev"
  content = "76.76.21.21"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "siidorow_dev_www" {
  zone_id = cloudflare_zone.siidorow_dev.id
  type    = "CNAME"
  name    = "www.siidorow.dev"
  content = "cname.vercel-dns.com"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "siidorow_dev_atproto" {
  zone_id = cloudflare_zone.siidorow_dev.id
  type    = "TXT"
  name    = "_atproto.siidorow.dev"
  content = "\"did=did:plc:7ajjqbub3qxysvscwvugeq5z\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "siidorow_dev_dmarc" {
  zone_id = cloudflare_zone.siidorow_dev.id
  type    = "TXT"
  name    = "_dmarc.siidorow.dev"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "siidorow_dev_domainkey_wildcard" {
  zone_id = cloudflare_zone.siidorow_dev.id
  type    = "TXT"
  name    = "*._domainkey.siidorow.dev"
  content = "\"v=DKIM1; p=\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "siidorow_dev_spf" {
  zone_id = cloudflare_zone.siidorow_dev.id
  type    = "TXT"
  name    = "siidorow.dev"
  content = "\"v=spf1 -all\""
  proxied = false
  ttl     = 1
}

# =============================================================================
# sweepmail.app records
# =============================================================================

resource "cloudflare_dns_record" "sweepmail_app_wildcard" {
  zone_id = cloudflare_zone.sweepmail_app.id
  type    = "CNAME"
  name    = "*.sweepmail.app"
  content = "pixie.porkbun.com"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "sweepmail_app_root" {
  zone_id = cloudflare_zone.sweepmail_app.id
  type    = "CNAME"
  name    = "sweepmail.app"
  content = "sweepmail.pages.dev"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "sweepmail_app_www" {
  zone_id = cloudflare_zone.sweepmail_app.id
  type    = "CNAME"
  name    = "www.sweepmail.app"
  content = "pixie.porkbun.com"
  proxied = true
  ttl     = 1
}
