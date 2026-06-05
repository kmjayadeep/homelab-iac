# OpenClaw VM Ansible Setup

This Ansible project installs OpenClaw on the `openclaw` VM using the upstream installer from <https://openclaw.ai/>.

## Prerequisites

- Ansible installed locally
- SSH access to `openclaw.cosmos.cboxlab.com`
- SSH key configured for the `ansible` user

## VM preparation

### 1. Install Ansible collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### 2. Verify connectivity

```bash
ansible all -m ping
```

### 3. Install OpenClaw

```bash
ansible-playbook playbooks/setup.yml
```

The playbook installs base packages, creates an `openclaw` user, adds your SSH key, configures git, installs OpenClaw, and configures Nginx + Let's Encrypt SSL for the OpenClaw gateway using Cloudflare DNS challenge.

OpenClaw dashboard traffic is proxied from `https://openclaw.cosmos.cboxlab.com` to the local Gateway Control UI at `http://127.0.0.1:18789`, which is the dashboard URL documented by OpenClaw. The Nginx vhost keeps the upstream on loopback, preserves WebSocket upgrades for Control UI auth, and adds static asset caching and security headers.

The OpenClaw installer command is:

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard --verify
```

Optional environment variable:

- `OPENCLAW_EMAIL` - git email for the `openclaw` user. Defaults to `openclaw@localhost`.
- `CLOUDFLARE_API_TOKEN` - Cloudflare API token used for the Let's Encrypt DNS challenge.
- `OPENCLAW_CERTBOT_EMAIL` - Let's Encrypt registration email. Defaults to `OPENCLAW_EMAIL`, then `admin@cboxlab.com`.

## Backups

Setup installs a restic systemd timer that periodically backs up `/home/openclaw/.openclaw/` to the MinIO bucket `openclaw-backup`.

Set these values via environment variables, Ansible vault, or host/group vars before running setup:

```yaml
restic_repository: s3:https://minio.cosmos.cboxlab.com/openclaw-backup
restic_password: your-restic-password
restic_s3_access_key: your-access-key
restic_s3_secret_key: your-secret-key
uptimekuma_url: https://uptime.example.com/api/push/...
```

Environment variable names are also supported:

```bash
export OPENCLAW_RESTIC_REPOSITORY=s3:https://minio.cosmos.cboxlab.com/openclaw-backup
export OPENCLAW_RESTIC_PASSWORD=...
export OPENCLAW_RESTIC_S3_ACCESS_KEY=...
export OPENCLAW_RESTIC_S3_SECRET_KEY=...
export UPTIMEKUMA_URL=https://uptime.example.com/api/push/...
```

Backup operations:

```bash
# Install or refresh restic service/timer files
ansible-playbook playbooks/backup.yml -e backup_operation=setup

# Run a manual backup
ansible-playbook playbooks/backup.yml -e backup_operation=backup

# List snapshots
ansible-playbook playbooks/backup.yml -e backup_operation=list
```

The periodic units are `backup-openclaw.timer` and `backup-openclaw.service`.

## Finish onboarding

Run OpenClaw onboarding interactively on the VM:

```bash
ssh ansible@openclaw.cosmos.cboxlab.com
sudo -i -u openclaw
~/.npm-global/bin/openclaw onboard
```

## Service management

OpenClaw is managed by its own CLI/tooling. These playbooks print guidance only:

```bash
ansible-playbook playbooks/start.yml
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/restart.yml
```

## Update OpenClaw

```bash
ansible-playbook playbooks/update.yml
```

## Configuration

See `inventory/group_vars/openclaw_servers.yml` for tunables like:

- OpenClaw user and group
- OpenClaw installer URL and arguments
- OpenClaw dashboard domain and upstream URL
- Git user name/email for the `openclaw` user
