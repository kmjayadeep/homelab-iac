# Nova Server - GitOps Container Management

Host nginx → Podman Compose → GitOps workflow with Renovate.

## Architecture

```
Host nginx (443) → localhost:8080 → nginx-app container
                 → localhost:3000 → my-app container  
                 → localhost:8081 → postgres container
                   
               Port-based routing via localhost!
```

**Simple port-based routing** - host nginx talks to containers via localhost ports!

## Deploy

```bash
./deploy.sh
```

## GitOps Workflow

1. **Renovate** auto-updates `docker-compose.yml` image versions
2. **Push to master** triggers container updates  
3. **update.sh** pulls new images and updates nginx config
4. **Zero downtime** container updates

## What you get

- ✅ **Podman Compose** (`/opt/nova-services/docker-compose.yml`)
- ✅ **Port-based routing** (localhost:port → containers)
- ✅ **Renovate integration** (auto image updates)  
- ✅ **CI/CD ready** (`update.sh` for automated deployments)
- ✅ **Host nginx** (443, SSL termination + routing)
- ✅ **Simple setup** (no complex networking)

## File Structure

```
ansible-nova/
├── roles/
│   ├── nginx/files/
│   │   ├── nginx.conf              # Host nginx config (→ /etc/nginx/sites-available/nova)
│   │   └── container-nginx.conf    # Container nginx config (→ /opt/nova-services/nginx.conf)
│   └── podman/templates/
│       └── docker-compose.yml.j2   # Main compose template
└── .gitignore                      # Excludes local customizations

# On server:
/etc/nginx/sites-enabled/nova       # Host nginx: 443 → localhost:XXXX (port routing)
/opt/nova-services/
├── docker-compose.yml              # Generated from template (Renovate managed)
└── nginx.conf                     # Simple container config (placeholder)
```

## CI/CD Integration

```bash
# Manual update (or from CI/CD)
./update.sh

# View current containers
ssh -6 root@nova.hetzner.cboxlab.com
cd /opt/nova-services
podman-compose ps
```

## Add More Services

1. **Copy example**: `cp services.example.yml services.yml`
2. **Customize** `services.yml` with your apps
3. **Update template**: Edit `roles/podman/templates/docker-compose.yml.j2`  
4. **Re-deploy**: `./deploy.sh`

Example multi-service setup:

```yaml
services:
  nginx-app:
    image: docker.io/nginx:1.25-alpine
    ports:
      - "8080:80"  # Host nginx routes here
    
  my-app:
    image: my-app:latest
    ports:
      - "3000:3000"  # Host nginx can route here
    environment:
      - NODE_ENV=production
      
  postgres:
    image: postgres:15-alpine
    ports:
      - "5432:5432"  # If needed for external access
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

## Port-Based Routing

**Single nginx config handles everything:**
- `roles/nginx/files/nginx.conf` → Host nginx (SSL + routing)
- `roles/nginx/files/container-nginx.conf` → Simple placeholder

Add services to host nginx upstream:

```nginx
upstream backend {
    server 127.0.0.1:8080;   # nginx-app container
    server 127.0.0.1:3000;   # my-app container
}

location /api/ {
    proxy_pass http://127.0.0.1:3000/;  # Direct port routing
}

location /db-admin/ {  
    proxy_pass http://127.0.0.1:8081/;  # Another container
}
```

**Benefits:**
- ✅ **Simple setup** - just bind container ports
- ✅ **Host-level routing** - all logic in one nginx
- ✅ **Easy debugging** - standard localhost:port
- ✅ **No complexity** - no container networking needed

**Modern GitOps container management!** 🚀