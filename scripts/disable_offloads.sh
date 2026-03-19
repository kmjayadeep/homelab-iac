#!/usr/bin/env bash
set -euo pipefail

: <<'SCRIPT_DOC'
================================================================================
disable_offloads.sh — Disable NIC Offloading at Runtime and Persistently via systemd
================================================================================

DESCRIPTION:
  This script disables all toggleable NIC offloading features for a given 
  network interface, both immediately (runtime) and persistently across reboots 
  using a systemd service.

  It is idempotent:
    - If all offloads are already disabled, the runtime ethtool command is skipped.
    - If the persistent systemd unit already exists with the expected settings, 
      the file is not rewritten.
    - If the unit exists but differs, a warning is shown and the file is left 
      untouched (to avoid overwriting custom configs).

  Designed for Proxmox 9 / Debian systems but works on most modern Linux systems
  with systemd.

ACTIONS PERFORMED:
  1. Verifies the given interface exists and ethtool is available.
  2. Displays current offload settings (filtered to key features).
  3. Disables these offloads at runtime (if any are still enabled):
       - tso  (TCP segmentation offload)
       - gso  (Generic segmentation offload)
       - gro  (Generic receive offload)
       - tx   (TX checksumming)
       - rx   (RX checksumming)
       - rxvlan (VLAN receive offload)
       - txvlan (VLAN transmit offload)
  4. Displays updated offload settings after the change.
  5. Creates a persistent systemd service that runs the same ethtool command 
     at boot, unless such a service already exists with the expected command.
  6. Enables and starts the service if not already enabled/active.

USAGE:
    sudo ./disable_offloads.sh <interface>
  Example:
    sudo ./disable_offloads.sh eno1
  Download and run one-line example:
    wget -qO- https://raw.githubusercontent.com/garrettlaman/homelab-scripts/main/disable_offloads.sh | bash -s -- eno1

REMOVAL:
    sudo systemctl disable --now disable-offload-<iface>.service
    sudo rm /etc/systemd/system/disable-offload-<iface>.service
    sudo systemctl daemon-reload

DEPENDENCIES:
  - ethtool
  - systemd
  - bash

AUTHOR:
  Garrett Laman — August 2025
================================================================================
SCRIPT_DOC

usage() {
  echo "Usage: sudo $0 <interface>"
  echo "Example: sudo $0 eno1"
  exit 1
}

[[ $# -eq 1 ]] || usage
IFACE="$1"

# --- Preconditions ---
if [[ $EUID -ne 0 ]]; then
  echo "Error: run as root (use sudo)."
  exit 1
fi
command -v ethtool >/dev/null 2>&1 || { echo "Error: ethtool not installed. apt update && apt install -y ethtool"; exit 1; }
ip link show "$IFACE" >/dev/null 2>&1 || { echo "Error: interface '$IFACE' not found."; exit 1; }
ETHTOOL_BIN="$(command -v ethtool)"

SERVICE="disable-offload-${IFACE}.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE}"
EXPECTED_CMD="${ETHTOOL_BIN} -K ${IFACE} gso off gro off tso off tx off rx off rxvlan off txvlan off"

PATTERN='^(tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload|tx-checksumming|rx-checksumming|rx-vlan-offload|tx-vlan-offload):'

divider() { printf '%*s\n' "$(tput cols 2>/dev/null || echo 80)" '' | tr ' ' '-'; }

read_status() {
  ethtool -k "$IFACE" 2>/dev/null | grep -E "$PATTERN" || true
}

enabled_nonfixed_count() {
  read_status | awk -F': ' '/: on/ && $0 !~ /\[fixed\]/ {c++} END{print c+0}'
}

enabled_nonfixed_list() {
  read_status | awk -F': ' '/: on/ && $0 !~ /\[fixed\]/ {print "- " $1}'
}

# --- Report BEFORE ---
echo "Interface: $IFACE"
divider
echo "Before (key offloads):"
read_status || true
BEFORE_CNT=$(enabled_nonfixed_count)
if (( BEFORE_CNT > 0 )); then
  echo
  echo "Toggleable offloads currently ENABLED:"
  enabled_nonfixed_list || true
else
  echo
  echo "All toggleable offloads already OFF. No runtime change needed."
fi

# --- Disable offloads at runtime (only if needed) ---
if (( BEFORE_CNT > 0 )); then
  echo
  echo "Disabling ALL toggleable offloads now..."
  set +e
  $EXPECTED_CMD
  ETHTOOL_RC=$?
  set -e
  if [[ $ETHTOOL_RC -ne 0 ]]; then
    echo "Note: ethtool reported some flags unsupported (normal for some NICs)."
  fi
else
  echo "Skipping runtime ethtool call (already disabled)."
fi

# --- Verify AFTER ---
AFTER_CNT=$(enabled_nonfixed_count)
divider
echo "After (key offloads):"
read_status || true
echo

if (( AFTER_CNT == 0 )); then
  echo "✅ All toggleable offloads are OFF at runtime."
else
  echo "⚠️  Some toggleable offloads remain ON (non-fixed):"
  enabled_nonfixed_list || true
fi

# --- Systemd unit management (idempotent) ---
echo
echo "Ensuring persistent disable via systemd unit: ${SERVICE}"

create_service_file() {
  cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Disable All NIC Offloading on ${IFACE}
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${EXPECTED_CMD}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
}

NEEDS_DAEMON_RELOAD=0

if [[ -f "$SERVICE_PATH" ]]; then
  # Check if ExecStart matches
  if grep -q "^ExecStart=${EXPECTED_CMD}$" "$SERVICE_PATH"; then
    echo "Service file exists with expected ExecStart. No rewrite needed."
  else
    echo "⚠️  Service file exists but ExecStart differs."
    echo "     Expected: ${EXPECTED_CMD}"
    echo "     Found:    $(grep '^ExecStart=' "$SERVICE_PATH" | head -n1 | cut -d= -f2-)"
    echo "     Not modifying existing unit. (Edit manually if desired.)"
  fi
else
  echo "Creating service file..."
  create_service_file
  NEEDS_DAEMON_RELOAD=1
fi

if (( NEEDS_DAEMON_RELOAD == 1 )); then
  systemctl daemon-reload
fi

# Enable if not enabled
if systemctl is-enabled "$SERVICE" >/dev/null 2>&1; then
  echo "Service already enabled."
else
  echo "Enabling service..."
  systemctl enable "$SERVICE"
fi

# Start if not active
if systemctl is-active "$SERVICE" >/dev/null 2>&1; then
  echo "Service already active."
else
  echo "Starting service..."
  systemctl start "$SERVICE"
fi

echo
echo "Unit status:"
systemctl --no-pager --full status "$SERVICE" || true
echo
echo "Done."
