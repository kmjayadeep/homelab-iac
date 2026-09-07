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

Optional environment variables:

- `OPENCLAW_EMAIL` - git email for the `openclaw` user. Defaults to `openclaw@localhost`.
- `OPENCLAW_CERTBOT_EMAIL` - Let's Encrypt registration email. Defaults to `OPENCLAW_EMAIL`, then `admin@cboxlab.com`.

## Vault-backed Certbot credentials

Vault Agent authenticates each VM with its own AppRole and renders the shared
canonical Cloudflare credential from
`homelab/kv/services/cloudflare/dns-cboxlab` to
`/etc/letsencrypt/cloudflare.ini`. The agent refreshes the static KV secret every
five minutes. `certbot.service` requires `vault-agent.service` and waits for a
non-empty, root-owned credential file with mode `0600` before running.

The inventory-derived roles are `openclaw-certbot` and
`openclaw-chinnu-certbot`. Bootstrap one host at a time using an authenticated
Vault operator environment, then apply the Vault Agent role:

```bash
./bootstrap-vault-agent.sh openclaw
ansible-playbook playbooks/setup-vault-agent.yml --limit openclaw
```

Repeat with `openclaw-chinnu` for the second host. The bootstrap script generates
a distinct SecretID, keeps it only in process memory, and sends it through
Ansible tasks protected by `no_log: true` and `diff: false`. The RoleID and
SecretID are installed at `/etc/vault-agent/role-id` and
`/etc/vault-agent/secret-id`, respectively, as `root:root` with mode `0600`.
Never put a SecretID in Git, Terraform, Ansible variables, command arguments, or
operator password stores.

Runtime checks:

```bash
sudo systemctl status vault-agent.service certbot.timer --no-pager
sudo stat /etc/letsencrypt/cloudflare.ini
sudo certbot renew --dry-run --cert-name openclaw.cosmos.cboxlab.com
```

Vault Agent connects only to `https://vault.cosmos.cboxlab.com` with normal TLS
verification. Do not configure `tls_skip_verify` or the internal HTTP endpoint.

### Cloudflare token rotation

Rotate the shared production identity without creating another Vault path:

1. Create a replacement Cloudflare token with zone-read and DNS-edit access only
   for `cboxlab.com`, then validate its scope without revoking the current token.
2. Write only `api_token` to `services/cloudflare/dns-cboxlab` through the
   approved non-logging Vault stdin/file workflow.
3. Update the KV custom metadata required by `vault-config/PATHS.md`, including
   `last-rotated-at`, `expires-at`, and the current non-secret scope details.
4. Wait at least five minutes for Vault Agent and the other consumers to
   reconcile. Confirm each VM's render-status timestamp advances without reading
   `/etc/letsencrypt/cloudflare.ini`.
5. Validate external-dns, cert-manager certificate issuance, and a Certbot dry
   run on both OpenClaw hosts.
6. Revoke the old Cloudflare token only after every consumer passes validation.

### TLS monitoring

`openclaw-tls-monitor.timer` runs hourly and checks that Vault Agent is active,
its non-secret render-status file is no older than 15 minutes, the Certbot
credential has safe metadata, and the certificate remains valid for more than
21 days. It never reads or logs the credential content.

Failures of `vault-agent.service`, `certbot.service`, or the TLS monitor trigger
`openclaw-tls-alert@.service`, which records a critical, actionable journal
entry. Inspect failures with:

```bash
sudo journalctl -t openclaw-tls-alert --no-pager
sudo systemctl status vault-agent.service certbot.service openclaw-tls-monitor.service
```

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
