#!/usr/bin/env bash
set -euo pipefail
IP=$(cd terraform && terraform output -raw ipv4_address)
exec ssh root@"$IP"