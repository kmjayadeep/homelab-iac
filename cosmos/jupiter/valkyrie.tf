module "valkyrie" {
  source = "../../terraform-modules/proxmox-vm-qemu"

  vmid        = 209
  target_node = "jupiter"
  name        = "valkyrie"
  clone       = "nixos-base"
  cores       = 2
  memory      = 4096
  desc        = "valkyrie valheim server for nomap hardcore run"
  sshkeys     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDVFwMXBBljf+W5diHw9sz+A5AQhojFh8xXHCvznJkebVimhPU18dP7aL6K91tMdx+1rDbW3XyqWlAcuJY55j/G1JMyMGGTSCWkUlovZArqFAWxyadQ9s7Ev13bSF+h2qaL1x8tFAYK/L/LR4OOHSKXzqdeS2WeZgIFEuBW6HDnlGGV0aVVLo6f7wTIt4QK48IiUxKDo+giN5vmXtcBg0F88DhbDtLip3Yab6Sqm4v5PCIM4XiKkULqMLGqfQoUItFi0MGEq1P2qvQ/pVdHEjMoPjXfnwI0Jr4T6NN/QO8lsEfyYlI8qtZ2MvTYdqmOvrY37cYx2BJsIQvwC1wzERgqboEUk0qsRwNqIUcAbOaBIADDn11FUQyvYZ2S8QeIqiwkdyE+jJuPTTgzh5RtuFoqyKuIQohzPDIhAmr65xygcYUyM7vRji5F20dVxc92fNc7ec1FCsbPoSHdW41PkimO2+plyhMFkYrbRo2Hzi6pW+LkmPDbZTMWDo6RM07G+1DIGoDUmSxCQDgkoHHG+x6U0mKh2YSX9zwIxr/9h/dvEyWYCG09XNmxFlGHNNlb0Us52UJ4Ax53WnNoxECH0RDojRQkn3m3v0xxFU9C/RaER48N7ppEDjL9dtcM0lF714TbpBQYBM2oJYJIoCX0Cj/fyrSxofHTYARsnBzblDZA9Q== kmjayadeep@gmail.com"
  ipv4_addr   = "192.168.1.79/24"
  ipv4_gw     = "192.168.1.1"
  disk_size   = "200G"
  tags        = "game,valheim"
  vm_state    = "stopped"
}

module "valkyrie_s3" {
  source      = "../../terraform-modules/minio_s3_bucket"
  name        = "valkyrie-valheim-backup"
  create_user = true
}
