# OpenClaw Ansible Setup

This Ansible project installs and manages OpenClaw on the `openclaw` VM.

## Prerequisites

- Ansible installed locally
- SSH access to `openclaw.cosmos.cboxlab.com`
- SSH key configured for the `ansible` user

## Installation

### 1. Verify connectivity

```bash
ansible all -m ping
```

### 2. Run setup

```bash
ansible-playbook playbooks/setup.yml
```

## Manual onboarding (required)

OpenClaw onboarding is manual by design:

```bash
ssh ansible@openclaw.cosmos.cboxlab.com
sudo -i -u openclaw
openclaw onboard --install-daemon
```

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
sudo systemctl status openclaw
sudo journalctl -u openclaw -f
```

## Configuration

See `inventory/group_vars/openclaw_servers.yml` for tunables like:
- OpenClaw user and service name
- Node.js version
- OpenClaw npm package/version
