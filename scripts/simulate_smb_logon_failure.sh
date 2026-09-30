#!/usr/bin/env bash
set -euo pipefail

# Safe lab-only simulation: repeated failed SMB login attempts.
# Do not run this against systems you do not own or administer.

TARGET="${1:-192.168.56.1}"
USER="${2:-fakeuser}"
PASS="${3:-WrongPassword}"
COUNT="${4:-10}"

for i in $(seq 1 "$COUNT"); do
  echo "[$i/$COUNT] SMB login failure test against //$TARGET/"
  smbclient -L "//$TARGET/" -U "${USER}%${PASS}" || true
  sleep 1
done
