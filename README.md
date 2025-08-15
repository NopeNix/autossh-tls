# autossh-tls

[![License](https://img.shields.io/github/license/NopeNix/autossh-tls?style=for-the-badge)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/NopeNix/autossh-tls?style=for-the-badge)](https://github.com/NopeNix/autossh-tls)
[![Docker Pulls](https://img.shields.io/docker/pulls/nopenix/autossh-tls?style=for-the-badge)](https://hub.docker.com/r/nopenix/autossh-tls)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/nopenix/autossh-tls?style=for-the-badge)](https://hub.docker.com/r/nopenix/autossh-tls)

A minimal, production-ready container for establishing reverse SSH tunnels over **TLS with SNI routing** using `autossh`.  
Perfect for exposing internal services securely when the SSH server is behind a TLS-terminating gateway (e.g., port 443 with SNI-based routing).

🔗 **GitHub**: [https://github.com/NopeNix/autossh-tls](https://github.com/NopeNix/autossh-tls)  
🐳 **Docker Hub**: [https://hub.docker.com/r/nopenix/autossh-tls](https://hub.docker.com/r/nopenix/autossh-tls)  
📌 **Base Image**: `alpine:3.18`  
🔐 **License**: MIT  

---

## ✨ Features

- ✅ Full TLS support via `openssl s_client` as `ProxyCommand`
- ✅ SNI hostname routing (`-servername`)
- ✅ Environment variable validation at startup (fail fast)
- ✅ Private key & `known_hosts` validation
- ✅ Auto-reconnect using `autossh`
- ✅ Clean logging to stdout (ideal for Docker/K8s)
- ✅ Lightweight (Alpine Linux + only essential tools)
- ✅ No root shell or unnecessary daemons

Ideal for securely tunneling databases, admin panels (like phpMyAdmin), APIs, and internal microservices.

---

## 📦 Prerequisites

Before using this image, ensure:

- An SSH server accessible over **port 443 (or any TLS-wrapped port)**
- SNI-based routing configured on the server side (e.g., via `sslh`, `nginx`, or custom proxy)
- SSH key-based authentication enabled (password login not supported)
- A `known_hosts` file for the target SSH host
- A dedicated SSH user with restricted access (e.g., `tunnel` user with forced command if needed)

---

## 🚀 Getting Started

Follow these steps to deploy `autossh-tls` and establish a secure reverse tunnel in minutes.

> 💡 Replace all placeholder values (`example.com`, `tunnel-mysql...`, IPs, ports) with your actual setup.

---

### Step 1: Prepare the SSH Private Key

Create a directory to hold your SSH credentials:

```bash
mkdir -p ./ssh
```

You should already have an SSH key pair (generated via `ssh-keygen`) or create one now:

```bash
ssh-keygen -t rsa -b 4096 -N "" -f ./ssh/id_rsa
```

> ✅ This generates:
> - Private key: `./ssh/id_rsa`
> - Public key: `./ssh/id_rsa.pub`

Add the public key (`id_rsa.pub`) to the remote SSH server's `~/.ssh/authorized_keys`.

#### Example Content: `./ssh/id_rsa`
```text
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdzc2gtcn
NhAAAAAwEAAQAAAgEA4sF...[your private key here]...FdWUMRb7k=
-----END OPENSSH PRIVATE KEY-----
```

> 🔒 Set correct permissions:
>
> ```bash
> chmod 600 ./ssh/id_rsa
> ```

---

### Step 2: Create the `known_hosts` File

To prevent man-in-the-middle attacks, the container requires a trusted `known_hosts` entry for the SSH server.

Run this command to fetch the server's public key:

```bash
ssh-keyscan -p 443 c.example.com >> ./ssh/known_hosts
```

> 🔧 If you're using a non-standard port (like 443), always specify `-p <port>`.

If `ssh-keyscan` fails due to TLS wrapping, connect manually once from another machine to verify and add the host fingerprint.

#### Example Content: `./ssh/known_hosts`

```text
c.example.com:443 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7F...[public key hash]...uQIDAQAB
```

> 🔐 Ensure file is readable and properly formatted:
>
> ```bash
> chmod 644 ./ssh/known_hosts
> ```

This file will be mounted into the container at `/root/.ssh/known_hosts`.

---

### Step 3: Start the Stack

Use the following `docker-compose.yml` as a baseline:

```yaml
version: '3.8'
services:
  autossh-tls:
    image: nopenix/autossh-tls:latest
    environment:
      - SSH_HOST=c.example.com
      - SSH_PORT=443
      - SNI_HOST=tunnel-mysql.example.com
      - SSH_USER=tunnel
      - SSH_KEY_FILE=/root/.ssh/id_rsa
      - REMOTE_BIND_PORT=3306
      - TARGET_HOST=mysql
      - TARGET_PORT=3306
    volumes:
      - ./ssh:/root/.ssh:ro
    restart: unless-stopped

  mysql:  # Example internal service
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
    command: --default-authentication-plugin=mysql_native_password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 10
    restart: unless-stopped
```

> 🔄 Replace:
> - `mysql` → your actual target service (`phpmyadmin`, `redis`, etc.)
> - `TARGET_HOST` and `TARGET_PORT` → match your internal service
> - `REMOTE_BIND_PORT` → port exposed on remote SSH server
> - Domain names → your domains
> - Ports → your actual ports

Now start the stack:

```bash
docker compose up -d
```

Check logs to confirm everything works:

```bash
docker compose logs -f autossh-tls
```

Expected success output:
```
🚀 autossh-tls: Starting validation
✅ All required config validated
🔄 Starting autossh: tunnel@c.example.com:443 → mysql:3306 (remote bind: 3306)
autossh[1]: starting ssh (count 1)
```

> ✅ **You’re live.** Your internal `mysql` service is now accessible via the reverse tunnel on the remote server.

---

### ✅ Final Checklist

| Task | Status |
|------|--------|
| 🔐 SSH key generated and added to remote `authorized_keys` | ☐ |
| 📄 `known_hosts` file created with correct host and port | ☐ |
| 🧩 Environment variables correctly set in `docker-compose.yml` | ☐ |
| 📂 `./ssh` directory mounted as `/root/.ssh:ro` | ☐ |
| 🐳 Ran `docker compose up -d` and checked logs | ☐ |

When all boxes are checked — you're golden.

Now go build something useful.

---

## 🛠️ Environment Variables

The following environment variables **must be set**:

| Variable             | Example Value                     | Description |
|----------------------|-----------------------------------|-------------|
| `SSH_HOST`           | `c.example.com`                   | Address of the SSH server |
| `SSH_PORT`           | `443`                             | Port where SSH-over-TLS runs |
| `SNI_HOST`           | `tunnel-mysql.example.com`        | Hostname used during TLS handshake |
| `SSH_USER`           | `tunnel`                          | SSH username |
| `SSH_KEY_FILE`       | `/root/.ssh/id_rsa`               | Path to private key inside container |
| `REMOTE_BIND_PORT`   | `3306`                            | Remote port on SSH server to bind to |
| `TARGET_HOST`        | `mysql` or `localhost`            | Internal service hostname |
| `TARGET_PORT`        | `3306`                            | Internal service port |

> ❗ The container fails immediately if any required variable is missing. This prevents silent failures.

---

## 🐳 Usage

### Using `docker run`

```bash
docker run -d \
  --name autossh-tls \
  --restart unless-stopped \
  -e SSH_HOST=c.example.com \
  -e SSH_PORT=443 \
  -e SNI_HOST=tunnel-mysql.example.com \
  -e SSH_USER=tunnel \
  -e SSH_KEY_FILE=/root/.ssh/id_rsa \
  -e REMOTE_BIND_PORT=3306 \
  -e TARGET_HOST=mysql \
  -e TARGET_PORT=3306 \
  -v ssh-config:/root/.ssh \
  nopenix/autossh-tls:latest
```

> Replace all values with your actual configuration.

### Using `docker-compose.yml`

```yaml
version: '3.8'
services:
  autossh-tls:
    image: nopenix/autossh-tls:latest
    environment:
      - SSH_HOST=c.example.com
      - SSH_PORT=443
      - SNI_HOST=tunnel-mysql.example.com
      - SSH_USER=tunnel
      - SSH_KEY_FILE=/root/.ssh/id_rsa
      - REMOTE_BIND_PORT=3306
      - TARGET_HOST=mysql
      - TARGET_PORT=3306
    volumes:
      - ssh-config:/root/.ssh
    restart: unless-stopped

volumes:
  ssh-config:
```

> 💡 To build locally instead of pulling from Docker Hub, replace `image:` with:
>
> ```yaml
> build:
>   context: .
> ```

---

## 🔐 SSH Key Setup

### 1. Generate a Key Pair (if you don’t have one)

```bash
ssh-keygen -t rsa -b 4096 -N "" -f ./ssh/id_rsa
```

Add the public key (`id_rsa.pub`) to the remote server’s `~/.ssh/authorized_keys`.

### 2. Create `known_hosts` File

To prevent MITM attacks, the container requires a pre-populated `known_hosts`.

Run this command (adjust port if needed):

```bash
mkdir -p ./ssh
ssh-keyscan -p 443 c.example.com >> ./ssh/known_hosts
```

Then mount the directory:

```yaml
volumes:
  - ./ssh:/root/.ssh:ro
```

> 🔒 Ensure the private key has secure permissions:
>
> ```bash
> chmod 600 ./ssh/id_rsa
> ```

---

## 🧪 Example Use Cases

### 1. Expose phpMyAdmin Securely

Expose a local `phpmyadmin` instance through a TLS-secured tunnel.

```yaml
services:
  phpmyadmin:
    image: phpmyadmin
    restart: always
    networks:
      - internal

  autossh-tls:
    image: nopenix/autossh-tls:latest
    environment:
      - SSH_HOST=c.example.com
      - SSH_PORT=443
      - SNI_HOST=tunnel-pma.example.com
      - SSH_USER=tunnel
      - SSH_KEY_FILE=/root/.ssh/id_rsa
      - REMOTE_BIND_PORT=8080
      - TARGET_HOST=phpmyadmin
      - TARGET_PORT=80
    volumes:
      - ./ssh:/root/.ssh:ro
    networks:
      - internal
    restart: unless-stopped

networks:
  internal:
```

On the remote server, use Nginx to proxy `https://pma.example.com` → `localhost:8080`.

### 2. Remote Access to MySQL

Securely allow external applications to access a local MySQL instance.

```yaml
environment:
  - REMOTE_BIND_PORT=3307
  - TARGET_HOST=mysql
  - TARGET_PORT=3306
```

Cloud app connects to `localhost:3307` on remote host → traffic forwarded securely.

---

## 🧰 Advanced Configuration

### Autossh Options

The following `autossh` environment variables are preconfigured:

```sh
AUTOSSH_POLL=30
AUTOSSH_FIRST_POLL=10
AUTOSSH_GATETIME=20
AUTOSSH_LOGLEVEL=7
AUTOSSH_LOGFILE=/proc/1/fd/1
```

You can override them via additional environment variables if needed.

### Custom ProxyCommand (Advanced)

If you need custom TLS logic (e.g., certificate pinning), you can provide your own `ProxyCommand` wrapper.

Override the SSH options by extending the image or bind-mounting a custom script.

---

## 📄 Logging & Monitoring

Logs are written directly to stdout and include:

- Startup validation
- Connection attempts
- `autossh` lifecycle messages

View logs with:

```bash
docker logs -f autossh-tls
```

Expected output on success:

```
🚀 autossh-tls: Starting validation
✅ All required config validated
🔄 Starting autossh: tunnel@c.example.com:443 → mysql:3306 (remote bind: 3306)
autossh[12]: starting ssh (count 1)
```

---

## 🧩 Building Locally

To build the image from source:

```bash
git clone https://github.com/NopeNix/autossh-tls.git
cd autossh-tls
docker build -t nopenix/autossh-tls:local .
```

Then use `image: nopenix/autossh-tls:local` in your compose file.

---

## 🛡️ Security Notes

- Only key-based authentication is supported.
- The container disables password and keyboard-interactive auth.
- `StrictHostKeyChecking=yes` prevents MITM attacks.
- All connections are double-encrypted: TLS + SSH.
- The container runs as `root`, but only to access `/root/.ssh`; no privilege escalation occurs.

> 🔐 **Best Practice**: Restrict the SSH user on the remote side using `authorized_keys` with `command=` and `no-agent-forwarding`, etc.

---

## 🤝 Contributing

Issues and pull requests are welcome. Please:
- Keep code clean
- Comment complex parts
- Test changes thoroughly

No drama. Just useful improvements.

---

## 📜 License

MIT — see [LICENSE](LICENSE) for details.

Copyright (c) 2025 Phil