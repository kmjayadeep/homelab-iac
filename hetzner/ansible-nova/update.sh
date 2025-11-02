#!/usr/bin/env bash
# Container Update Script (for CI/CD)

set -e

echo "Updating containers on nova..."

# SSH to nova and update containers
ssh -6 root@psuite.hetzner.cboxlab.com << 'EOF'
cd /opt/podman-compose

# Pull latest images and recreate containers
podman-compose pull
podman-compose up -d --force-recreate

echo "✅ Update complete!"
echo ""
echo "Services:"
echo "- Syncthing: https://psuite.hetzner.cboxlab.com"
echo "- Wiki:      https://wiki.hetzner.cboxlab.com"
echo ""
podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF
