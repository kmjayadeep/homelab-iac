variable "external_secrets_roles" {
  description = "Kubernetes identities and logical KV paths they may read. Map keys are Vault role names."
  type = map(object({
    kubernetes_namespace = string
    service_account_name = optional(string, "external-secrets-vault")
    secret_paths         = set(string)
  }))
  default = {
    actions-runner = {
      kubernetes_namespace = "actions-runner-system"
      secret_paths         = ["services/github/actions-runner"]
    }
    baskit-firebase = {
      kubernetes_namespace = "baskit"
      service_account_name = "external-secrets-vault-firebase"
      secret_paths         = ["services/firebase/baskit"]
    }
    baskit-runtime = {
      kubernetes_namespace = "baskit"
      service_account_name = "external-secrets-vault-runtime"
      secret_paths = [
        "services/ghcr/baskit-pull",
        "services/object-storage/baskit-backup",
      ]
    }
    beancount = {
      kubernetes_namespace = "beancount"
      secret_paths         = ["apps/beancount/auth"]
    }
    cert-manager-cloudflare = {
      kubernetes_namespace = "cert-manager"
      secret_paths         = ["services/cloudflare/dns-cboxlab"]
    }
    dotbintask = {
      kubernetes_namespace = "dotbintask"
      secret_paths         = ["apps/dotbintask/api"]
    }
    external-dns-cloudflare = {
      kubernetes_namespace = "external-dns"
      secret_paths         = ["services/cloudflare/dns-cboxlab"]
    }
    glance = {
      kubernetes_namespace = "glance"
      secret_paths = [
        "services/adguard/glance",
        "services/immich/glance",
      ]
    }
    litellm = {
      kubernetes_namespace = "litellm"
      secret_paths = [
        "apps/litellm/core",
        "services/postgresql/litellm",
      ]
    }
    monitoring-alertmanager = {
      kubernetes_namespace = "monitoring"
      service_account_name = "external-secrets-vault-alertmanager"
      secret_paths         = ["platform/monitoring/alertmanager"]
    }
    monitoring-grafana = {
      kubernetes_namespace = "monitoring"
      service_account_name = "external-secrets-vault-grafana"
      secret_paths         = ["platform/monitoring/grafana-admin"]
    }
    monitoring-loki = {
      kubernetes_namespace = "monitoring"
      service_account_name = "external-secrets-vault-loki"
      secret_paths         = ["services/object-storage/loki"]
    }
    monitoring-restic = {
      kubernetes_namespace = "monitoring"
      service_account_name = "external-secrets-vault-restic"
      secret_paths         = ["platform/backup/restic-exporter"]
    }
    monitoring-thanos = {
      kubernetes_namespace = "monitoring"
      service_account_name = "external-secrets-vault-thanos"
      secret_paths         = ["services/object-storage/thanos"]
    }
    otpcloud = {
      kubernetes_namespace = "totp"
      secret_paths = [
        "apps/otpcloud/core",
        "services/postgresql/otpcloud",
      ]
    }
    psuite = {
      kubernetes_namespace = "psuite"
      secret_paths         = ["apps/psuite/wiki"]
    }
    shoppinglist = {
      kubernetes_namespace = "shoppinglist"
      secret_paths         = ["services/postgresql/shoppinglist"]
    }
    taskplanner = {
      kubernetes_namespace = "taskplanner"
      secret_paths         = ["services/postgresql/taskplanner"]
    }
    torrents = {
      kubernetes_namespace = "torrents"
      secret_paths = [
        "services/vpn/deluge-openvpn",
        "services/vpn/deluge-wireguard",
      ]
    }
    vault-backup-storage = {
      kubernetes_namespace = "vault"
      service_account_name = "external-secrets-vault-backup"
      secret_paths         = ["services/object-storage/vault-backup"]
    }
    wallabag = {
      kubernetes_namespace = "wallabag"
      secret_paths         = ["apps/wallabag/core"]
    }
  }

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
  policy = join("\n\n", concat(
    [<<-EOT
      path "auth/token/lookup-self" {
        capabilities = ["read"]
      }
    EOT
    ],
    [
      for secret_path in sort(tolist(each.value.secret_paths)) : <<-EOT
        path "${vault_mount.homelab_kv.path}/data/${secret_path}" {
          capabilities = ["read"]
        }
      EOT
    ]
  ))
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
