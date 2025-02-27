resource "vault_jwt_auth_backend_role" "near-dns" {
  backend           = vault_jwt_auth_backend.github.path
  role_name         = "auth.jwt.near-dns"
  bound_audiences   = ["https://github.com/kmjayadeep"]
  bound_claims_type = "string"
  bound_claims = {
    repository = "kmjayadeep/near-dns"
  }
  user_claim = "sub"
  role_type  = "jwt"
  token_ttl  = 300
  token_type = "service"
  token_policies = [
    vault_policy.near-dns.name
  ]
}

resource "vault_policy" "near-dns" {
  name   = "near-dns"
  policy = <<EOT
path "homelab/kv/data/near-dns/*" {
  capabilities = ["read"]
}
EOT
}

