# Valheim Server Backup Configuration

This ansible role now includes automated backup functionality using [restic](https://restic.net/) for backing up Valheim world saves to S3-compatible storage.

## Configuration

### Required Variables

Add these variables to your `inventory/group_vars/valheim_servers.yml` or in your vault:

```yaml
# Backup Configuration
backup_enabled: true
backup_schedule: "hourly"  # hourly, daily, weekly, or custom cron expression

# Restic S3 Configuration
restic_repository: "s3:https://s3.amazonaws.com/your-backup-bucket/valheim"
restic_password: "your-secure-restic-password"
restic_s3_access_key: "your-s3-access-key"
restic_s3_secret_key: "your-s3-secret-key"

# Optional: Uptime monitoring
uptime_url: "https://your-uptime-service.com/ping/your-uuid"
```

### Backup Settings

```yaml
backup_retention:
  keep_last: 10      # Keep 10 most recent backups
  keep_daily: 10     # Keep daily backups for 10 days
  keep_monthly: 12   # Keep monthly backups for 12 months

backup_paths:
  - "{{ valheim_data_dir }}/worlds_local"  # Valheim world saves
```

## Usage

### Automatic Backups

Once configured, backups will run automatically according to your schedule:
- **Hourly**: Every hour
- **Daily**: Once per day at midnight
- **Weekly**: Once per week on Sunday at midnight
- **Custom**: Use any systemd timer format

### Manual Backup Operations

Use the dedicated backup playbook for manual operations:

```bash
# Run interactive backup operations
ansible-playbook playbooks/backup.yml

# Or specify the operation directly
ansible-playbook playbooks/backup.yml -e backup_operation=backup
```

Available operations:
- `setup`: Install and configure backup system
- `backup`: Perform immediate backup
- `list`: List available backup snapshots
- `restore`: Restore from a backup (interactive)

### Direct Commands

```bash
# Check backup service status
sudo systemctl status backup-valheim.service

# Run manual backup
sudo systemctl start backup-valheim.service

# View backup logs
sudo journalctl -u backup-valheim.service -f

# List backup snapshots (as valheim user)
sudo -u valheim bash -c 'source /etc/restic-env && restic snapshots'

# Check backup timer
sudo systemctl status backup-valheim.timer
```

## S3 Setup

### AWS S3

1. Create an S3 bucket for backups
2. Create IAM user with programmatic access
3. Attach policy allowing s3:GetObject, s3:PutObject, s3:DeleteObject on your bucket

### Other S3-Compatible Services

The backup system works with any S3-compatible service:
- **MinIO**: `s3:http://your-minio-server:9000/bucket-name`
- **DigitalOcean Spaces**: `s3:https://nyc3.digitaloceanspaces.com/your-space`
- **Backblaze B2**: `b2:bucket-name`

## Security

- Backup credentials are stored in `/etc/restic-env` with 600 permissions
- Backups run as the `valheim` user
- Repository is encrypted with your restic password
- Use ansible-vault to encrypt sensitive variables

## Monitoring

If `uptime_url` is configured, the backup service will ping the URL after successful backups, allowing you to monitor backup health with services like:
- [Healthchecks.io](https://healthchecks.io/)
- [Uptime Robot](https://uptimerobot.com/)
- [Better Uptime](https://betterstack.com/uptime)

## Troubleshooting

### Backup Service Won't Start
```bash
# Check if repository is accessible
sudo -u valheim bash -c 'source /etc/restic-env && restic snapshots'

# Initialize repository if needed
sudo -u valheim bash -c 'source /etc/restic-env && restic init'
```

### S3 Connection Issues
```bash
# Test S3 connectivity
sudo -u valheim bash -c 'source /etc/restic-env && restic check'
```

### View Detailed Logs
```bash
sudo journalctl -u backup-valheim.service --since="1 hour ago" -n 50
```
