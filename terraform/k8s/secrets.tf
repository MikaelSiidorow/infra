resource "kubernetes_secret_v1" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = "cert-manager"
  }

  data = {
    api-token = var.cloudflare_api_token
  }
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = "monitoring"
  }

  data = {
    admin-user     = "admin"
    admin-password = var.grafana_admin_password
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

resource "kubernetes_namespace_v1" "gatus" {
  metadata {
    name = "gatus"
  }
}

resource "kubernetes_secret_v1" "gatus_telegram_token" {
  metadata {
    name      = "gatus-telegram-token"
    namespace = kubernetes_namespace_v1.gatus.metadata[0].name
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

# Marginalia auto-generated secrets
resource "random_password" "marginalia_postgres_password" {
  length  = 32
  special = false
}

resource "random_password" "marginalia_better_auth_secret" {
  length  = 32
  special = false
}

resource "random_password" "marginalia_zero_admin_password" {
  length  = 32
  special = false
}

resource "kubernetes_secret_v1" "marginalia_secrets" {
  metadata {
    name      = "marginalia-secrets"
    namespace = "marginalia"
  }

  data = {
    POSTGRES_PASSWORD    = random_password.marginalia_postgres_password.result
    DATABASE_URL         = "postgresql://marginalia:${random_password.marginalia_postgres_password.result}@marginalia-db:5432/marginalia"
    DATABASE_CVR_URL     = "postgresql://marginalia:${random_password.marginalia_postgres_password.result}@marginalia-db:5432/marginalia_cvr"
    DATABASE_CDB_URL     = "postgresql://marginalia:${random_password.marginalia_postgres_password.result}@marginalia-db:5432/marginalia_cdb"
    BETTER_AUTH_SECRET   = random_password.marginalia_better_auth_secret.result
    ZERO_ADMIN_PASSWORD  = random_password.marginalia_zero_admin_password.result
    GITHUB_CLIENT_SECRET = var.marginalia_github_client_secret
    SMTP_HOST            = var.marginalia_smtp_host
    SMTP_USER            = var.marginalia_smtp_user
    SMTP_PASS            = var.marginalia_smtp_pass
    SMTP_FROM            = var.marginalia_smtp_from
  }
}
