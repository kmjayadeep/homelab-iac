# Nova Server - Layered Architecture

Host nginx → Container nginx setup for flexible routing.

## Architecture

```
Host nginx (443) → nginx-app container (172.17.0.x:80) → Your apps
```

## Deploy

```bash
./deploy.sh
```

## Access

- HTTPS: https://nova.hetzner.cboxlab.com
- Container has no exposed ports (cleaner!)

## Management

```bash
# SSH to server
ssh -6 root@nova.hetzner.cboxlab.com

# Container management
podman ps                  # List containers
podman logs nginx-app      # View nginx container logs
podman restart nginx-app   # Restart nginx container

# Host nginx management
systemctl status nginx     # Host nginx status
systemctl reload nginx     # Reload host config
```