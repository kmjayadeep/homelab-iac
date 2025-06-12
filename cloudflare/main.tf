resource "cloudflare_r2_bucket" "postgres-cosmos-backup" {
  account_id    = "de346322c951eb2e500a79df4f02317f"
  name          = "postgres-cosmos-backup"
  storage_class = "Standard"
  jurisdiction  = "eu"
}
