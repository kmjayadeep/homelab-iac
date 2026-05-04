# Windrose Server Ansible Setup

This Ansible project deploys a Windrose dedicated server on `windrose.cosmos.cboxlab.com` using Docker Compose.

Windrose does not currently provide a native Linux server. This project uses the community Wine-in-Docker approach and the `ghcr.io/uberdudepl/windrose-dedicated-server-docker` image because it provides pinned releases, health checks, persistent volumes, diagnostics, backups, and helper-oriented configuration.

## Prerequisites

- Ansible installed locally
- SSH access to `windrose.cosmos.cboxlab.com` as the `ansible` user
- Target host running Ubuntu 22.04+ or Debian 12+
- At least 8 GB RAM, with 12-16 GB preferred for larger groups
- IPv6 must not be disabled with the `ipv6.disable=1` kernel flag

## Installation

```bash
cd ansible-windrose
ansible-galaxy collection install -r requirements.yml
ansible all -m ping
ansible-playbook playbooks/setup.yml
```

Or run:

```bash
./deploy.sh
```

## Configuration

Edit `inventory/group_vars/windrose_servers.yml` before deploying.

Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `windrose_image_tag` | `v1.6.2` | Docker image tag to deploy |
| `windrose_seccomp_unconfined` | `true` | Allows Wine to initialize when Docker's default seccomp profile blocks `AF_ALG` sockets |
| `windrose_server_name` | `Cosmos Windrose Server` | Server name patched into `ServerDescription.json` |
| `windrose_invite_code` | empty | Optional invite code. Empty lets the server generate one |
| `windrose_server_password` | empty | Optional server password |
| `windrose_max_players` | `4` | Maximum players |
| `windrose_port` | `7777` | Game port |
| `windrose_query_port` | `7778` | Query port |
| `windrose_puid` / `windrose_pgid` | empty | Optional explicit container UID/GID. Empty uses the target host's `windrose` user |

The server files live on the host under:

```text
/home/windrose/windrose-server
```

Persistent data is stored in:

```text
/home/windrose/windrose-server/data
/home/windrose/windrose-server/steam-home
```

## Usage

Start:

```bash
ansible-playbook playbooks/start.yml
```

Stop:

```bash
ansible-playbook playbooks/stop.yml
```

Restart:

```bash
ansible-playbook playbooks/restart.yml
```

Update image and recreate:

```bash
ansible-playbook playbooks/update.yml
```

View logs:

```bash
ssh ansible@windrose.cosmos.cboxlab.com
sudo docker compose --project-directory /home/windrose/windrose-server logs -f windrose
```

Players normally join with the generated invite code from:

```text
/home/windrose/windrose-server/data/R5/ServerDescription.json
```

## Notes

The container uses `network_mode: host`, matching the upstream production compose file. UFW allows SSH plus UDP `7777` and `7778`; direct-connection TCP is only opened when `windrose_use_direct_connection` is enabled.

`windrose_seccomp_unconfined` is enabled by default because Wine can fail during prefix initialization when Docker blocks socket family `AF_ALG` with `socket: Function not implemented`. This relaxes seccomp only for the Windrose container.
