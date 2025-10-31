# SSH Key Resource
data "hcloud_ssh_key" "nova_ssh_key" {
  name = var.ssh_public_key_name
}

# Server Resource
resource "hcloud_server" "nova" {
  name        = "nova"
  server_type = "cx23"
  image       = "debian-13"
  location    = "nbg1"
  
  ssh_keys = [data.hcloud_ssh_key.nova_ssh_key.id]

  network {
    network_id = hcloud_network.nova_network.id
    ip         = "10.10.0.10"
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
  
  labels = {
    environment = "homelab"
    managed_by  = "terraform"
  }

  firewall_ids = [hcloud_firewall.nova_firewall.id]
}

# Firewall resource for basic security
resource "hcloud_firewall" "nova_firewall" {
  name = "nova-firewall"
  
  # SSH access
  rule {
    direction = "in"
    port      = "22"
    protocol  = "tcp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  
  labels = {
    environment = "homelab"
    managed_by  = "terraform"
  }
}