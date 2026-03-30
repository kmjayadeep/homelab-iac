# Paperclip Ansible Setup

This Ansible project installs and manages Paperclip on the target VM, and also installs the OpenAI Codex CLI so Paperclip can use the `codex_local` adapter.

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
codex --login
paperclipai onboard
systemctl --user daemon-reload
systemctl --user enable --now paperclip
```

Paperclip's current quickstart documents `npx paperclipai onboard --yes` as the recommended bootstrap path, and `paperclipai run` as the long-running process.
Codex can be authenticated interactively with OAuth from the CLI itself, so no manual `OPENAI_API_KEY` is required when using that flow.

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
- `paperclipai doctor --repair`
- service restart

## Logs and status

```bash
ssh ansible@paperclip.cosmos.cboxlab.com
sudo -i -u paperclip
systemctl --user status paperclip
journalctl --user -u paperclip -f
codex --help
```

## Configuration

See `inventory/group_vars/paperclip_servers.yml` for tunables like:
- Paperclip user and service name
- Node.js version
- Paperclip and Codex npm package versions
- Nginx hostname and upstream port
- Git user name and email for the Paperclip user
