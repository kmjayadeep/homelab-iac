# Kite VM Ansible Setup

This Ansible project prepares the `kite` VM for manual software installation. It installs general-purpose base packages, creates the `kite` user, installs its SSH key, configures its Git identity, and configures Nginx to proxy `kite.cosmos.cboxlab.com` to `127.0.0.1:3000`.

It does not install OpenClaw or any other application, TLS certificate, backup job, or application service.

## Prerequisites

- Ansible installed locally
- SSH access to `kite.cosmos.cboxlab.com`
- SSH key configured for the VM's `ansible` user

## Setup

From this directory:

```bash
ansible-galaxy collection install -r requirements.yml
ansible all -m ping
ansible-playbook playbooks/setup.yml
```

Set `KITE_EMAIL` before running setup to configure a non-default Git email for the `kite` user. If it is unset, `kite@localhost` is used.

After setup, connect as the dedicated user and install the required software manually. The application must listen on `127.0.0.1:3000`:

```bash
ssh kite@kite.cosmos.cboxlab.com
```

## Configuration

See `inventory/group_vars/kite_servers.yml` to customize:

- Base packages
- Kite user and group
- Authorized SSH keys
- Git user name and email
- Nginx domain and local upstream address
