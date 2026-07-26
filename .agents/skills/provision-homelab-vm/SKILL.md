---
name: provision-homelab-vm
description: Provision a named Proxmox VM and its supporting Terraform resources, scaffold a dedicated Ansible project, and optionally configure an Nginx reverse proxy with Let's Encrypt DNS-challenge TLS. Use when adding a new homelab VM under cosmos/proxmox and cosmos/ansible-<name>. Defaults to the jupiter node, verifies node-specific datastores before editing, validates generated infrastructure code, and reports a final summary.
---

# Provision Homelab VM

Create a VM using the repository's current Terraform and Ansible conventions. Keep edits scoped to the requested host and never apply infrastructure unless the user explicitly asks.

## Inputs

Collect or infer these values before editing:

- `name` (required): VM hostname and project name.
- `node` (optional): Proxmox node; default `jupiter`.
- `domain` (optional): default `<name>.cosmos.cboxlab.com`.
- `cores` (optional): default `2`.
- `memory_mb` (optional): default `2048`.
- `disk_gb` (optional): default `100`.
- `dns_record` (optional): default `true`.
- `backup_bucket` (optional): whether to create `<name>-backup` and a MinIO user. Infer from the request; ask if ambiguous rather than silently creating credentials.
- `reverse_proxy` (optional): default `false`. When requested, collect `upstream_host` (default `127.0.0.1`) and `upstream_port` (required if not clear).
- `tls` (optional): default to `true` when a reverse proxy with SSL/TLS is requested; otherwise `false`.
- `ssh_private_key_file` (optional): default `~/.ssh/id_rsa`.

Ask only for missing values that cannot safely be inferred. Confirm unusual node, storage, networking, image, or resource requirements.

Normalize identifiers consistently:

- Keep the hostname/file stem in lowercase kebab-case.
- Use snake_case for Terraform labels, variables, modules, and outputs.
- Use lowercase snake_case for Ansible variables and group names.
- Use a human-readable title-cased name only in descriptions and task names.

## 1. Inspect Before Editing

1. Read repository instructions and check for deeper `AGENTS.md` files.
2. Inspect `git status`; preserve unrelated work.
3. Inspect the closest current examples, especially:
   - `cosmos/proxmox/kite.tf`
   - another VM on the selected node
   - `cosmos/proxmox/providers.tf`
   - `cosmos/proxmox/debian.tf`
   - `cosmos/proxmox/outputs.tf`
   - `cosmos/ansible-kite/`
4. Search for the requested hostname, DNS name, Terraform label, Ansible directory, bucket name, and outputs. Stop and report conflicts rather than duplicating resources.
5. Check that the selected node has a matching `proxmox-bpg` provider alias. Do not invent a provider configuration.

## 2. Verify Datastores for the Selected Node

Never select storage from the node name alone. Verify storage on every run before generating Terraform.

Use both repository evidence and, when available, live Proxmox evidence:

```bash
rg -n 'node_name|datastore_id|target_node|storage\s*=' cosmos/proxmox/*.tf
ssh root@<node>.cosmos.cboxlab.com 'pvesm status --enabled 1 && printf "\n--- config ---\n" && pvesm config'
```

Verify separately that:

- the VM disk and EFI datastore exists, is active, is available on the selected node, and supports VM images;
- the cloud-init snippet datastore exists, is available on the selected node, and supports snippets;
- the Debian import source is accessible from the selected node.

Current repository patterns are hints, not substitutes for verification:

- `jupiter`: VM disk/EFI commonly use `local-lvm`; snippets/imports use shared `nfs-templates`.
- `mars`: newer VM disk/EFI definitions commonly use `ssd-lvm`, while some resources use `local-lvm`; snippets/imports use `nfs-templates`.
- `pluto`: do not assume a VM datastore; live verification or explicit user confirmation is required.

If live access is unavailable, use multiple same-node Terraform examples and clearly ask the user to confirm the selected datastore when evidence is absent or inconsistent. Never guess, especially for `pluto`.

Record the verified VM datastore and snippet datastore for the final summary.

## 3. Create Terraform Resources

Create `cosmos/proxmox/<name>.tf`, following the nearest selected-node example rather than mechanically copying stale code.

Normally include:

1. `proxmox_virtual_environment_vm` using `proxmox-bpg.<node>-bpg`.
2. Selected `node_name`, verified disk/EFI datastore, `q35`, OVMF, host CPU, requested sizing, DHCP, bridged networking, and QEMU guest agent.
3. A `proxmox_virtual_environment_file` cloud-init snippet on the verified snippet datastore.
4. Cloud-init users consistent with current repository conventions, including the automation user and SSH key.
5. A `cloudflare_dns_record` when `dns_record` is enabled. Use the VM-reported address in the same manner as validated same-node examples; do not fabricate a fallback address.
6. A `minio_s3_bucket` module only when `backup_bucket` is requested.
7. Sensitive access-key and secret-key outputs in `cosmos/proxmox/outputs.tf` only when the bucket/user is created.

