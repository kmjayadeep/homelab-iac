# Hermes Ansible Setup

This Ansible project installs and manages Hermes agent on the target VM, along with Docker and other prerequisites.

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

`OPENCLAW_EMAIL` is still accepted as a legacy fallback for certificate issuance.

## Manual onboarding

Install Hermes and configure it:

```bash
ssh ansible@hermes.cosmos.cboxlab.com
sudo -i -u hermes
docker info
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
hermes model          # Choose your LLM provider and model
hermes config set OPENROUTER_API_KEY your-key
hermes doctor
systemctl --user daemon-reload
systemctl --user enable --now hermes
```

## UI via Nginx

The playbook installs Nginx and proxies the Hermes UI to:

```bash
https://hermes.cosmos.cboxlab.com
```

Default upstream port is `3100`.

## Service management

```bash
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
docker ps
hermes version
```

## Configuration

See `inventory/group_vars/hermes_servers.yml` for tunables like:
- Hermes user and service name
- Nginx hostname and upstream port
