resource "vault_ssh_secret_backend_role" "jailmaker-docker" {
  name                    = "jailmaker-docker"
  backend                 = vault_mount.ssh.path
  key_type                = "ca"
  allow_user_certificates = true
  allowed_users           = "ubuntu,admin,root"
  default_extensions = {
    "permit-pty" = ""
  }
  ttl     = "30m"
  max_ttl = "1h"
}

resource "vault_jwt_auth_backend_role" "homelab-docker-stacks" {
  backend           = vault_jwt_auth_backend.github.path
  role_name         = "auth.jwt.homelab-docker-stacks"
  bound_audiences   = ["https://github.com/kmjayadeep"]
  bound_claims_type = "string"
  bound_claims = {
    repository = "kmjayadeep/homelab-docker-stacks"
  }
  user_claim = "sub"
  role_type  = "jwt"
  token_ttl  = 300
  token_type = "service"
  token_policies = [
    vault_policy.homelab-docker-stacks.name
  ]
}

resource "vault_policy" "homelab-docker-stacks" {
  name = "homelab-docker-stacks"

  policy = <<EOT
path "homelab/ssh/sign/jailmaker-docker" {
  capabilities = ["create", "update"]
}

path "homelab/ssh/config/ca" {
  capabilities = ["read"]
}
EOT
}
