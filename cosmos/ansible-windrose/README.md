# Windrose Server Ansible Setup

This Ansible project deploys a Windrose dedicated server on `windrose.cosmos.cboxlab.com` using Docker Compose.

Windrose does not currently provide a native Linux server. This project uses the community Wine-in-Docker approach and the `ghcr.io/uberdudepl/windrose-dedicated-server-docker` image because it provides pinned releases, health checks, persistent volumes, diagnostics, backups, and helper-oriented configuration.

Upstream image and documentation: https://github.com/UberDudePL/windrose-dedicated-server-docker

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

## Import a Local World

Use a stop, backup, copy, edit, start workflow. Replace `<WorldIslandId>` with the folder name of the world you want to import.

Local Steam worlds live under:

```text
/home/jayadeep/.steam/root/steamapps/compatdata/3041230/pfx/drive_c/users/steamuser/AppData/Local/R5/Saved/SaveProfiles/76561198379968698/RocksDB/0.10.0/Worlds
```

Server worlds live under:

```text
/home/windrose/windrose-server/data/R5/Saved/SaveProfiles/Default/RocksDB_v2/0.10.0/Worlds
```

Stop the server:

```bash
ansible-playbook playbooks/stop.yml
```

Back up the current server data:

```bash
ssh windrose \
  'mkdir -p /home/windrose/windrose-server/backups && tar -czf /home/windrose/windrose-server/backups/pre-world-import-$(date +%Y%m%d-%H%M%S).tar.gz -C /home/windrose/windrose-server data'
```

Copy your local world folder to the server:

```bash
rsync -avh --progress \
  /home/jayadeep/.steam/root/steamapps/compatdata/3041230/pfx/drive_c/users/steamuser/AppData/Local/R5/Saved/SaveProfiles/76561198379968698/RocksDB/0.10.0/Worlds/<WorldIslandId>/ \
  windrose:/tmp/<WorldIslandId>/
```

Move the world into the persistent data directory:

```bash
ssh windrose
mkdir -p /home/windrose/windrose-server/data/R5/Saved/SaveProfiles/Default/RocksDB_v2/0.10.0/Worlds/<WorldIslandId>
rsync -avh /tmp/<WorldIslandId>/ /home/windrose/windrose-server/data/R5/Saved/SaveProfiles/Default/RocksDB_v2/0.10.0/Worlds/<WorldIslandId>/
```

Edit `/home/windrose/windrose-server/data/R5/ServerDescription.json` and set the persistent world ID to the copied folder name:

```json
"ServerDescription_Persistent": {
  "WorldIslandId": "<WorldIslandId>"
}
```

Start the server:

```bash
ansible-playbook playbooks/start.yml
```

Watch logs while the world loads:

```bash
ssh windrose \
  'docker compose --project-directory /home/windrose/windrose-server logs -f windrose'
```

The copied world folder name, `WorldDescription.IslandId` inside that world, and `ServerDescription_Persistent.WorldIslandId` must match exactly.

## Notes

The container uses `network_mode: host`, matching the upstream production compose file. UFW allows SSH plus UDP `7777` and `7778`; direct-connection TCP is only opened when `windrose_use_direct_connection` is enabled.

`windrose_seccomp_unconfined` is enabled by default because Wine can fail during prefix initialization when Docker blocks socket family `AF_ALG` with `socket: Function not implemented`. This relaxes seccomp only for the Windrose container.
