# Valheim Server Ansible Setup

This Ansible project automates the deployment and management of a Valheim dedicated server on Proxmox using SteamCMD.

## Features

- **Native installation** using SteamCMD for better performance
- **Systemd service** for automatic startup and management
- **Automated installation** of SteamCMD and all prerequisites
- **Firewall configuration** using UFW
- **Easy server management** with dedicated playbooks for start/stop/restart/update
- **Customizable configuration** through group variables

## Prerequisites

- Ansible 2.9 or higher installed on your local machine
- SSH access to the target server (valheim-rivers.cosmos.cboxlab.com)
- SSH key configured for the `ansible` user
- Target server running Debian/Ubuntu

## Installation

### 1. Install Ansible Collections

First, install the required Ansible collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

### 2. Configure Variables

Edit `group_vars/valheim_servers.yml` to customize your server settings:

```yaml
valheim_server_name: "Your Server Name"
valheim_world_name: "YourWorldName"
valheim_server_password: "your-secure-password"  # CHANGE THIS!
valheim_public: 1  # 0 for private, 1 for public
```

**Important:** Change the default password!

### 3. Verify Connectivity

Test your SSH connection and Ansible setup:

```bash
ansible all -m ping
```

## Usage

### Initial Setup

Deploy the Valheim server for the first time:

```bash
ansible-playbook playbooks/setup.yml
```

This will:
- Install Docker and prerequisites
- Configure the firewall
- Pull the Valheim server Docker image
- Start the Valheim server
- Configure automatic backups

### Server Management

**Start the server:**
```bash
ansible-playbook playbooks/start.yml
```

**Stop the server:**
```bash
ansible-playbook playbooks/stop.yml
```

**Restart the server:**
```bash
ansible-playbook playbooks/restart.yml
```

**Update the server:**
```bash
ansible-playbook playbooks/update.yml
```

### View Server Logs

To check the server logs:

```bash
ssh ansible@valheim-rivers.cosmos.cboxlab.com
sudo journalctl -u valheim -f
```

Or view recent logs:
```bash
sudo journalctl -u valheim -n 100
```

## Configuration

### Main Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `valheim_server_name` | "Cosmos Valheim Server" | Server name shown in the server list |
| `valheim_world_name` | "RiversWorld" | World name (used for save files) |
| `valheim_server_password` | "changeme123" | Server password (CHANGE THIS!) |
| `valheim_public` | 1 | 0 for private, 1 for public server |
| `valheim_server_port` | 2456 | Game server port (uses +1 and +2 as well) |
| `valheim_install_dir` | "/home/valheim/valheim-server" | Installation directory for server files |
| `steamcmd_dir` | "/home/valheim/steamcmd" | SteamCMD installation directory |
| `valheim_modifiers` | [] | List of server modifiers (see below) |

### Server Modifiers

You can customize gameplay using Valheim's built-in modifiers. Add them to `valheim_modifiers` in your group_vars:

```yaml
valheim_modifiers:
  - "-modifier deathpenalty casual"    # Casual death penalty
  - "-modifier raids none"             # Disable raids
  - "-modifier resources most"         # More resources
  - "-setkey StaminaRate 50"          # Set stamina regeneration rate
  - "-modifier portals casual"         # Casual portal restrictions
```

Available modifiers:
- **deathpenalty**: `none`, `casual`, `hardcore`
- **raids**: `none`, `much`, `often`
- **resources**: `muchless`, `less`, `more`, `most`
- **portals**: `casual` (allows teleporting with metals)
- **combat**: `easy`, `hard`, `veryhard`
- **stamina**: `easy`, `hard`

Use `-setkey` to set specific values like StaminaRate, HealthRate, etc.

### Directories

- Installation directory: `/home/valheim/valheim-server`
- SteamCMD directory: `/home/valheim/steamcmd`
- Save files: `/home/valheim/.config/unity3d/IronGate/Valheim/worlds`

## Network Configuration

The server requires the following UDP ports to be open:

- **2456** - Game port
- **2457** - Game port + 1
- **2458** - Game port + 2

These are automatically configured by the playbook using UFW.

## Connecting to Your Server

1. Launch Valheim
2. Select "Join Game"
3. Click "Join IP"
4. Enter: `valheim-rivers.cosmos.cboxlab.com:2456`
5. Enter your server password

## Troubleshooting

### Server not starting

Check service status and logs:
```bash
ssh ansible@valheim-rivers.cosmos.cboxlab.com
sudo systemctl status valheim
sudo journalctl -u valheim -n 100
```

### Can't connect to server

1. Verify the server is running: `sudo systemctl status valheim`
2. Check firewall rules: `sudo ufw status`
3. Verify ports are listening: `sudo netstat -tulpn | grep 2456`

### Update the server

The server automatically checks for updates on startup. To manually update:
```bash
ansible-playbook playbooks/update.yml
```

## Advanced Configuration

### Mods Support

To enable mods, edit `group_vars/valheim_servers.yml`:

```yaml
valheim_mods_enabled: true
valheim_mods:
  - "BepInExPack_Valheim"
  - "ValheimPlus"
```

### Performance Tuning

The native installation provides better performance than Docker. You can adjust system limits by editing `/etc/systemd/system/valheim.service` on the server if needed.

## Maintenance

### Regular Tasks

1. **Monitor disk space** for save files
2. **Check logs** for any errors
3. **Update the server** periodically with `ansible-playbook playbooks/update.yml`

### Manual Commands

```bash
# Check server status
ansible valheim_servers -m command -a "systemctl status valheim" -b

# Check disk usage
ansible valheim_servers -m command -a "df -h /home/valheim" -b

# View running processes
ansible valheim_servers -m command -a "ps aux | grep valheim" -b
```

## Security Notes

- Change the default server password immediately
- Keep the SSH key secure
- Regularly update the server with `ansible-playbook playbooks/update.yml`
- Consider setting `valheim_public: 0` for private servers
- Monitor server logs for suspicious activity
- Implement your own backup strategy as needed

## License

MIT

## Credits

- SteamCMD: [Valve Corporation](https://developer.valvesoftware.com/wiki/SteamCMD)
- Valheim: [Iron Gate Studio](https://www.valheimgame.com/)

