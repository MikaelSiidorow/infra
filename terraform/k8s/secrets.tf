resource "kubernetes_secret_v1" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = "cert-manager"
  }

  data = {
    api-token = var.cloudflare_api_token
  }
}

resource "kubernetes_secret_v1" "alertmanager_telegram_token" {
  metadata {
    name      = "alertmanager-telegram-token"
    namespace = "monitoring"
  }

  data = {
    bot-token = var.telegram_bot_token
  }
}

resource "kubernetes_secret_v1" "refinery_secrets" {
  metadata {
    name      = "refinery-secrets"
    namespace = "refinery"
  }

  data = {
    POSTGRES_PASSWORD      = var.refinery_postgres_password
    DATABASE_URL           = "postgresql://refinery:${var.refinery_postgres_password}@refinery-db:5432/refinery"
    ENCRYPTION_KEY         = var.refinery_encryption_key
    GITHUB_CLIENT_SECRET   = var.refinery_github_client_secret
    LINKEDIN_CLIENT_SECRET = var.refinery_linkedin_client_secret
    ZERO_ADMIN_PASSWORD    = var.refinery_zero_admin_password
  }
}
