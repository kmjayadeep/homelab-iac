# Vault configuration

This Terraform configuration manages Vault auth methods, secret engines, and
policies. Secret values are written through a separate secure operator workflow
and must not be added to Terraform.

## External Secrets access

The path taxonomy and migration map are documented in [PATHS.md](PATHS.md).
Paths name the application or service that owns a credential rather than the
Kubernetes or VM consumer.

Add an entry to `external_secrets_roles` for each Kubernetes trust boundary when
its `SecretStore` and `ExternalSecret` are introduced. For example:

```hcl
external_secrets_roles = {
  example = {
    kubernetes_namespace = "example"
    service_account_name = "external-secrets-vault"
    secret_paths = [
      "apps/example/core",
      "services/postgresql/example",
    ]
  }
}
```

The map key is the Vault Kubernetes-auth role used by the `SecretStore`. The
`kubernetes_namespace` field only identifies the Kubernetes namespace containing
the ServiceAccount; it is not a Vault Enterprise namespace or part of a secret
path.

The existing `homelab/kv` KV v2 mount is shared by Kubernetes and non-Kubernetes
consumers. Access remains isolated by path policies. A workload or VM can be
granted access to an existing owner-based path without copying its value.

Vault uses its in-cluster ServiceAccount token and CA for Kubernetes TokenReview
requests. Ensure the Vault server ServiceAccount has the `system:auth-delegator`
role before applying this configuration.

The checked-in `.envrc` loads the current administrative token from `pass` for
Terraform operations; the token value is never committed. Prefer replacing the
root token with a scoped Terraform administration token when practical.
Terraform state is committed through `git-crypt` and must remain encrypted.
