# Hosting & Networking

## Network Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `host` | Server + local client | Solo or small groups |
| `server` | Dedicated server only | Always-on multiplayer |
| `client` | Connect to a server | Join existing game |
| `none` | No networking | Offline testing |

## Host Mode

Host mode starts a server and connects a local player automatically. This is the simplest way to play with friends.

```bash
./isometry_linux.x86_64 --campaign=demo --network=host \
  --port=5000 --username=host_player --password=secret
```

Other players connect as clients to your IP address.

## Dedicated Server

For always-on multiplayer, run a dedicated server:

```bash
./isometry_linux.x86_64 --campaign=demo --network=server \
  --port=5000 --username=server --password=adminpass
```

### Server Deployment

#### Systemd Service

```ini
[Unit]
Description=Isometry Game Server
After=network.target

[Service]
Type=simple
User=isometry
ExecStart=/opt/isometry/isometry_linux.x86_64 \
  --campaign=demo --network=server --port=5000 \
  --username=server --password=secret
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Port Configuration

- Default port: **5000** (UDP)
- Port range: 1024-65535
- Protocol: **ENet over UDP** (not TCP)
- Forward UDP traffic on your router/firewall

### Security

- RSA keypairs are generated on first server launch (stored in `.rsa/`)
- Client passwords are encrypted during transmission
- Campaign checksums prevent version mismatches between server and clients
- Maximum clients configurable (default: 4095)
