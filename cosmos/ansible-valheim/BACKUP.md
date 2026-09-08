# Valheim Backups

Valheim world data is backed up to a host-specific S3-compatible repository by
restic. The systemd timer runs hourly by default.

## Host configuration

Keep the repository URL and retention policy in the host's `vars.yml`:

```yaml
backup_enabled: true
backup_schedule: "hourly"
backup_retention:
  keep_last: 10
  keep_daily: 10
  keep_monthly: 12
backup_paths:
  - "{{ valheim_data_dir }}/worlds_local"
restic_repository: "s3:https://minio.cosmos.cboxlab.com/example-bucket"
```

Keep `restic_password`, `restic_s3_access_key`, `restic_s3_secret_key`, and
`uptime_url` only in the host's encrypted `vault.yml`. The rendered environment
file is mode `0600`, and secret-bearing template tasks suppress logs and diffs.

## Host-limited operations

```bash
ansible-playbook playbooks/backup.yml --limit valheim-nordlys -e backup_operation=setup
ansible-playbook playbooks/backup.yml --limit valheim-nordlys -e backup_operation=backup
ansible-playbook playbooks/backup.yml --limit valheim-nordlys -e backup_operation=list
ansible-playbook playbooks/backup.yml --limit valheim-nordlys -e backup_operation=restore-test
```

`restore-test` prompts for a snapshot and restores it to an isolated
`/tmp/valheim-restore-*` directory. It verifies that `worlds_local` exists but
never stops the server or copies files over live data. Inspect the restored
world files and ownership, record the drill result, and remove the temporary
copy afterward.

## Direct checks

```bash
sudo systemctl status backup-valheim.timer
sudo journalctl -u backup-valheim.service -n 100
sudo -u valheim bash -c 'source /etc/restic-env && restic snapshots'
```
