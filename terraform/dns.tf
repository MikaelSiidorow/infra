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

# =============================================================================
# m12w.me records
# =============================================================================

resource "cloudflare_dns_record" "m12w_me_atproto" {
  zone_id = cloudflare_zone.m12w_me.id
  type    = "TXT"
  name    = "_atproto.m12w.me"
  content = "\"did=did:plc:7ajjqbub3qxysvscwvugeq5z\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "m12w_me_dmarc" {
  zone_id = cloudflare_zone.m12w_me.id
  type    = "TXT"
  name    = "_dmarc.m12w.me"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s; rua=mailto:mikael@siidorow.com\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "m12w_me_domainkey_wildcard" {
  zone_id = cloudflare_zone.m12w_me.id
  type    = "TXT"
  name    = "*._domainkey.m12w.me"
  content = "\"v=DKIM1; p=\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "m12w_me_spf" {
  zone_id = cloudflare_zone.m12w_me.id
  type    = "TXT"
  name    = "m12w.me"
  content = "\"v=spf1 -all\""
  proxied = false
  ttl     = 1
}

# =============================================================================
# miksu.link records
# =============================================================================

resource "cloudflare_dns_record" "miksu_link_root_a" {
  zone_id = cloudflare_zone.miksu_link.id
  type    = "A"
  name    = "miksu.link"
  content = "76.76.21.21"
  proxied = false
  ttl     = 1
  comment = "Vercel root"
}

resource "cloudflare_dns_record" "miksu_link_www" {
  zone_id = cloudflare_zone.miksu_link.id
  type    = "CNAME"
  name    = "www.miksu.link"
  content = "cname.vercel-dns.com"
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_link_t_aaaa" {
  zone_id = cloudflare_zone.miksu_link.id
  type    = "AAAA"
  name    = "t.miksu.link"
  content = "100::"
  proxied = true
  ttl     = 1
}

# =============================================================================
# miksu.app records
# =============================================================================

resource "cloudflare_dns_record" "miksu_app_jono" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "AAAA"
  name    = "jono.miksu.app"
  content = "100::"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_turbodoc" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "AAAA"
  name    = "turbodoc.miksu.app"
  content = "100::"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_headscale" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "A"
  name    = "hs.miksu.app"
  content = hcloud_server.k3s_server.ipv4_address
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_refinery" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "A"
  name    = "refinery.miksu.app"
  content = hcloud_server.k3s_server.ipv4_address
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_refinery_zero" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "A"
  name    = "refinery-zero.miksu.app"
  content = hcloud_server.k3s_server.ipv4_address
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_marginalia" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "A"
  name    = "marginalia.miksu.app"
  content = hcloud_server.k3s_server.ipv4_address
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_marginalia_zero" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "A"
  name    = "zero.marginalia.miksu.app"
  content = hcloud_server.k3s_server.ipv4_address
  proxied = true
  ttl     = 1
}

# Marginalia email (Scaleway TEM)
resource "cloudflare_dns_record" "miksu_app_marginalia_spf" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "TXT"
  name    = "marginalia.miksu.app"
  content = "\"v=spf1 include:_spf.tem.scaleway.com -all\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_marginalia_dkim" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "TXT"
  name    = "7b9f3309-1a48-4cf2-b9fa-fab3dd0a6813._domainkey.marginalia.miksu.app"
  content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvOY6vL/a9vab+j3yKGwNo4faIZzOaZ4GnF79c/6z5+VtB4VIMeGxy3maUuXYTdV6ph/jRPEHluwgFdpsRGsQUed2BImrg1U4gRSai/Oo2YCaELmhoA5wmybzrUweBkxfuDOm1PUT3jI5tuh9tVlEn1k9Xxc2T52aDZ4ZdImTycxjkBRBITzHQ5zPh4eDe1+7NeNHFCtfAKMbQzT9+XBi0qzJPc0cBuYONHdi6GfFK98kYZtpUhOxfxf0jwV8EFO4UVHtUmZihSnARoEvMrBdjELZf1d2/VZ8E0ynxp1i6BrqeDw+rDp5BQ0OVGyjUvN2mhRYinF6fP7942qpcEkxNwIDAQAB\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_marginalia_dmarc" {
  zone_id = cloudflare_zone.miksu_app.id
  type    = "TXT"
  name    = "_dmarc.marginalia.miksu.app"
  content = "\"v=DMARC1; p=none\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "miksu_app_marginalia_mx" {
  zone_id  = cloudflare_zone.miksu_app.id
  type     = "MX"
  name     = "marginalia.miksu.app"
  content  = "blackhole.tem.scaleway.com"
  proxied  = false
  ttl      = 1
  priority = 10
}

# =============================================================================
# pluck.pics records
# =============================================================================

resource "cloudflare_dns_record" "pluck_pics_mx_route3" {
  zone_id  = cloudflare_zone.pluck_pics.id
  type     = "MX"
  name     = "pluck.pics"
  content  = "route3.mx.cloudflare.net"
  proxied  = false
  ttl      = 1
  priority = 47
}

