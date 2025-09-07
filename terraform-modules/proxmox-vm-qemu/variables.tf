variable "vmid" {
  type = number
}

variable "target_node" {
  type = string
}

variable "name" {
  type = string
}

variable "clone" {
  default = ""
  type    = string
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

variable "balloon" {
  type    = number
  default = null
}

variable "onboot" {
  description = "Start the VM on Proxmox host boot"
  type        = bool
  default     = true
}

variable "desc" {
  type = string
}

variable "sshkeys" {
  type = string
}

variable "ipv4_addr" {
  description = "Static ipv4 address for the VM. Eg: 192.168.1.100/24"
}

variable "ipv4_gw" {
  description = "Ipv4 gateway. Eg: 192.168.1.1"
}

variable "vm_state" {
  type    = string
  default = "running"
}

variable "disk_size" {
  type        = string
  description = "Disk size. Eg: 30G"
  default     = "50G"
}

variable "storage" {
  type        = string
  description = "Proxmox storage to use for the VM disk and cloudinit"
  default     = "local-lvm"
}

variable "tags" {
  description = "Comma separated tags for the VM"
  type        = string
  default     = ""
}
