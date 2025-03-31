resource "vault_mount" "homelab_kv" {
  path        = "homelab/kv"
  description = "KV Secrets used in homelab"
  type        = "kv-v2"
}

resource "vault_mount" "ssh" {
  path        = "homelab/ssh"
  type        = "ssh"
  description = "SSH secrets engine for homelab"
}
