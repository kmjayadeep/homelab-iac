# Valheim Server Quick Start

All mutating playbooks require an explicit limit that resolves to exactly one
host. Never run an operation against the entire `valheim_servers` group.

## Configure a host

Non-secret settings belong in `inventory/host_vars/<hostname>/vars.yml`.
Secrets belong in its encrypted `vault.yml`:

```yaml
vault_valheim_server_password: "..."
restic_password: "..."
restic_s3_access_key: "..."
restic_s3_secret_key: "..."
uptime_url: "..."
```

Create and edit the file without placing values in command arguments or shell
history, then encrypt it with Ansible Vault. Keep the vault password file local.

## Deploy one host

```bash
ansible-galaxy collection install -r requirements.yml
ansible-inventory --host valheim-nordlys
ansible-playbook --syntax-check playbooks/setup.yml
ansible valheim-nordlys -m ping
ansible-playbook playbooks/setup.yml --limit valheim-nordlys --check --diff
ansible-playbook playbooks/setup.yml --limit valheim-nordlys
```

The first successful start of `valheim-nordlys` creates a fresh, randomly seeded
`Nordlys` world. Do not copy a legacy world into its data directory. Nordlys
uses the Steam backend; connect to Tailscale first, then join
`valheim-nordlys-tailscale.cosmos.cboxlab.com:2456`.

The imported `speedrun` world runs on `valheim-speedrun`. Connect to Tailscale,
then join `speedrun.cboxlab.com:2456`. Substitute
`valheim-speedrun` for `valheim-nordlys` in the commands below to operate it.

## Operate one host

```bash
ansible-playbook playbooks/start.yml --limit valheim-nordlys
ansible-playbook playbooks/stop.yml --limit valheim-nordlys
ansible-playbook playbooks/restart.yml --limit valheim-nordlys
ansible-playbook playbooks/update.yml --limit valheim-nordlys
ansible-playbook playbooks/backup.yml --limit valheim-nordlys -e backup_operation=backup
ansible-playbook playbooks/backup.yml --limit valheim-nordlys -e backup_operation=list
ansible-playbook playbooks/backup.yml --limit valheim-nordlys -e backup_operation=restore-test
```

The restore drill writes under `/tmp/valheim-restore-*`; it never overwrites the
live world. Inspect the restored files and ownership before deleting the test
copy.

## Check health

```bash
ssh ansible@valheim-nordlys.cosmos.cboxlab.com
sudo systemctl status valheim
sudo journalctl -u valheim -n 100
sudo ss -lunp | grep 2456
sudo systemctl status backup-valheim.timer
sudo tailscale status
```

A healthy launch has an active service and process, a UDP listener, and a
`Game server connected` journal message from the current service activation.
