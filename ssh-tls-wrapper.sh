#!/bin/sh
# ssh-tls-wrapper.sh
# TLS wrapper for ProxyCommand – uses env vars for host/port

set -u

SSH_HOST="${SSH_HOST}"
SSH_PORT="${SSH_PORT}"
SNI_HOST="${SNI_HOST}"

exec openssl s_client -connect "${SSH_HOST}:${SSH_PORT}" \
                      -servername "${SNI_HOST}" \
                      -quiet