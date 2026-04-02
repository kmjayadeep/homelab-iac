# Paperclip Ansible Setup

This Ansible project installs and manages Paperclip on the target VM, and also installs the OpenAI Codex CLI, `qmd`, Docker, `kubectl`, `kubectx`, `kustomize`, `kind`, `flutter`, `fzf`, `gh`, `jq`, `rg`, `uv`, `zsh`, and Hermes prerequisites so Paperclip can use the `codex_local` adapter and the `paperclip` user can manage local Kind clusters.

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
- `PAPERCLIP_EMAIL`

`OPENCLAW_EMAIL` is still accepted as a legacy fallback for certificate issuance.

## Manual onboarding

Paperclip should be onboarded interactively so you can choose the correct deployment mode and public URL:

```bash
ssh ansible@paperclip.cosmos.cboxlab.com
sudo -i -u paperclip
docker info
codex --login
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc  # or ~/.zshrc
hermes version
paperclipai onboard
systemctl --user daemon-reload
systemctl --user enable --now paperclip
```

Paperclip's current quickstart documents `npx paperclipai onboard --yes` as the recommended bootstrap path, and `paperclipai run` as the long-running process.
Codex can be authenticated interactively with OAuth from the CLI itself, so no manual `OPENAI_API_KEY` is required when using that flow.
Hermes Agent should be installed manually after setup with the official installer from `https://hermes-agent.nousresearch.com/docs/getting-started/installation/`, since its installer is interactive. Docker, `kubectl`, `kubectx`, `kustomize`, `kind`, `flutter`, `fzf`, `gh`, `jq`, `qmd`, `rg`, `uv`, `zsh`, and `ffmpeg` are installed during setup; the `paperclip` user is added to the `docker` group so it can create and manage local Kind clusters. If your current shell predates the group change, reconnect before running `kind create cluster`.

## UI via Nginx

The playbook installs Nginx and proxies the Paperclip UI to:

```bash
https://paperclip.cosmos.cboxlab.com
```

Default upstream port is `3100`, which matches the current Paperclip quickstart.

## Service management

```bash
ansible-playbook playbooks/start.yml
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/restart.yml
```

## Update Paperclip and Codex

```bash
ansible-playbook playbooks/update.yml
```

This runs:
- `npm install -g paperclipai@latest`
- `npm install -g @openai/codex@latest`
- `npm install -g @tobilu/qmd@2.0.1`
- `paperclipai doctor --repair`
- service restart

## Logs and status

```bash
ssh ansible@paperclip.cosmos.cboxlab.com
sudo -i -u paperclip
systemctl --user status paperclip
journalctl --user -u paperclip -f
docker ps
kubectl version --client
kubectx --help
kustomize version
kind version
flutter --version
fzf --version
gh --version
hermes version
jq --version
qmd --version
rg --version
uv --version
zsh --version
codex --help
```

## Configuration

See `inventory/group_vars/paperclip_servers.yml` for tunables like:
- Paperclip user and service name
- Pinned `kubectl`, `kind`, `kustomize`, and `flutter` versions
- Node.js version
- Paperclip, Codex, and qmd npm package versions
- Nginx hostname and upstream port
- Git user name and email for the Paperclip user
