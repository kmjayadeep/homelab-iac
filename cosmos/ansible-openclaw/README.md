# NanoClaw VM Ansible Setup

This Ansible project prepares the fresh `openclaw` VM for the NanoClaw quickstart. It no longer installs OpenClaw, Node.js, Nginx, Certbot, or an OpenClaw systemd service.

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

### 3. Prepare the VM

```bash
ansible-playbook playbooks/setup.yml
```

The playbook installs basic packages, creates a `nanoclaw` user, adds your SSH key, configures git, and prints the manual NanoClaw quickstart commands.

Optional environment variable:

- `NANOCLAW_EMAIL` - git email for the `nanoclaw` user. Defaults to `nanoclaw@localhost`.

## Manual NanoClaw install

Run the upstream quickstart manually on the VM:

```bash
ssh ansible@openclaw.cosmos.cboxlab.com
sudo -i -u nanoclaw
git clone https://github.com/nanocoai/nanoclaw.git nanoclaw-v2
cd nanoclaw-v2
bash nanoclaw.sh
```

`nanoclaw.sh` handles NanoClaw setup and can install Node, pnpm, and Docker if missing.

## Service management

NanoClaw is managed by its own installer/tooling. The old OpenClaw user service playbooks have been replaced with guidance-only notices:

```bash
ansible-playbook playbooks/start.yml
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/restart.yml
```

## Update NanoClaw checkout

If the repo has already been cloned, this pulls the latest changes as the `nanoclaw` user:

```bash
ansible-playbook playbooks/update.yml
```

Run any NanoClaw installer or migration steps manually afterward.

## Configuration

See `inventory/group_vars/nanoclaw_servers.yml` for tunables like:

- NanoClaw user and group
- NanoClaw repo URL and checkout path
- Git user name/email for the `nanoclaw` user
