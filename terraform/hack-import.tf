# Adopt the DNS-only record bootstrapped for the hackathon.
# Import format: https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/dns_record
import {
  to = cloudflare_dns_record.miksu_app_hack
  id = "f5e39ffae561880208531ae8779e2569/315b9072e8661d9a968f2523d8943b17"
}
