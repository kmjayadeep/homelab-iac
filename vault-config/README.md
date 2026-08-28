# Vault configuration

This Terraform configuration manages Vault auth methods, secret engines, and
policies. Secret values are written through a separate secure operator workflow
and must not be added to Terraform.

## External Secrets application access

Add an entry to `external_secrets_applications` for each Kubernetes application
when its `SecretStore` and `ExternalSecret` are introduced. For example:

```hcl
external_secrets_applications = {
  example = {
    kubernetes_namespace = "example"
    application          = "example"
    service_account_name = "external-secrets-vault"
  }
}
```

The map key is the Vault Kubernetes-auth role used by the `SecretStore`. Each
identity can read only `homelab/kv/apps/<application>` and its descendants. The
`kubernetes_namespace` field is only the Kubernetes namespace containing the
ServiceAccount; it is not a Vault Enterprise namespace or part of the secret
path.

The existing `homelab/kv` KV v2 mount is shared by Kubernetes and non-Kubernetes
consumers. Access remains isolated by path policies; another workload or VM can
be granted access to the same application path when it legitimately shares the
secret, without copying the value to another mount.

Vault uses its in-cluster ServiceAccount token and CA for Kubernetes TokenReview
requests. Ensure the Vault server ServiceAccount has the `system:auth-delegator`
role before applying this configuration.

The checked-in `.envrc` loads the current administrative token from `pass` for
Terraform operations; the token value is never committed. Prefer replacing the
root token with a scoped Terraform administration token when practical.
Terraform state is committed through `git-crypt` and must remain encrypted.
