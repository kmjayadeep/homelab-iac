# Changes Made to Valheim Server Setup

## Overview
This project has been updated to use SteamCMD for native Valheim server installation instead of Docker, and configured to use the existing `valheim` user.

## Key Changes

### 1. Installation Method
- **Before**: Docker-based installation using `lloesche/valheim-server` image
- **After**: Native installation using SteamCMD with systemd service management

### 2. User Configuration
- **User**: `valheim` (existing user)
- **Home Directory**: `/home/valheim`
- **No user creation**: Uses existing valheim user on the system

### 3. Directory Structure
```
/home/valheim/
├── valheim-server/          # Server installation
├── steamcmd/                # SteamCMD installation
├── valheim-backups/         # Backup storage
└── .config/unity3d/IronGate/Valheim/
    └── worlds/              # World save files
```

### 4. Service Management
- **Systemd service**: `/etc/systemd/system/valheim.service`
- **Auto-updates**: Server checks for updates on startup
- **Auto-restart**: Service configured to restart on failure

### 5. New Features
- Native performance (better than Docker)
- Automatic update checks on service start
- Systemd integration for better system management
- Cron-based automatic backups (3:00 AM daily)
- Dedicated update playbook

## Playbooks

### Available Playbooks
1. `playbooks/setup.yml` - Initial server setup and installation
2. `playbooks/start.yml` - Start the server
3. `playbooks/stop.yml` - Stop the server
4. `playbooks/restart.yml` - Restart the server
5. `playbooks/update.yml` - Update the server (NEW)
6. `playbooks/backup.yml` - Create manual backup

## Configuration Variables

### Key Variables in `group_vars/valheim_servers.yml`
```yaml
valheim_server_name: "Cosmos Valheim Server"
valheim_world_name: "RiversWorld"
valheim_server_password: "changeme123"  # CHANGE THIS!
valheim_public: 1
valheim_server_port: 2456

valheim_install_dir: "/home/valheim/valheim-server"
steamcmd_dir: "/home/valheim/steamcmd"
valheim_data_dir: "/home/valheim/.config/unity3d/IronGate/Valheim"
valheim_backups_dir: "/home/valheim/valheim-backups"

steam_user: "valheim"
steam_group: "valheim"
steam_home: "/home/valheim"
```

## Installation Steps

1. **Install Ansible collections**:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

2. **Update configuration**:
   Edit `group_vars/valheim_servers.yml` and change the server password!

3. **Deploy**:
   ```bash
   ./deploy.sh
   # OR
   ansible-playbook playbooks/setup.yml
   ```

## Management Commands

### Systemd Service
```bash
# On the server
sudo systemctl status valheim
sudo systemctl start valheim
sudo systemctl stop valheim
sudo systemctl restart valheim
sudo journalctl -u valheim -f
```

### Ansible Playbooks
```bash
ansible-playbook playbooks/start.yml
ansible-playbook playbooks/stop.yml
ansible-playbook playbooks/restart.yml
ansible-playbook playbooks/update.yml
ansible-playbook playbooks/backup.yml
```

## Benefits of SteamCMD Approach

1. **Better Performance**: Native execution without containerization overhead
2. **Simpler Debugging**: Direct access to server processes and logs
3. **Lower Resource Usage**: No Docker daemon required
4. **Official Method**: Uses Valve's official SteamCMD tool
5. **Systemd Integration**: Better system integration and management

## Files Removed
- `roles/valheim/tasks/docker.yml` - No longer needed

## Files Added
- `roles/valheim/tasks/steamcmd.yml` - SteamCMD installation
- `roles/valheim/tasks/systemd.yml` - Systemd service setup
- `roles/valheim/handlers/main.yml` - Ansible handlers
- `roles/valheim/templates/valheim.service.j2` - Systemd service template
- `roles/valheim/templates/start_valheim.sh.j2` - Server startup script
- `roles/valheim/templates/backup_valheim.sh.j2` - Backup script
- `playbooks/update.yml` - Server update playbook
- `QUICKSTART.md` - Quick reference guide

## Requirements
- Debian/Ubuntu-based system
- Existing `valheim` user with home directory at `/home/valheim`
- Sudo access for the ansible user
- Ports 2456-2458 UDP open on firewall

## Next Steps

1. Change the server password in `group_vars/valheim_servers.yml`
2. Run `ansible-galaxy collection install -r requirements.yml`
3. Test connectivity: `ansible all -m ping`
4. Deploy: `./deploy.sh` or `ansible-playbook playbooks/setup.yml`
5. Monitor: `ssh ansible@valheim-rivers.cosmos.cboxlab.com 'sudo journalctl -u valheim -f'`

