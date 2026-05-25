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

OpenClaw gateway traffic is proxied from `https://openclaw.cosmos.cboxlab.com` to `http://127.0.0.1:18791`. The Nginx vhost follows the OpenClaw reverse-proxy guidance: loopback upstream, WebSocket upgrade handling with the `418` escape hatch, static asset caching, and security headers.

The OpenClaw installer command is:

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard --verify
```

Optional environment variable:

- `OPENCLAW_EMAIL` - git email for the `openclaw` user. Defaults to `openclaw@localhost`.
- `CLOUDFLARE_API_TOKEN` - Cloudflare API token used for the Let's Encrypt DNS challenge.
- `OPENCLAW_CERTBOT_EMAIL` - Let's Encrypt registration email. Defaults to `OPENCLAW_EMAIL`, then `admin@cboxlab.com`.

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
- OpenClaw gateway domain and upstream URL
- Git user name/email for the `openclaw` user
