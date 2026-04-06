# Hermes Ansible Setup

This Ansible project installs and manages Hermes agent on the target VM, along with Docker and Open WebUI.

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

## Manual onboarding

Install Hermes, start Open WebUI, and configure:

```bash
ssh ansible@hermes.cosmos.cboxlab.com
sudo -i -u hermes
cd ~/open-webui && docker compose up -d
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
hermes model          # Choose your LLM provider and model

# Set the following env vars in ~/.hermes/env
API_SERVER_ENABLED true
API_SERVER_KEY your-api-key

# Run
hermes doctor
systemctl --user daemon-reload
systemctl --user enable --now hermes
```

## Open WebUI

Open WebUI runs via Docker and is served via Nginx with SSL.

- Open WebUI: https://hermes.cosmos.cboxlab.com
- Open WebUI (local): http://localhost:3000
- Hermes API: https://hermes.cosmos.cboxlab.com/api/v1

## Service management

```bash
# Start Open WebUI
cd ~/open-webui && docker compose up -d

# Hermes service
ansible-playbook playbooks/start.yml
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/restart.yml
```

## Logs and status

```bash
ssh ansible@hermes.cosmos.cboxlab.com
sudo -i -u hermes
systemctl --user status hermes
journalctl --user -u hermes -f
docker logs -f open-webui
hermes version
```

## Configuration

See `inventory/group_vars/hermes_servers.yml` for tunables like:
- Hermes user and service name
- API key for Hermes agent and Open WebUI
- Nginx hostname
