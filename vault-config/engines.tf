resource "vault_mount" "homelab_kv" {
  path = "homelab/kv"
  description = "KV Secrets used in homelab"
  type = "kv-v2"
}

