resource "kubernetes_namespace_v1" "refinery" {
  metadata {
    name = "refinery"
  }
}

resource "kubernetes_secret_v1" "refinery_secrets" {
  metadata {
    name      = "refinery-secrets"
    namespace = kubernetes_namespace_v1.refinery.metadata[0].name
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
