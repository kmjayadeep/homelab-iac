# Pi Remote VM

Base Debian 13 workspace on Mars: 4 vCPUs, 6144 MiB RAM, 100 GiB disk.
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

## Development tools

Ansible installs mise from its apt repository and sets Flutter
`pi_remote_flutter_version` (3.47.7, bundled Dart 3.13.5) as the global default
for `pi-remote`. Projects can pin their own version in `.tool-versions`.
mise shims are on the login PATH and the Remote Pi supervisor PATH, so daemons
can run `flutter`/`dart`. Flutter/Dart telemetry is disabled.
Also installed: `gh`, `git-lfs`, `tmux`, `build-essential`, and Flutter's Linux prerequisites.
A 4 GiB `/swapfile` (`vm.swappiness=10`) backs the 6 GiB RAM during analyze/test.
No Android SDK/JDK is installed; APK builds stay in GitHub Actions.

Git uses an ed25519 key at `~/.ssh/id_ed25519`, generated on first run and printed
by the play; add it to GitHub before pushing. GitHub's host key is pinned in
`known_hosts`.

```bash
ansible-playbook playbooks/setup.yml --tags dev_tools
```

## Remote Pi

Remote Pi 0.7.0 is installed as `npm:remote-pi@0.7.0`. Ansible manages its
`remote-pi-supervisord.service` user unit and enables lingering so the supervisor
survives logout and starts after reboot. No daemon is registered
yet; pair and register one manually (not managed by Ansible).
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

On 2026-10-16 the VM moved from Jupiter (VM 109, 2 vCPU/2 GiB) to Mars as VM 101
at `192.168.1.151` with 4 vCPU/6 GiB; Jupiter was memory-saturated. Mars and
Jupiter are standalone nodes, so the move was a targeted destroy with the Jupiter
provider followed by a targeted create with the Mars provider. The old home
directory was not migrated. Ansible was rerun in full and converged with no changes.
A full Terraform plan is still blocked by unreachable Pluto; run one once it is
reachable to check unrelated drift.
