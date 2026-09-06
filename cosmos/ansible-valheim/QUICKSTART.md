# Valheim Server Quick Start

All mutating playbooks require an explicit limit that resolves to exactly one
host. Never run an operation against the entire `valheim_servers` group.

## Configure a host

Non-secret settings belong in `inventory/host_vars/<hostname>/vars.yml`.
Secrets belong in its encrypted `vault.yml`:

```yaml
valheim_server_password: "..."
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
ansible-inventory --host valheim-skadi
ansible-playbook --syntax-check playbooks/setup.yml
ansible valheim-skadi -m ping
ansible-playbook playbooks/setup.yml --limit valheim-skadi --check --diff
ansible-playbook playbooks/setup.yml --limit valheim-skadi
```

The first successful start of `valheim-skadi` creates a fresh, randomly seeded
`Skadi` world. Do not copy a legacy world into its data directory.

## Operate one host

```bash
ansible-playbook playbooks/start.yml --limit valheim-skadi
ansible-playbook playbooks/stop.yml --limit valheim-skadi
ansible-playbook playbooks/restart.yml --limit valheim-skadi
ansible-playbook playbooks/update.yml --limit valheim-skadi
ansible-playbook playbooks/backup.yml --limit valheim-skadi -e backup_operation=backup
ansible-playbook playbooks/backup.yml --limit valheim-skadi -e backup_operation=list
ansible-playbook playbooks/backup.yml --limit valheim-skadi -e backup_operation=restore-test
```

The restore drill writes under `/tmp/valheim-restore-*`; it never overwrites the
live world. Inspect the restored files and ownership before deleting the test
copy.

## Check health

```bash
ssh ansible@valheim-skadi.cosmos.cboxlab.com
sudo systemctl status valheim
sudo journalctl -u valheim -n 100
sudo ss -lunp | grep 2456
sudo systemctl status backup-valheim.timer
```

A healthy launch has an active service and process, a UDP listener, and a
`Game server connected` journal message.
