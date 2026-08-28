variable "external_secrets_applications" {
  description = "Kubernetes identities allowed to read an application's Vault secrets. Map keys are Vault role names."
  type = map(object({
    kubernetes_namespace = string
    application          = string
    service_account_name = optional(string, "external-secrets-vault")
  }))
  default = {}
}

resource "vault_policy" "external_secrets_application" {
  for_each = var.external_secrets_applications

  name   = "external-secrets-${each.key}"
  policy = <<-EOT
    path "${vault_mount.homelab_kv.path}/data/apps/${each.value.application}" {
      capabilities = ["read"]
    }

    path "${vault_mount.homelab_kv.path}/data/apps/${each.value.application}/*" {
      capabilities = ["read"]
    }

    path "${vault_mount.homelab_kv.path}/metadata/apps/${each.value.application}" {
      capabilities = ["read"]
    }

    path "${vault_mount.homelab_kv.path}/metadata/apps/${each.value.application}/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "external_secrets_application" {
  for_each = var.external_secrets_applications

  backend                          = vault_kubernetes_auth_backend_config.cluster.backend
  role_name                        = each.key
  bound_service_account_names      = [each.value.service_account_name]
  bound_service_account_namespaces = [each.value.kubernetes_namespace]
  token_policies                   = [vault_policy.external_secrets_application[each.key].name]
  token_no_default_policy          = true
  token_ttl                        = 900
  token_max_ttl                    = 3600
}
