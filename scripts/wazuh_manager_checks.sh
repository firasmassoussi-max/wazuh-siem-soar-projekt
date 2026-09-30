#!/usr/bin/env bash
set -euo pipefail

echo "== Network =="
hostname -I || true
ip a | sed -n '1,120p'

echo "== Route =="
ip route || true

echo "== Wazuh Manager =="
sudo systemctl status wazuh-manager.service --no-pager || true

echo "== Agents =="
sudo /var/ossec/bin/agent_control -l || true
