# Valheim 1.0 Server Plan

## Goal

Provision a new, isolated Valheim server for the 1.0/Deep North release without
upgrading or modifying the existing `valheim-rivers` and `chillyfries` worlds.
Launch with a fresh world, no mods, tested backups, and a documented rollback
path.

Valheim 1.0 is scheduled for 9 September. Iron Gate recommends starting a new
world for the best experience, although old saves remain usable. There will be
no public test branch for 1.0, so final server validation cannot happen until
the release build is available.

Official references:

- <https://valheim.com/support/valheim-1-0-faq/>
- <https://valheim.com/support/a-guide-to-dedicated-servers/>

## Recommended baseline

| Setting | Recommendation |
| --- | --- |
| Hostname | `deep-north` (confirm before implementation) |
| DNS | `deep-north.cosmos.cboxlab.com` |
| Proxmox node | `jupiter`, subject to live capacity and datastore checks |
| OS | Debian 13 cloud image, matching current Ansible-managed Valheim hosts |
| CPU | 4 host CPU cores |
| Memory | 8192 MiB |
| Disk | 100 GiB on a verified VM datastore |
| World | New world and seed; do not copy an existing world |
| Players | Up to 10, matching the supported Valheim limit |
| Mods | Disabled for launch; reassess after 1.0-compatible releases exist |
| Backups | Hourly restic backup to a dedicated MinIO bucket |
| Existing servers | Leave stopped/unchanged as recovery and comparison targets |

## Decisions required before implementation

- [ ] Confirm the hostname and visible server name.
- [ ] Confirm `jupiter` or select another Proxmox node.
- [ ] Choose a world name and either a specific seed or a randomly generated
      seed.
- [ ] Confirm gameplay preset/modifiers. Starting with normal/default settings
      is safest for achievements and a first 1.0 playthrough.
- [ ] Choose Steam-only or crossplay networking:
  - **Crossplay (recommended for mixed platforms):** add `-crossplay` and a
    unique `-instanceid`; the PlayFab relay avoids router port forwarding.
  - **Steam backend:** allocate a unique UDP port pair and configure matching
    router/NAT rules. Cloudflare DNS alone does not proxy Valheim UDP traffic.
- [ ] Confirm whether the server should appear in the public server browser.
- [ ] Confirm the administrator/permitted player Platform User IDs.
- [ ] Confirm the planned go-live time and who will perform the client join
      test.

## Safety constraints

- Do not apply Terraform or deploy Ansible until explicitly approved.
- Do not update either existing Valheim host as part of this work.
- Do not reuse or copy an existing world into the new server.
- Do not commit a plaintext server password, restic password, MinIO access key,
  or secret key. Store host-specific values in an Ansible Vault file and enter
  them through a non-logging editor/stdin workflow.
- Rotate the currently shared plaintext Valheim password before launch and
  remove it from shared group variables; give every host its own vaulted
  password.
- Always use `--limit <hostname>` for setup, update, start, stop, backup, and
  validation playbooks. The current playbooks target the entire
  `valheim_servers` group by default.
- Review a complete Terraform plan before apply. Do not rely only on a targeted
  plan.

## Phase 1: Preflight and automation hardening

- [ ] Verify live Proxmox capacity and storage on the selected node with
      `pvesm status --enabled 1` and `pvesm config`.
- [ ] Confirm that the Debian 13 import image and `nfs-templates` snippets are
      accessible from that node.
- [ ] Reserve a DHCP lease/static address and confirm there is no hostname,
      DNS, VM ID, IP, port, Terraform label, bucket, or inventory collision.
- [ ] Inspect the upstream dedicated-server build on release day and record its
      Steam build/manifest ID before deployment.
- [ ] Make these targeted improvements to `cosmos/ansible-valheim` before using
      it for the new host:
  - move `valheim_server_password` from shared group variables to per-host
    encrypted vault files;
  - parameterize `valheim_public`, `valheim_crossplay`, and a unique
    `valheim_instance_id` in the startup template;
  - ensure modifier values conform to the current dedicated-server syntax;
  - replace the current TCP `wait_for` check (Valheim uses UDP) with service,
    process/log, and socket checks;
  - remove ignored health-check failures so a failed launch fails deployment;
  - make the update workflow restart safely on failure and preserve useful
    diagnostics;
  - keep mods disabled unless explicitly enabled per host.
- [ ] Add a documented host-limited command path to the README/quickstart so a
      routine operation cannot restart every Valheim server.

## Phase 2: Infrastructure definition

- [ ] Add `cosmos/proxmox/deep-north.tf` (renamed if another hostname is
      selected), following current `bpg/proxmox` conventions.
- [ ] Define a VM with Q35/OVMF, host CPU, QEMU guest agent, DHCP networking,
      and the confirmed CPU, memory, disk, node, and datastores.
- [ ] Add cloud-init for the `ansible` and `valheim` users using existing SSH
      key variables. Do not add resolved credentials.
- [ ] Add an unproxied Cloudflare A record if DNS is required.
- [ ] Add a dedicated MinIO bucket/user through the existing module, using the
      correctly spelled name `deep-north-valheim-backup`.
