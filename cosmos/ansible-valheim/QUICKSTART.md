# Valheim Server Quick Start Guide

## Initial Setup

1. **Install Ansible collections:**
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

2. **Configure your server settings:**
   Edit `group_vars/valheim_servers.yml` and change at minimum:
   - `valheim_server_name`: Your server name
   - `valheim_world_name`: Your world name
   - `valheim_server_password`: **CHANGE THIS!**

3. **Test connectivity:**
   ```bash
   ansible all -m ping
   ```

4. **Deploy the server:**
   ```bash
   ./deploy.sh
   ```
   
   Or manually:
   ```bash
   ansible-playbook playbooks/setup.yml
   ```

## Daily Operations

### Start/Stop/Restart

```bash
# Start
ansible-playbook playbooks/start.yml

# Stop
ansible-playbook playbooks/stop.yml

# Restart
ansible-playbook playbooks/restart.yml
```

### Update Server

```bash
ansible-playbook playbooks/update.yml
```

This will:
1. Stop the server
2. Update via SteamCMD
3. Start the server

### View Logs

```bash
# Live logs
ssh ansible@valheim-rivers.cosmos.cboxlab.com 'sudo journalctl -u valheim -f'

# Recent logs
ssh ansible@valheim-rivers.cosmos.cboxlab.com 'sudo journalctl -u valheim -n 100'
```

## Server Connection

**In Valheim Client:**
1. Click "Join Game"
2. Click "Join IP"
3. Enter: `valheim-rivers.cosmos.cboxlab.com:2456`
4. Enter your password

## File Locations

| Path | Description |
|------|-------------|
| `/home/valheim/valheim-server/` | Server installation |
| `/home/valheim/steamcmd/` | SteamCMD installation |
| `/home/valheim/.config/unity3d/IronGate/Valheim/worlds/` | World save files |
| `/etc/systemd/system/valheim.service` | Systemd service file |

## Systemd Commands

```bash
# Check status
sudo systemctl status valheim

# Start/Stop/Restart
sudo systemctl start valheim
sudo systemctl stop valheim
sudo systemctl restart valheim

# Enable/Disable auto-start
sudo systemctl enable valheim
sudo systemctl disable valheim
```

## Configuration Changes

After modifying `group_vars/valheim_servers.yml`:

```bash
# Re-run setup to apply changes
ansible-playbook playbooks/setup.yml
```

## Troubleshooting

### Server won't start
```bash
ssh ansible@valheim-rivers.cosmos.cboxlab.com
sudo systemctl status valheim
sudo journalctl -u valheim -n 50
```

### Port not accessible
```bash
# Check firewall
ssh ansible@valheim-rivers.cosmos.cboxlab.com 'sudo ufw status'

# Verify server is listening
ssh ansible@valheim-rivers.cosmos.cboxlab.com 'sudo netstat -tulpn | grep 2456'
```

### Disk space issues
```bash
ansible valheim_servers -m command -a "df -h /home/valheim" -b
```

## Tips

- **Password Changes**: Update in `group_vars/valheim_servers.yml`, then run `ansible-playbook playbooks/setup.yml`
- **Port Changes**: Update `valheim_server_port` in group_vars, then re-run setup
- **Performance**: Native SteamCMD installation provides better performance than Docker
- **Backups**: Implement your own backup strategy - world files are in `/home/valheim/.config/unity3d/IronGate/Valheim/worlds`

