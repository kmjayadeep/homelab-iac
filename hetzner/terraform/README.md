# Hetzner Cloud Terraform Configuration - Nova Server

This Terraform configuration creates a server named "nova" on Hetzner Cloud with hardcoded settings.

## Setup

1. **Set your Hetzner Cloud API token**:
   ```bash
   export HCLOUD_TOKEN="your_hetzner_cloud_api_token_here"
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
- **Network**: 10.10.0.0/16
- **Firewall**: SSH (22)
- **SSH Key**: main