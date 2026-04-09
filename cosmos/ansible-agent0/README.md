# Agent0 Ansible Setup

This Ansible project installs and manages Agent0 on the `agent0` VM. It is based on the Paperclip setup and installs Paperclip (`paperclipai`), OpenAI Codex CLI, and pi-agent, plus Docker, `kubectl`, `kubectx`, `kustomize`, `kind`, `flutter`, `fzf`, `gh`, `jq`, `rg`, `uv`, and `zsh`.

Hermes and OpenCode are intentionally not installed in this project.

## Prerequisites

- Ansible installed locally
- SSH access to `agent0.cosmos.cboxlab.com`
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
- `AGENT0_EMAIL`

## Manual onboarding

Onboarding is interactive by design:

```bash
ssh ansible@agent0.cosmos.cboxlab.com
sudo -i -u agent0
docker info
codex --login
paperclipai onboard
systemctl --user daemon-reload
systemctl --user enable --now agent0
```

## UI via Nginx

The playbook installs Nginx and proxies the UI to:

```bash
https://agent0.cosmos.cboxlab.com
```

Default upstream port is `3100`.

## Service management

```bash
ansible-playbook playbooks/start.yml
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/restart.yml
```

## Update Agent0 and Codex

```bash
ansible-playbook playbooks/update.yml
```

This runs:
- `npm install -g paperclipai@latest`
- `npm install -g @openai/codex@latest`
- `paperclipai doctor --repair`
- service restart

## Logs and status

```bash
ssh ansible@agent0.cosmos.cboxlab.com
sudo -i -u agent0
systemctl --user status agent0
journalctl --user -u agent0 -f
docker ps
kubectl version --client
kubectx --help
kustomize version
kind version
flutter --version
fzf --version
gh --version
jq --version
rg --version
uv --version
zsh --version
codex --help
```

## Configuration

See `inventory/group_vars/agent0_servers.yml` for tunables like:
- Agent0 user and service name
- Pinned `kubectl`, `kind`, `kustomize`, and `flutter` versions
- Node.js version
- Agent0 and Codex npm package versions
- Nginx hostname and upstream port
- Git user name and email for the Agent0 user
