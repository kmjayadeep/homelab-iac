# Nova Server

Host nginx (443) → localhost ports → containers

## Deploy

```bash
./deploy.sh
```

## Update

```bash
./update.sh
```

## Add Service

1. Edit `roles/podman/templates/docker-compose.yml.j2` - add service + port
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
    server 127.0.0.1:8080;   # nginx-app
    server 127.0.0.1:3000;   # my-app
}
```