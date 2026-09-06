resource "vault_policy" "openclaw_certbot" {
  name = "openclaw-certbot"

  policy = <<-EOT
    path "homelab/kv/data/services/cloudflare/dns-cboxlab" {
      capabilities = ["read"]
    }

    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_approle_auth_backend_role" "openclaw_certbot" {
  for_each = toset([
    "openclaw-certbot",
    "openclaw-chinnu-certbot",
  ])

  backend                 = vault_auth_backend.approle.path
  role_name               = each.value
  bind_secret_id          = true
  secret_id_num_uses      = 0
  secret_id_ttl           = 0
  token_policies          = [vault_policy.openclaw_certbot.name]
  token_no_default_policy = true
  token_type              = "service"
  token_ttl               = 900
  token_max_ttl           = 3600
}
