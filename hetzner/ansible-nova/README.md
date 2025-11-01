# Nova Server - Simple & Reliable

Host-based nginx reverse proxy + Podman for containerized services.

## Deploy

```bash
./deploy.sh
```

## What you get

- ✅ **Nginx** (host-based, reliable reverse proxy)
- ✅ **Podman** (for your containerized apps)
- ✅ **SSL ready** (certbot installed)
- ✅ **Health check** at `/health`

## Access

- HTTP: http://nova.hetzner.cboxlab.com
- Health: http://nova.hetzner.cboxlab.com/health

## Add services

```bash
# SSH to server
ssh -6 root@nova.hetzner.cboxlab.com

# Run your app in container
podman run -d --name my-app -p 3000:3000 my-app:latest

# Add to nginx config
vi /etc/nginx/sites-available/nova
systemctl reload nginx
```

**Simple, reliable, fast!** 🚀