#!/bin/sh
# entrypoint.sh — Fully configurable autossh over TLS with SNI

set -u

echo "🚀 autossh-tls: Starting validation"

# Tunnel direction: 'reverse' (default) or 'forward'
TUNNEL_DIRECTION="${TUNNEL_DIRECTION:-reverse}"

# Required environment variables
: "${SSH_HOST?❌ ERROR: SSH_HOST is not set}"
: "${SSH_PORT?❌ ERROR: SSH_PORT is not set}"
: "${SNI_HOST?❌ ERROR: SNI_HOST is not set}"
: "${SSH_USER?❌ ERROR: SSH_USER is not set}"
: "${SSH_KEY_FILE?❌ ERROR: SSH_KEY_FILE is not set}"
: "${REMOTE_BIND_PORT?❌ ERROR: REMOTE_BIND_PORT is not set (e.g. 3306) on remote side}"
: "${TARGET_HOST?❌ ERROR: TARGET_HOST is not set (e.g. db)}"
: "${TARGET_PORT?❌ ERROR: TARGET_PORT is not set (e.g. 3306)}"

# Validate private key
if [ ! -f "$SSH_KEY_FILE" ]; then
  echo "❌ ERROR: Private key not found at $SSH_KEY_FILE" >&2
  exit 1
fi
chmod 600 "$SSH_KEY_FILE" || exit 1

# Validate known_hosts
if [ ! -f /root/.ssh/known_hosts ]; then
  echo "❌ ERROR: /root/.ssh/known_hosts not found!" >&2
  echo "👉 Run: ssh-keyscan -p \$SSH_PORT \$SSH_HOST >> known_hosts" >&2
  exit 1
fi

echo "✅ All required config validated"

# Set autossh options
export AUTOSSH_POLL=30
export AUTOSSH_FIRST_POLL=10
export AUTOSSH_GATETIME=20
export AUTOSSH_LOGLEVEL=7
export AUTOSSH_LOGFILE=/proc/1/fd/1  # stdout

# Determine tunnel configuration based on direction
if [ "$TUNNEL_DIRECTION" = "forward" ]; then
  # Forward tunnel: LOCAL_PORT:TARGET_HOST:TARGET_PORT
  # Explicitly bind to all interfaces to avoid localhost binding issues
  # Force IPv4 only to avoid IPv6 issues
  TUNNEL_ARG="-L *:${REMOTE_BIND_PORT}:${TARGET_HOST}:${TARGET_PORT}"
  echo "🔄 Starting autossh (FORWARD): ${SSH_USER}@${SSH_HOST}:${SSH_PORT} ← ${TARGET_HOST}:${TARGET_PORT} (local port: ${REMOTE_BIND_PORT})"
else
  # Reverse tunnel: REMOTE_BIND_PORT:TARGET_HOST:TARGET_PORT
  # Bind only to IPv4 addresses to avoid IPv6 issues
  TUNNEL_ARG="-R *:${REMOTE_BIND_PORT}:${TARGET_HOST}:${TARGET_PORT}"
  echo "🔄 Starting autossh (REVERSE): ${SSH_USER}@${SSH_HOST}:${SSH_PORT} → ${TARGET_HOST}:${TARGET_PORT} (remote bind: ${REMOTE_BIND_PORT})"
fi

exec autossh -M 0 \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile=/root/.ssh/known_hosts \
  -o IdentityFile="$SSH_KEY_FILE" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=3 \
  -o AddressFamily=inet \
  -N \
  $TUNNEL_ARG \
  "${SSH_USER}@${SSH_HOST}" \
  -p "${SSH_PORT}" \
  -o ProxyCommand="openssl s_client -connect ${SSH_HOST}:${SSH_PORT} -servername ${SNI_HOST} -quiet"