resource "cloudflare_dns_record" "pluck_pics_mx_route2" {
  zone_id  = cloudflare_zone.pluck_pics.id
  type     = "MX"
  name     = "pluck.pics"
  content  = "route2.mx.cloudflare.net"
  proxied  = false
  ttl      = 1
  priority = 96
}

resource "cloudflare_dns_record" "pluck_pics_mx_route1" {
  zone_id  = cloudflare_zone.pluck_pics.id
  type     = "MX"
  name     = "pluck.pics"
  content  = "route1.mx.cloudflare.net"
  proxied  = false
  ttl      = 1
  priority = 51
}

resource "cloudflare_dns_record" "pluck_pics_dkim" {
  zone_id = cloudflare_zone.pluck_pics.id
  type    = "TXT"
  name    = "cf2024-1._domainkey.pluck.pics"
  content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "pluck_pics_dmarc" {
  zone_id = cloudflare_zone.pluck_pics.id
  type    = "TXT"
  name    = "_dmarc.pluck.pics"
  content = "\"v=DMARC1; p=none; rua=mailto:1670034898de41e9aac244d3998aeb8e@dmarc-reports.cloudflare.net\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "pluck_pics_google_verification" {
  zone_id = cloudflare_zone.pluck_pics.id
  type    = "TXT"
  name    = "pluck.pics"
  content = "\"google-site-verification=Qu4l-Y6pyiEPtghS_3Y63R41v3CCwI717dXqlidaTbU\""
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "pluck_pics_spf" {
  zone_id = cloudflare_zone.pluck_pics.id
  type    = "TXT"
  name    = "pluck.pics"
  content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "pluck_pics_root_aaaa" {
  zone_id = cloudflare_zone.pluck_pics.id
  type    = "AAAA"
  name    = "pluck.pics"
  content = "100::"
  proxied = true
  ttl     = 1
}

# =============================================================================
# siidorow.com records
# =============================================================================

resource "cloudflare_dns_record" "siidorow_com_root_a" {
  zone_id = cloudflare_zone.siidorow_com.id
  type    = "A"
  name    = "siidorow.com"
  content = "76.76.21.21"
  proxied = false
  ttl     = 1
}

# CNAME records
resource "cloudflare_dns_record" "siidorow_com_www" {
  zone_id = cloudflare_zone.siidorow_com.id
  type    = "CNAME"
  name    = "www.siidorow.com"
  content = "cname.vercel-dns.com"
  proxied = false
  ttl     = 1
}

# MX records (Google Workspace)
resource "cloudflare_dns_record" "siidorow_com_mx_alt3" {
  zone_id  = cloudflare_zone.siidorow_com.id
  type     = "MX"
  name     = "siidorow.com"
  content  = "alt3.aspmx.l.google.com"
  proxied  = false
  ttl      = 3600
  priority = 10
}

resource "cloudflare_dns_record" "siidorow_com_mx_primary" {
  zone_id  = cloudflare_zone.siidorow_com.id
  type     = "MX"
  name     = "siidorow.com"
  content  = "aspmx.l.google.com"
  proxied  = false
  ttl      = 3600
  priority = 1
}

resource "cloudflare_dns_record" "siidorow_com_mx_alt4" {
  zone_id  = cloudflare_zone.siidorow_com.id
  type     = "MX"
  name     = "siidorow.com"
  content  = "alt4.aspmx.l.google.com"
  proxied  = false
  ttl      = 3600
  priority = 10
}

resource "cloudflare_dns_record" "siidorow_com_mx_alt1" {
  zone_id  = cloudflare_zone.siidorow_com.id
  type     = "MX"
  name     = "siidorow.com"
  content  = "alt1.aspmx.l.google.com"
  proxied  = false
  ttl      = 3600
  priority = 5
}

resource "cloudflare_dns_record" "siidorow_com_mx_alt2" {
  zone_id  = cloudflare_zone.siidorow_com.id
  type     = "MX"
  name     = "siidorow.com"
  content  = "alt2.aspmx.l.google.com"
  proxied  = false
  ttl      = 3600
  priority = 5
}

# TXT records
resource "cloudflare_dns_record" "siidorow_com_dkim" {
  zone_id = cloudflare_zone.siidorow_com.id
  type    = "TXT"
  name    = "cf2024-1._domainkey.siidorow.com"
  content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "siidorow_com_dmarc" {
  zone_id = cloudflare_zone.siidorow_com.id
  type    = "TXT"
  name    = "_dmarc.siidorow.com"
  content = "\"v=DMARC1; p=none; rua=mailto:bfc996ec26d74328985ccdce900879a8@dmarc-reports.cloudflare.net\""
  proxied = false
  ttl     = 1
}

resource "cloudflare_dns_record" "siidorow_com_spf" {
  zone_id = cloudflare_zone.siidorow_com.id
  type    = "TXT"
  name    = "siidorow.com"
  content = "\"v=spf1 include:_spf.google.com -all\""
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "siidorow_com_google_verification" {
  zone_id = cloudflare_zone.siidorow_com.id
  type    = "TXT"
  name    = "siidorow.com"
  content = "\"google-site-verification=mse43FSKT_uszYVj1W6MpwXPs0DPfiXgol8lUgXWqAo\""
  proxied = false
  ttl     = 1
}
