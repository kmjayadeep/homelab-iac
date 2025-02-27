resource "vault_jwt_auth_backend" "github" {
  description        = "Allow github actions to authenticate"
  path               = "jwt"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}
