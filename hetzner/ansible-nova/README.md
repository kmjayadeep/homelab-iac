# Nova Server

Host nginx (443 SSL) → localhost ports → containers  
Wildcard cert: `*.hetzner.cboxlab.com` (DNS challenge)

## Setup

1. Edit `inventory/group_vars/nova.yml` - set your email
2. Set API token: `export CLOUDFLARE_API_TOKEN="your-token"`
3. Deploy: `./deploy.sh`

Or use direnv: `cp .envrc.example .envrc && direnv allow`

## Update

```bash
./update.sh
```

## Services

- **Syncthing**: https://psuite.hetzner.cboxlab.com (personal sync)
  - Ports: 8384 (web), 22000 (sync), 21027 (discovery)  
  - Volumes: `psuite-data` and `psuite-config` (persistent)
  - Health checks: `/rest/noauth/health`

## Add Service

1. Edit `roles/podman/files/compose.yml` - add service + port
2. Edit `roles/nginx/files/nginx.conf` - add upstream server  
3. Run `./deploy.sh`

Example:
```yaml
my-app:
  image: my-app:latest
  ports:
    - "3000:3000"
```

```nginx
upstream backend {
    server 127.0.0.1:8384;   # psuite syncthing
    server 127.0.0.1:3000;   # my-app
}
```