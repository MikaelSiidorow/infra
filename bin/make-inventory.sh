#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
IP=$(cd "$ROOT_DIR/terraform" && terraform output -raw ipv4_address)
mkdir -p "$ROOT_DIR/ansible"
cat > "$ROOT_DIR/ansible/inventory.ini" <<EOF
[coolify]
$IP
EOF
echo "Wrote ansible/inventory.ini with host $IP"