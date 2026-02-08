# OpenClaw Ansible Setup

This Ansible project installs and manages OpenClaw on the `openclaw` VM.

## Prerequisites

- Ansible installed locally
- SSH access to `openclaw.cosmos.cboxlab.com`
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

Ensure the environment variables are set (see `.envrc`):
- `CLOUDFLARE_API_TOKEN`
- `OPENCLAW_EMAIL`

## Manual onboarding (required)

OpenClaw onboarding is manual by design:

```bash
ssh ansible@openclaw.cosmos.cboxlab.com
sudo -i -u openclaw
openclaw onboard --install-daemon
```

## Dashboard via Nginx

The playbook installs Nginx and proxies the OpenClaw dashboard.

```bash
https://openclaw.cosmos.cboxlab.com
```

To access the dashboard, run `openclaw dashboard` on the VM to generate a token, then use that token when opening the URL above.

## Service management

```bash
ansible-playbook playbooks/start.yml
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/restart.yml
```

## Update OpenClaw

```bash
ansible-playbook playbooks/update.yml
```

This runs:
- `npm install -g openclaw@latest`
- `openclaw doctor`
- service restart

## Logs and status

```bash
ssh ansible@openclaw.cosmos.cboxlab.com
sudo -i -u openclaw
systemctl --user status openclaw-gateway
journalctl --user -u openclaw-gateway -f
```

## Configuration

See `inventory/group_vars/openclaw_servers.yml` for tunables like:
- OpenClaw user and service name
- Node.js version
- OpenClaw npm package/version
- Git user name/email for the openclaw user
