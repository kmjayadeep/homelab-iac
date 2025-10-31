resource "hcloud_network" "nova_network" {
  name     = "nova-network"
  ip_range = "10.10.0.0/16"
}

resource "hcloud_network_subnet" "nova_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.nova_network.id
  network_zone = "eu-central"
  ip_range     = "10.10.0.0/24"
}