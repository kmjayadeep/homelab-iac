resource "vault_policy" "vault_raft_snapshot" {
  name   = "vault-raft-snapshot"
  policy = <<-EOT
    path "sys/storage/raft/snapshot" {
      capabilities = ["read", "sudo"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "vault_raft_snapshot" {
  backend                          = vault_kubernetes_auth_backend_config.cluster.backend
  role_name                        = "vault-raft-snapshot"
  bound_service_account_names      = ["vault-backup"]
  bound_service_account_namespaces = ["vault"]
  token_policies                   = [vault_policy.vault_raft_snapshot.name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 900
}
