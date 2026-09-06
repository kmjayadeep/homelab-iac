# Valheim Server Ansible Setup

This project manages native SteamCMD Valheim dedicated servers as systemd
services. Configuration is host-specific, secrets are encrypted with Ansible
Vault, and every mutating playbook requires `--limit <hostname>` resolving to
one host.

See [QUICKSTART.md](QUICKSTART.md) for deployment and routine operations and
[BACKUP.md](BACKUP.md) for backup and restore drills.

## Managed hosts

| Host | Purpose | Gameplay |
| --- | --- | --- |
| `valheim-rivers` | Legacy world | Existing host settings |
| `chillyfries` | Legacy world | Existing host settings |
| `valheim-skadi` | Fresh Valheim 1.0 world | Vanilla defaults, crossplay |

## Configuration

Shared paths and package settings are in
`inventory/group_vars/valheim_servers.yml`. Names, networking, gameplay,
access lists, and backup repositories belong in
`inventory/host_vars/<hostname>/vars.yml`. Credentials belong only in the
host's encrypted `vault.yml`.

Relevant host variables include:

- `valheim_server_name`, `valheim_world_name`, and `valheim_server_port`
- `valheim_public`, `valheim_crossplay`, and `valheim_instance_id`
- `valheim_preset` and `valheim_modifiers`
- `valheim_mods_enabled` (disabled unless explicitly enabled per host)
- `valheim_admin_ids`
- `valheim_permitted_list_enabled` and `valheim_permitted_ids`

Platform IDs use the case-sensitive `[Platform]_[User ID]` form. Enabling a
permitted list denies access to everyone not listed.

`valheim-skadi` intentionally sets no preset or modifiers and enables no mods,
so Valheim's vanilla defaults apply.

## Release and rollback procedure

1. Keep both legacy hosts stopped or unchanged; never deploy this work to them.
2. Confirm Steam App ID `896660` is the expected 1.0 build and record its build
   or manifest ID.
3. Provision and deploy only `valheim-skadi` using the commands in the
   quickstart.
4. Confirm `Game server connected`, perform Steam and external/crossplay joins,
   and verify a clean restart and world persistence.
5. Run an on-demand backup and an isolated `restore-test`, then confirm the
   hourly timer.
6. Keep the legacy hosts as rollback targets until Skadi has run for 48 hours
   and completed at least two scheduled backups.

If an update fails, the update playbook always attempts to restart the service,
prints SteamCMD and journal diagnostics, and then fails. If 1.0 cannot launch,
stop and disable only `valheim-skadi`; preserve its logs and data rather than
downgrading or overwriting a legacy world.