Use the existing Debian 13 image resource only after confirming it is accessible to the selected node. Do not modify or commit Terraform state as part of scaffolding. Do not run `terraform apply` unless explicitly requested.

## 4. Create the Basic Ansible Project

Create `cosmos/ansible-<name>/` with:

```text
ansible.cfg
README.md
requirements.yml
inventory/hosts.yml
inventory/group_vars/<name>_servers.yml
playbooks/setup.yml
roles/<name>/tasks/main.yml
```

Add `roles/<name>/handlers/main.yml` and templates only when needed.

The basic role should:

- install a concise configurable base package list;
- create a dedicated group and user with a home directory and Bash shell;
- install the requested authorized key using `ansible.posix.authorized_key`;
- configure Git user name and email from variables/environment;
- remain idempotent and avoid application-specific software;
- print useful next steps without claiming services that were not configured.

Use `ansible` as the inventory connection user unless the user requests otherwise. Set the inventory host to the requested domain when DNS is enabled, otherwise ask for or use an explicitly supplied IP/hostname.

Document prerequisites, setup commands, environment variables, connection instructions, and configurable values in the README.

## 5. Optional Nginx and TLS

When `reverse_proxy` is enabled:

- add `nginx` to base packages;
- configure and enable a named site proxying to the requested local upstream;
- remove the default site;
- add handlers that run `nginx -t` before reloading;
- enable and start Nginx;
- include standard forwarding and WebSocket headers.

When `tls` is enabled:

- require DNS to resolve to the VM, creating the Terraform DNS record if requested;
- install `certbot` and `python3-certbot-dns-cloudflare`;
- read `CLOUDFLARE_API_TOKEN` on the controller and assert it is non-empty;
- obtain a certificate with the Cloudflare DNS challenge;
- store `/etc/letsencrypt/cloudflare.ini` as root with mode `0600`;
- set `diff: false` on the credential template task so `ansible-playbook --diff` cannot disclose the token;
- install a deploy hook to test Nginx configuration and reload it after renewal;
- enable the Certbot renewal timer;
- redirect HTTP to the configured domain, not user-controlled `$host`, for example:

```nginx
return 301 https://{{ vm_domain }}$request_uri;
```

- terminate TLS on Nginx and proxy to the configured HTTP upstream.

Use a host-specific certificate email environment variable such as `<NAME>_CERTBOT_EMAIL`, falling back to `<NAME>_EMAIL`, then the repository's established administrative default. Never commit token values. If creating `.envrc`, include only commands/environment lookups following existing repository conventions, never resolved secrets.

If Nginx is requested without TLS, generate only the port 80 proxy and do not add Certbot or Cloudflare credential tasks.

## 6. Validate

Run targeted, non-destructive checks:

```bash
terraform -chdir=cosmos/proxmox fmt <name>.tf outputs.tf
terraform -chdir=cosmos/proxmox validate
cd cosmos/ansible-<name> && ansible-playbook --syntax-check playbooks/setup.yml
cd <repo-root> && git diff --check
git status --short
git diff --stat
git diff -- cosmos/proxmox/<name>.tf cosmos/proxmox/outputs.tf cosmos/ansible-<name>
```

Only format `outputs.tf` when it was changed. If a required tool or initialized provider is unavailable, report the skipped check and why. Do not hide validation failures and do not apply Terraform or execute the playbook unless asked.

Review generated files for:

- correct provider alias and node name;
- verified datastores in every disk, EFI, import, and snippet field;
- no duplicate DNS, bucket, output, or resource names;
- no plaintext secrets or unexpected state changes;
- valid YAML/Jinja indentation and idempotent Ansible modules;
- Nginx configuration matching the requested domain and upstream;
- TLS credentials protected from Ansible diff output;
- explicit-domain HTTP redirect when TLS is enabled.

## 7. Final Summary

Always finish with a concise report containing:

- `VM`: name, node, CPU, memory, disk, image.
- `Storage verification`: evidence used, VM datastore, snippet datastore, and import accessibility.
- `Terraform`: files/resources created or updated, including DNS and optional bucket/outputs.
- `Ansible`: project path and base configuration created.
- `Nginx/TLS`: enabled or disabled; domain and upstream when enabled.
- `Validation`: each command and pass/fail/skipped status.
- `Not executed`: explicitly state that Terraform apply and Ansible deployment were not run, unless they were requested and completed.
- `Next steps`: the exact plan/apply and Ansible commands the user may run.
