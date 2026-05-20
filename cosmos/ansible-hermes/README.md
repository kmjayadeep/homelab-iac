# Hermes Ansible Setup

This Ansible project installs and manages Hermes agent on the target VM, served through the built-in Hermes dashboard.

## Prerequisites

- Ansible installed locally
- SSH access to the target host
- SSH key configured for the `ansible` user

## Installation

### 1. Install Ansible collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### 2. Verify connectivity

```bash
ansible all -m ping
```

### 3. Run setup

```bash
ansible-playbook playbooks/setup.yml
```

Ensure the environment variables are set:
- `CLOUDFLARE_API_TOKEN`
- `HERMES_EMAIL`
- `HERMES_API_KEY` (optional, defaults to `hermes-secret-key`)

`OPENCLAW_EMAIL` is still accepted as a legacy fallback for certificate issuance.

## Manual onboarding (first-time only)

The setup playbook deploys and starts the dashboard systemd service automatically.
If this is a fresh VM with no hermes agent installed yet, run the onboarding steps:

```bash
ssh ansible@hermes.cosmos.cboxlab.com
sudo -i -u hermes
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
hermes model          # Choose your LLM provider and model

# Configure API access
hermes config set API_SERVER_ENABLED true
hermes config set API_SERVER_KEY your-api-key

# Verify and restart the dashboard
hermes doctor
systemctl --user restart hermes
```

## Hermes dashboard

The built-in Hermes dashboard is served via Nginx with SSL.

- Hermes dashboard: https://hermes.cosmos.cboxlab.com
- Hermes local service: http://localhost:8642
- Hermes API: https://hermes.cosmos.cboxlab.com/v1 (served by the dashboard)

## Service management

```bash
# Hermes service
ansible-playbook playbooks/start.yml
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/restart.yml
```

## Logs and status

```bash
# Check dashboard service
sudo -i -u hermes systemctl --user status hermes

# Follow dashboard logs
sudo -i -u hermes journalctl --user -u hermes -f

# Check dashboard health
curl -s http://localhost:8642/ | head -5

# Hermes CLI version
sudo -i -u hermes hermes version
```

## Configuration

See `inventory/group_vars/hermes_servers.yml` for tunables like:
- Hermes user and service name
- API key for Hermes agent
- Nginx hostname
