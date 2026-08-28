variable "external_secrets_roles" {
  description = "Kubernetes identities and logical KV paths they may read. Map keys are Vault role names."
  type = map(object({
    kubernetes_namespace = string
    service_account_name = optional(string, "external-secrets-vault")
    secret_paths         = set(string)
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for role in values(var.external_secrets_roles) : [
        for path in role.secret_paths : can(regex("^(apps|services|platform)/[a-z0-9]+(-[a-z0-9]+)*(/[a-z0-9]+(-[a-z0-9]+)*)+$", path))
      ]
    ]))
    error_message = "Secret paths must have at least two lowercase, kebab-case components below apps/, services/, or platform/."
  }
}

resource "vault_policy" "external_secrets" {
  for_each = var.external_secrets_roles

  name = "external-secrets-${each.key}"
  policy = join("\n\n", [
    for secret_path in sort(tolist(each.value.secret_paths)) : <<-EOT
      path "${vault_mount.homelab_kv.path}/data/${secret_path}" {
        capabilities = ["read"]
      }
    EOT
  ])
}

resource "vault_kubernetes_auth_backend_role" "external_secrets" {
  for_each = var.external_secrets_roles

  backend                          = vault_kubernetes_auth_backend_config.cluster.backend
  role_name                        = each.key
  bound_service_account_names      = [each.value.service_account_name]
  bound_service_account_namespaces = [each.value.kubernetes_namespace]
  token_policies                   = [vault_policy.external_secrets[each.key].name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 3600
}
