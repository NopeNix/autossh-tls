# `nopenix/autossh-tls`

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](https://github.com/NopeNix/autossh-tls/blob/main/LICENSE)&nbsp;&nbsp;&nbsp;
[![GitHub Repo](https://img.shields.io/badge/GitHub-Repos-181717?style=for-the-badge&logo=github)](https://github.com/NopeNix/autossh-tls)&nbsp;&nbsp;&nbsp;
[![Docker Hub](https://img.shields.io/badge/Docker_Hub-nopenix%2Fautossh--tls-0db7ed?style=for-the-badge&logo=docker)](https://hub.docker.com/r/nopenix/autossh-tls)&nbsp;&nbsp;&nbsp;
[![Docker Pulls](https://img.shields.io/docker/pulls/nopenix/autossh-tls?style=for-the-badge)](https://hub.docker.com/r/nopenix/autossh-tls)



## 🔧 What It Does

Wraps SSH in TLS so `autossh` can tunnel through **Traefik TCP routers** that require **SNI-based routing**.  
Because Traefik drops raw SSH. This container speaks **TLS + SNI + SSH + autossh monitoring** — all in one.

Use it to:
- Expose internal MySQL/PostgreSQL via reverse tunnel
- Survive `HostSNI()` routing
- Never lose your tunnel again

---

## ✅ Features

- 🔐 TLS-wrapped SSH (`ProxyCommand=openssl s_client`)
- 🔄 `autossh`-powered auto-restart & liveness
- 📦 Volume-mounted SSH keys & `known_hosts`
- 🚫 Zero defaults — fail if env missing
- 📦 Alpine-based (~15MB)
- 🧠 Works with Let's Encrypt

---

## 🎯 Use Cases

- Expose `db:3306` via Traefik `tcp@docker` router
- Secure tunnel behind e.g. `HostSNI(tunnel.example.com)` (Traefik)
- Avoid raw SSH rejection from SNI-only endpoints

---

## 🛠️ Environment Variables

| Variable | Required | Description |
|--------|---------|-------------|
| `SSH_HOST` | ✅ | Remote SSH server (e.g. `tunnel.example.com`) |
| `SSH_PORT` | ✅ | Remote SSH port (e.g. `22`) |
| `SNI_HOST` | ✅ | SNI header to send (typically same as `SSH_HOST`) |
| `SSH_USER` | ✅ | SSH user for authentication (e.g. `tunnel`) |
| `SSH_KEY_FILE` | ✅ | Path to private key inside container (e.g. `/root/.ssh/id_rsa`) |
| `REMOTE_PORT` | ✅ | Remote port to expose (e.g. `3306`) |

---

## ▶️ Docker Run Example

```bash
docker run -d \
  --name autossh-tls-mysql \
  --restart unless-stopped \
  -e SSH_HOST=tunnel.example.com \
  -e SSH_PORT=2222 \
  -e SNI_HOST=tunnel.example.com \
  -e SSH_USER=tunnel \
  -e SSH_KEY_FILE=/root/.ssh/id_rsa \
  -e REMOTE_PORT=3306 \
  -v ssh-config:/root/.ssh \
  nopenix/autossh-tls:latest
```

> 💡 `ssh-config` must contain: `id_rsa` and `known_hosts` with `[host]:port` entry

---

## ▶️ Docker Compose Example

```yaml
version: '3.8'

services:
  autossh-tls:
    image: nopenix/autossh-tls:latest
    environment:
      - SSH_HOST=tunnel.example.com
      - SSH_PORT=2222
      - SNI_HOST=tunnel.example.com
      - SSH_USER=tunnel
      - SSH_KEY_FILE=/root/.ssh/id_rsa
      - REMOTE_PORT=3306
    volumes:
      - ssh-config:/root/.ssh
    restart: unless-stopped

volumes:
  ssh-config:
```