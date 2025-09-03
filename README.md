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

- 🔒 **Secure**: Uses OpenSSL to establish TLS connection with SNI routing before initiating SSH
- 🔄 **Persistent**: Automatically reconnects using `autossh` if the tunnel drops
- ⚙️ **Configurable**: All settings via environment variables
- 📦 **Lightweight**: Based on Alpine Linux (minimal footprint)
- 🔄 **Flexible**: Support for both reverse and forward tunnels
---

## 🐳 Usage

### Environment Variables

| Variable | Description | Required |
|---------|-------------|----------|
| `SSH_HOST` | Remote SSH server hostname | ✅ |
| `SSH_PORT` | Remote SSH server port (typically 443) | ✅ |
| `SNI_HOST` | SNI hostname for TLS routing | ✅ |
| `SSH_USER` | SSH username for authentication | ✅ |
| `SSH_KEY_FILE` | Path to private SSH key file | ✅ |
| `REMOTE_BIND_PORT` | Port to bind on the remote SSH server (reverse) or local port (forward) | ✅ |
| `TARGET_HOST` | Hostname of the service to tunnel to | ✅ |
| `TARGET_PORT` | Port of the service to tunnel to | ✅ |
| `TUNNEL_DIRECTION` | Direction of tunnel (`reverse` or `forward`) - defaults to `reverse` | |

### Docker Compose Example (Reverse Tunnel)
```yaml
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
      # Default is reverse tunnel, but you can be explicit:
      - TUNNEL_DIRECTION=reverse
    volumes:
      - ./ssh:/root/.ssh:ro
    restart: unless-stopped
```

### Docker Compose Example (Forward Tunnel)
```yaml
services:
  autossh-tls-forward:
    image: nopenix/autossh-tls:latest
    environment:
      - SSH_HOST=c.example.com
      - SSH_PORT=443
      - SNI_HOST=tunnel-mysql.example.com
      - SSH_USER=tunnel
      - SSH_KEY_FILE=/root/.ssh/id_rsa
      - REMOTE_BIND_PORT=3306  # Local port to bind
      - TARGET_HOST=mysql.internal
      - TARGET_PORT=3306
      - TUNNEL_DIRECTION=forward
    volumes:
      - ./ssh:/root/.ssh:ro
    ports:
      - "3306:3306"  # Expose the local port
    restart: unless-stopped
```

---

## 🛠️ How It Works

### Reverse Tunnel Mode (Default)
In reverse tunnel mode, connections to `REMOTE_BIND_PORT` on the SSH server are forwarded to `TARGET_HOST:TARGET_PORT` in the docker container's network.

This is useful for exposing internal services to external clients through the SSH server.

### Forward Tunnel Mode
In forward tunnel mode, connections to `REMOTE_BIND_PORT` on the local machine (where the container runs) are forwarded to `TARGET_HOST:TARGET_PORT` accessible from the SSH server's network.

This is useful for accessing services in the SSH server's network from the local environment.
---

## 🔐 Security Notes

- Ensure your SSH private key has strict permissions (600)
- The container expects a properly populated `known_hosts` file to prevent MITM attacks
- Traffic between the SSH client and server is encrypted with SSH
- Initial connection is wrapped in TLS with SNI routing for environments where SSH directly is blocked

To generate the required `known_hosts` file:
```bash
ssh-keyscan -p $SSH_PORT $SSH_HOST >> known_hosts
```

```

Let me know if you'd like the README expanded with more examples, usage notes, or tailored for specific environments like Kubernetes!

