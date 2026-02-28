variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "refinery_postgres_password" {
  type      = string
  sensitive = true
}

variable "refinery_encryption_key" {
  type      = string
  sensitive = true
}

variable "refinery_github_client_secret" {
  type      = string
  sensitive = true
}

variable "refinery_linkedin_client_secret" {
  type      = string
  sensitive = true
}

variable "refinery_zero_admin_password" {
  type      = string
  sensitive = true
}

variable "telegram_bot_token" {
  type      = string
  sensitive = true
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}
