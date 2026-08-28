resource "vault_jwt_auth_backend" "github" {
  description        = "Allow github actions to authenticate"
  path               = "jwt"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

resource "vault_auth_backend" "kubernetes" {
  type        = "kubernetes"
  path        = "kubernetes"
  description = "Authenticate Kubernetes workloads, including External Secrets"
}

# Vault runs in the cluster, so the auth backend uses the pod's service account
# token and CA to perform TokenReview requests. No reviewer credential is stored
# in Terraform or Git.
resource "vault_kubernetes_auth_backend_config" "cluster" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc:443"
}

resource "vault_ssh_secret_backend_ca" "ssh_ca" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
}
