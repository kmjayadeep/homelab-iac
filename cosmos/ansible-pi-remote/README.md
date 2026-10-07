# Pi Remote VM

Base Debian 13 workspace on Jupiter: 2 vCPUs, 2048 MiB RAM, 100 GiB disk.
DNS: `pi-remote.cosmos.cboxlab.com`. DHCP and QEMU guest agent supply the address.
VM/EFI storage: `local-lvm`; snippets and Debian import: shared `nfs-templates`.
Pi 1.0.4 is installed globally from `@earendil-works/pi-coding-agent` with
`--ignore-scripts`, using Node.js 24 from NodeSource. No backup bucket,
Nginx, or TLS is configured. Pi runs interactively over SSH.

## Provision

From `cosmos/proxmox`, with the existing provider credentials loaded:

```bash
terraform plan
terraform apply
```

Review the full plan: retiring `openclaw-chinnu`, `chillyfries`, and `jd-vm`
deletes their VM disks, cloud-init snippets, and managed DNS records. Their
existing MinIO backup buckets/users remain in `archived-s3.tf`.
Check backups before applying; PBS was unreachable during storage verification.

## Configure

Requires Ansible, SSH access as `ansible`, a matching public key at
`~/.ssh/id_rsa.pub`, and working DNS after Terraform apply. Verify the host's
SSH fingerprint and accept it before running the playbook.

From `cosmos/ansible-pi-remote`:

```bash
ansible-galaxy collection install -r requirements.yml
ansible all -m ping
ansible-playbook --syntax-check playbooks/setup.yml
ansible-playbook playbooks/setup.yml
ssh pi-remote@pi-remote.cosmos.cboxlab.com
```

Optional controller environment variables: `PI_REMOTE_GIT_USER_NAME` and
`PI_REMOTE_EMAIL` set Git identity. Override the user, group, authorized keys,
identity, and base packages in `inventory/group_vars/pi_remote_servers.yml`.
The controller must also have `~/.pi/agent/models.json` containing the LiteLLM
`qwen-intel` model. The dedicated LiteLLM key is read from `pass litellm/pi-remote`.
The controller needs access to that password-store entry. Override `pi_remote_models_source_file`,
`pi_remote_model_provider`, or `pi_remote_model_id` if needed.
Override the SSH key path in `inventory/hosts.yml` if needed.
The Node.js repository series and Pi package/version are configurable with
`pi_remote_nodejs_version`, `pi_remote_npm_package`, and `pi_remote_npm_version`.
Pi requires Node.js >=22.19. See https://pi.dev/ for documentation.

## Use Pi

```bash
ssh pi-remote@pi-remote.cosmos.cboxlab.com
pi --version
pi
```

Pi defaults to `litellm/qwen-intel` at `https://litellm.cosmos.cboxlab.com/v1`.
Ansible mirrors that model's metadata, sampling parameters, and compatibility
settings from the controller's Pi config, without copying unrelated models.
The API key is deployed separately to `~/.pi/agent/litellm-api-key` (mode `0600`)
and resolved by a credential command in `models.json`. Credential tasks disable
logging and diffs; no key is stored in this repository. Rerunning Ansible rotates
the remote key to match `pass litellm/pi-remote`. Configuration directories use `0700`.
To rotate only the credential, run
`ansible-playbook playbooks/setup.yml --tags pi_remote_credential`.

Existing unrelated settings are preserved while setting the default model.
Use `/model` to switch models, or `/login` for other providers.
A no-tools Qwen smoke test returned `QWEN_OK`.

## Remote Pi

Remote Pi 0.7.0 is installed as `npm:remote-pi@0.7.0`. Ansible manages its
`remote-pi-supervisord.service` user unit and enables lingering so the supervisor
survives logout and starts after reboot. No agent daemon is registered yet.
The `remote-pi` CLI is linked into `~/.local/bin`.

To install/update only Remote Pi without reapplying model configuration:

```bash
ansible-playbook playbooks/setup.yml --tags remote_pi
```

Pair interactively from the folder you want the agent to work in:

```bash
ssh pi-remote@pi-remote.cosmos.cboxlab.com
pi
# Inside Pi: /remote-pi — choose a relay, then scan the QR with the mobile app.
```

The public relay operator can potentially inspect traffic; prefer a self-hosted
relay for sensitive work. Ansible does not select a relay, pair devices, or
print/store pairing secrets. After pairing a project, optionally run:

```bash
remote-pi create /path/to/project --name "Pi Remote"
remote-pi daemon start
remote-pi daemons
systemctl --user status remote-pi-supervisord.service
```

Daemons execute tools without interactive approval; choose their project scope
carefully. The plugin currently emits a host-dependency manifest warning on Pi
1.0.4; the extension-loaded smoke test passed (`REMOTE_PI_OK`). The Remote Pi
Ansible rerun reported zero changes.
Docs: https://remote-pi.jacobmoura.work/remote-pi

## Deployment status

VM 109 was created on Jupiter at `192.168.1.148`; DNS and Ansible deployment
completed. The retired VMs and their managed DNS/snippets were deleted; backup
buckets/users were retained. A full Terraform plan was blocked by unreachable
Pluto, so apply used a reviewed, refreshing plan targeted to these VM changes.
A subsequent targeted apply retired `windrose`, `kite`, `agent0`,
`valheim-speedrun`, and `valheim-rivers` (15 resources deleted). Their S3 buckets,
users, policies, and credential outputs were retained unchanged. The post-apply
targeted plan reported no changes. Qwen passed a live smoke test using the
dedicated `pass litellm/pi-remote` token, and the Remote Pi supervisor is active.
Run a full `terraform plan` once Pluto is reachable to check unrelated drift.
