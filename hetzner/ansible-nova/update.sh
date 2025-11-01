#!/usr/bin/env bash
# Container Update Script (for CI/CD)

set -e

echo "Updating containers on nova..."

# SSH to nova and update containers
ssh -6 root@nova.hetzner.cboxlab.com << 'EOF'
cd /opt/nova-services

# Pull latest images and recreate containers
podman-compose pull
podman-compose up -d --force-recreate

echo "✅ Update complete!"
EOF
