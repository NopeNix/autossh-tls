#!/bin/sh
# entrypoint.sh — Production-grade autossh with strict checks

set -u

echo "🚀 autossh-tls: Starting connection setup"

# Required environment variables
: "${SSH_HOST?❌ ERROR: SSH_HOST is not set}"
: "${SSH_PORT?❌ ERROR: SSH_PORT is not set}"
: "${SNI_HOST?❌ ERROR: SNI_HOST is not set}"
: "${SSH_USER?❌ ERROR: SSH_USER is not set}"
: "${SSH_KEY_FILE?❌ ERROR: SSH_KEY_FILE path not set}"
: "${REMOTE_PORT?❌ ERROR: REMOTE_PORT not set, e.g. 3306}"

# Validate SSH key
if [ ! -f "$SSH_KEY_FILE" ]; then
  echo "❌ ERROR: Private key not found at $SSH_KEY_FILE" >&2
  exit 1
fi
chmod 600 "$SSH_KEY_FILE" || exit 1

# Validate known_hosts
if [ ! -f /root/.ssh/known_hosts ]; then
  echo "❌ ERROR: /root/.ssh/known_hosts not found!" >&2
  echo "👉 Run: ssh-keyscan -p $SSH_PORT $SSH_HOST >> known_hosts && docker cp known_hosts <container>:/root/.ssh/known_hosts" >&2
  exit 1
fi

echo "✅ SSH credentials validated"

# Export to autossh
export AUTOSSH_POLL=30
export AUTOSSH_FIRST_POLL=10
export AUTOSSH_GATETIME=20
export AUTOSSH_LOGLEVEL=7
export AUTOSSH_LOGFILE=/proc/1/fd/1  # log to container stdout

# Optional: maximum lifetime (e.g. forced rotation)
# export AUTOSSH_MAXLIFETIME=86400

echo "🔄 Starting autossh: ${SSH_USER}@${SSH_HOST}:${SSH_PORT} → db:3306"

exec autossh -M 0 \
  -o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile=/root/.ssh/known_hosts \
  -o IdentityFile="$SSH_KEY_FILE" \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=3 \
  -N \
  -R "${REMOTE_PORT}":db:3306 \
  "${SSH_USER}"@"${SSH_HOST}" \
  -p "${SSH_PORT}" \
  -o ProxyCommand="openssl s_client -connect ${SSH_HOST}:${SSH_PORT} -servername ${SNI_HOST} -quiet"