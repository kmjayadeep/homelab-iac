# Hetzner Cloud Terraform Configuration - Nova Server

This Terraform configuration creates a server named "nova" on Hetzner Cloud with hardcoded settings.

## Setup

1. **Configure environment variables**:
   ```bash
   # Set your API tokens
   export HCLOUD_TOKEN="your_hetzner_token"
   export CLOUDFLARE_API_TOKEN="your_cloudflare_token"
   ```

   or use direnv with pass to store the token

   ```
   direnv allow
   ```

2. **Deploy the server**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Server Configuration

- **Name**: nova
- **Type**: cx23 (2 vCPU, 8GB RAM, 40GB SSD)
- **OS**: Debian 13
- **Location**: Nuremberg (nbg1)
- **Network**: IPv6-only with private network (10.10.0.10/24)
- **DNS**: nova.cboxlab.com (AAAA record)

## Access

After deployment:

**Via IPv6 address:**
```bash
terraform output nova_ssh_connection_command_ipv6
```

**Via DNS name:**
```bash
terraform output nova_ssh_connection_command_dns
# Or directly:
ssh -6 root@nova.hetzner.cboxlab.com
```

## DNS Record

The configuration automatically creates:
- **AAAA record**: `nova.hetzner.cboxlab.com` → server IPv6 address
- **TTL**: 300 seconds
- **Managed by**: Terraform (with comment)

## Outputs

- `nova_ipv6_address`: Server's public IPv6 address
- `nova_dns_fqdn`: Full DNS name (nova.hetzner.cboxlab.com)
- `nova_ssh_connection_command_ipv6`: SSH via IPv6
- `nova_ssh_connection_command_dns`: SSH via DNS name
