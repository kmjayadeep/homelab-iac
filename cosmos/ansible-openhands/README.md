# OpenHands Agent Canvas

**URL:** https://openhands.cosmos.cboxlab.com/canvas

This deploys the current Agent Canvas all-in-one distribution, not the deprecated
Local GUI. The pinned official image bundles Canvas, Agent Server, Automation
Server, and internal ingress: `ghcr.io/openhands/agent-canvas:1.26.0` at the digest
configured in `inventory/group_vars/openhands_servers.yml`.

## Access

1. HTTP Basic Auth username: `openhands`.
2. HTTP password: retrieve locally with `pass homelab/openhands/dashboard`.
3. When Canvas asks for the backend API key, retrieve it with
   `pass homelab/openhands/canvas-backend`.

Both backend services require `X-Session-API-Key`; Nginx requires Basic Auth as
an additional gate. The backend key is not embedded in frontend HTML. The site
root redirects to `/canvas`. Clear stale browser state if it still shows the
legacy frontend.

## Model and automations

- Active LLM profile: `qwen-intel`.
- Model: `litellm_proxy/qwen-intel`.
- API base: `https://litellm.cosmos.cboxlab.com/v1`.
- Dedicated model key: `pass litellm/openhands`, loaded through `.envrc`.
- Explicit max input: 114688 tokens; max output: 16384 tokens.
- LLM summarizing condenser: enabled, token threshold 100000; its default event
  threshold remains enabled as another trigger.

The role saves a named LLM profile and updates model/condenser settings through
Agent Server's API. Changes are partial, preserving unrelated settings; keys
are suppressed from Ansible logs/diffs and encrypted at rest by the backend.
The image generates and persists its settings encryption key in the data mount.

Use Canvas's **Automate** view for scheduled and event-driven jobs. Automation
Server is installed and its authenticated listing/health endpoints were verified.
No automation definition or GitHub write credential is provisioned by this role.
Configure repository access before enabling PR-writing automations, and use
bounded tasks, a dedicated repo-scoped credential, draft PRs, and no auto-merge.

## Infrastructure and isolation

- Proxmox node `mars`, VM ID `100`, DHCP address `192.168.1.150`.
- Debian 13, 4 vCPUs, 8192 MB RAM, 100 GB disk, bridge `vmbr0`.
- Disk/EFI: `ssd-lvm`; snippets/shared Debian import: `nfs-templates`.
- Terraform: `../proxmox/openhands.tf`; no Terraform change was needed for the
  Local GUI → Canvas migration.
- Service: `openhands.service`; container: `openhands-canvas`.
- Only `127.0.0.1:8000` is published; Nginx terminates TLS and proxies all routes,
  including `/api/automation`, `/api`, `/sockets`, `/canvas`, and `/vscode`.
  The site's access log omits query strings to avoid recording URL credentials.
- Data: `/var/lib/agent-canvas` → `/home/openhands/.openhands`.
- Projects: `/var/lib/agent-canvas-projects` → `/projects`.
- Data/projects use image UID/GID `10001:10001` and mode `0700`.
- Backend environment: `/etc/openhands/agent-canvas.env`, root-only `0600`.
  Both `LOCAL_BACKEND_API_KEY` and `OH_SESSION_API_KEYS_0` are set explicitly so
  the packaged agent-server actually enforces authentication.
- No Docker socket mount and no privileged mode. Agent tools operate inside the
  container and mounted directories; nested Docker workloads are not enabled.
- The existing Docker ingress protection service remains enabled; direct LAN
  ingress to Docker containers is blocked. Legacy dynamic sandbox/MCP Nginx
  exceptions have been removed.
- Certbot uses the Cloudflare DNS challenge and its renewal timer. Its root-only
  token file remains `/etc/letsencrypt/cloudflare.ini`; renewal validates Nginx
  before reload. Product telemetry is disabled in the container environment.

Agents can execute commands and access everything available inside this backend,
including its mounted data. This is a trusted single-user environment, not a
multi-tenant isolation boundary. Protect access and back up its secrets/data.

## Reconfigure

Prerequisites: Ansible, working SSH authentication, matching `.pub` file beside
the controller's private key, and password-store access.

```bash
cd cosmos/ansible-openhands
ansible-galaxy collection install -r requirements.yml
source .envrc
export SSH_PRIVATE_KEY_FILE="$HOME/private/ssh/id_rsa" # if not ~/.ssh/id_rsa
ansible-playbook --syntax-check playbooks/setup.yml
ansible-playbook playbooks/setup.yml
```

`.envrc` contains lookups only, never resolved credentials. Rotate the HTTP or
backend password in `pass`, reload `.envrc`, then rerun setup. Backend rotation
requires entering the new key in Canvas. For model-key rotation, additionally
use `-e openhands_llm_rotate_key=true`.

## Migration archive and rollback

The legacy conversations were interrupted at the user's request. Their sandbox
containers were paused, their workspaces copied, and the legacy application was
stopped before backing up its data. The sandbox containers were subsequently
stopped but not deleted. Their old workspaces/history are **not automatically
imported into Canvas**; GitHub integrations must be configured for the new backend.

Root-only archive on the VM:

`/var/backups/openhands/legacy-20261009T182904Z/`

It contains `application-data.tar.gz`, workspace copies, sandbox metadata, and
the old service/Nginx configurations. The original `/var/lib/openhands` is also
retained untouched. Do not commit or share archive contents: they include secrets.

For rollback, stop `openhands`, restore `openhands.service` and `openhands.conf`
from that archive to their original `/etc` locations, run `systemctl daemon-reload`
and `nginx -t`, reload Nginx, and start `openhands`. Resume old sandbox containers
only deliberately; they may contain unfinished agent tasks. Rollback returns to
the deprecated Local GUI and its old security/configuration model.

## Operations and validation

```bash
ssh ansible@openhands.cosmos.cboxlab.com
sudo systemctl status openhands nginx openhands-docker-ingress
sudo journalctl -u openhands -f
sudo docker ps
sudo certbot certificates
```

Verified trusted HTTPS, authenticated Canvas/API access, rejected requests
without Basic Auth or backend keys, Automation Server listing/health, blocked
LAN access to port 8000, and an actual Qwen conversation returning
`AGENT_CANVAS_QWEN_OK`. The test conversation was deleted. Settings/profile
persistence was verified across a service restart. Rerunning Ansible is
idempotent. Repository changes remain uncommitted.
