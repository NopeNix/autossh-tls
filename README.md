# 🛡️ `autossh-tls` – Persistent SSH Reverse Tunnels Over TLS with SNI Support

# autossh-tls
> Securely expose internal services through Traefik (or any SNI-based TCP router) using SSH tunnels wrapped in **TLS with SNI** — because raw SSH gets dropped by modern reverse proxies.

![Docker Pulls](https://img.shields.io/docker/pulls/nopenix/autossh-tls?style=for-the-badge)
![License](https://img.shields.io/github/license/nopenix/autossh-tls?style=for-the-badge)

This image runs `autossh` with a **TLS-wrapped SSH connection** using `ProxyCommand=openssl s_client`, enabling **SNI-based routing** through TLS-terminated entry points (like Traefik).

Perfect for:
- Exposing internal databases (MySQL, PostgreSQL) securely
- Bypassing restrictive firewalls
- Long-lived, self-healing tunnels behind `traefik [tcp routers]`

---

## 🚀 Features

- ✅ SSH over TLS with SNI (`HostSNI(...)`)
- ✅ Full `autossh` health checks + auto-restart
- ✅ Strict `known_hosts` and key verification
- ✅ Volume-mounted SSH config (`id_rsa`, `known_hosts`)
- ✅ Fail-fast on missing environment or invalid config
- ✅ Alpine-based, **~15MB**, secure surface
- ✅ Works with **Let's Encrypt**, Traefik, and ACME-secured endpoints

---

## ⚙️ Use Case

You're running Traefik with a TCP router:

```yaml
tcp:
  routers:
    tunnel-mysql:
      rule: HostSNI(`tunnel-rapidapi-scraper-mysql.c.nopenix.de`)
      tls: {}
      service: mysql-backend