- [ ] Add only sensitive credential outputs for the backup account and a
      non-sensitive VM IP output.
- [ ] Add lifecycle protection where supported so accidental Terraform changes
      cannot destroy the VM or backup bucket without an explicit review.
- [ ] Run:

  ```bash
  terraform -chdir=cosmos/proxmox fmt deep-north.tf outputs.tf
  terraform -chdir=cosmos/proxmox validate
  terraform -chdir=cosmos/proxmox plan
  ```

- [ ] Review the full plan for unrelated changes, replacement actions, secret
      output, correct provider alias, and correct datastores before apply.

## Phase 3: Host-specific Ansible configuration

- [ ] Add the host to `cosmos/ansible-valheim/inventory/hosts.yml`.
- [ ] Add `inventory/host_vars/deep-north/vars.yml` containing only non-secret
      settings: server/world names, port, public/crossplay flags, instance ID,
      modifiers, backup paths, and retention.
- [ ] Add `inventory/host_vars/deep-north/vault.yml` encrypted with Ansible
      Vault for the server password, restic password, MinIO credentials, and
      uptime endpoint.
- [ ] Keep the vault password file local and ignored.
- [ ] Configure `adminlist.txt` and, if requested, `permittedlist.txt`
      idempotently from per-host variables. Note that enabling a permitted list
      denies everyone not listed.
- [ ] Validate without contacting or changing existing hosts:

  ```bash
  cd cosmos/ansible-valheim
  ansible-inventory --host deep-north
  ansible-playbook --syntax-check playbooks/setup.yml
  ansible deep-north -m ping
  ansible-playbook playbooks/setup.yml --limit deep-north --check --diff
  ```

  Ensure secret-bearing tasks use `no_log: true` or `diff: false` before the
  check-mode run.

## Phase 4: Provision and pre-release soak

- [ ] Apply the reviewed Terraform plan in a maintenance window.
- [ ] Confirm cloud-init completion, guest-agent reporting, DNS resolution, SSH,
      clock synchronization, and disk capacity.
- [ ] Transfer MinIO credentials directly into the encrypted host vault without
      printing them to terminal output or storing them in command arguments.
- [ ] Deploy only the new host:

  ```bash
  cd cosmos/ansible-valheim
  ansible-playbook playbooks/setup.yml --limit deep-north
  ```

- [ ] Before 1.0 is released, use the current stable server only to test the
      VM, systemd unit, networking, access controls, clean shutdown, and backup
      pipeline. Do not create the final world yet, or remove the pre-release
      test world before launch.
- [ ] Trigger an on-demand restic backup and perform a restore drill into a
      temporary directory. Verify world files and ownership without replacing
      the live data.

## Phase 5: 1.0 release-day validation and launch

Because there is no public test branch, treat release day as a controlled
upgrade gate rather than enabling unattended changes.

- [ ] Confirm that Steam App ID `896660` serves the expected 1.0 dedicated
      server build and that client/server versions match.
- [ ] Stop the service cleanly and take a final infrastructure snapshot/backup
      of the pre-release test state.
- [ ] Run the host-limited update playbook, then verify that systemd reports the
      service active and logs contain `Game server connected` without crash
      loops or protocol errors.
- [ ] Create the final fresh world with the approved world name/seed and
      modifiers.
- [ ] Complete two client tests:
  1. local/LAN or Steam client join, gameplay, logout, and reconnect;
  2. external and/or console join through the selected Steam/crossplay path.
- [ ] Verify admin access, allowlist behavior if enabled, world save, clean
      restart, and persistence after reboot.
- [ ] Trigger and verify the first production restic snapshot, then confirm the
      hourly timer and retention policy.
- [ ] Publish the join method, server name, password through a private channel,
      and the planned availability window. Do not publish credentials in Git.

## Rollback and failure handling

- Keep `valheim-rivers` and `chillyfries` unchanged until the new server has
  completed at least 48 hours of stable operation and two successful scheduled
  backups.
- If the 1.0 binary fails to launch, stop and disable only the new service,
  preserve logs and world data, and leave the VM available for diagnosis.
- If world creation or saving is faulty, restore the most recent verified
  restic snapshot into a separate path first; never restore over live data
  without a second backup.
- If Steam-backend networking fails, validate the UDP port pair and NAT rules.
  If crossplay fails, validate `-crossplay`, the unique instance ID, and the
  `Game server connected` log before changing firewall rules.
- Do not downgrade or overwrite an existing production world. The unchanged
  legacy servers are the fallback service while 1.0 issues are resolved.

## Completion criteria

- [ ] New VM is independently managed and no existing Valheim resource changed.
- [ ] Fresh 1.0 world starts after reboot and accepts the intended clients.
- [ ] Passwords and backup credentials exist only in encrypted/local stores.
- [ ] Server health checks detect real failures.
- [ ] Admin/allowlist and public visibility match the approved settings.
- [ ] Hourly backups succeed and a restore drill has passed.
- [ ] Existing servers remain available as rollback targets through the soak
      period.
- [ ] Terraform, Ansible, networking, operations, and recovery commands are
      documented with host-limited examples.
