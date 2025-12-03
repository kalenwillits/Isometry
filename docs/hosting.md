# Hosting Multiplayer Games

Guide to hosting Isometry multiplayer games using Host or Server mode.

## Table of Contents

- [Host Mode vs Server Mode](#host-mode-vs-server-mode)
- [Starting a Host](#starting-a-host)
- [Starting a Dedicated Server](#starting-a-dedicated-server)
- [Port Forwarding and Firewall](#port-forwarding-and-firewall)
- [Player Management](#player-management)
- [Server Configuration](#server-configuration)

## Host Mode vs Server Mode

Isometry provides two ways to run multiplayer games:

| Feature | Host Mode | Server Mode |
|---------|-----------|-------------|
| **Play while hosting** | ✅ Yes | ❌ No (headless) |
| **Peer ID** | 1 (server + player) | 1 (server only) |
| **Resource usage** | Higher (rendering + server) | Lower (no rendering) |
| **Best for** | Small groups, casual play | Dedicated servers, many players |
| **Window** | Game window visible | No window (headless) |

### When to Use Host Mode

Use `--network=host` when:
- Playing with friends (2-10 players)
- You want to play along with your guests
- Running a temporary game session
- Testing campaigns in multiplayer

### When to Use Server Mode

Use `--network=server` when:
- Running a 24/7 dedicated server
- Hosting many players (10+ concurrent)
- Running on a VPS or cloud server
- You don't need to play yourself
- Maximizing performance

## Starting a Host

### Basic Host Command

```bash
./atlas --campaign=mycampaign \
  --network=host \
  --port=5000 \
  --username=admin \
  --password=adminpass
```

**Parameters:**
- `--network=host` or `--network=1` - Launch in host mode
- `--port=5000` - Port to listen on (default: 5000)
- `--username=admin` - Your username for authentication
- `--password=adminpass` - Your password for authentication

### Host Example

```bash
# Host a campaign called "dungeon_crawl"
./atlas --campaign=dungeon_crawl \
  --network=host \
  --port=7777 \
  --username=dungeon_master \
  --password=secret123

Host started on port 7777
Your character: dungeon_master
Campaign: dungeon_crawl
Waiting for players...
```

### How Players Connect to Your Host

Players use client mode to connect:

```bash
./atlas --campaign=dungeon_crawl \
  --network=client \
  --uri=your.ip.address \
  --port=7777 \
  --username=player1 \
  --password=player1pass
```

**You must provide:**
- Your public IP address (find at whatismyip.com)
- The port number
- Campaign ZIP file (identical to yours)
- User credentials (you manage these)

## Starting a Dedicated Server

### Basic Server Command

```bash
./atlas --campaign=mycampaign \
  --network=server \
  --port=5000 \
  --username=server \
  --password=serverpass
```

**Parameters:**
- `--network=server` or `--network=2` - Launch in server mode
- `--port=5000` - Port to listen on
- `--username=server` - Server operator username
- `--password=serverpass` - Server operator password

### Dedicated Server Example

```bash
# Run dedicated server for "epic_campaign"
./atlas --campaign=epic_campaign \
  --network=server \
  --port=5000 \
  --username=server_admin \
  --password=supersecret

Dedicated server started
Port: 5000
Campaign: epic_campaign (checksum: a3f8d9...)
Max clients: 4095
Waiting for connections...
```

### Running as a Background Process

**Linux (using nohup):**

```bash
nohup ./atlas --campaign=mycampaign \
  --network=server \
  --port=5000 \
  --username=server \
  --password=pass \
  > server.log 2>&1 &

# Check it's running
ps aux | grep atlas

# View logs
tail -f server.log

# Stop server
pkill atlas
```

**Linux (using screen):**

```bash
# Start a screen session
screen -S atlas-server

# Run the server
./atlas --campaign=mycampaign --network=server --port=5000 --username=server --password=pass

# Detach: Ctrl+A, then D

# Reattach later
screen -r atlas-server

# Kill the screen
screen -X -S atlas-server quit
```

### Systemd Service (Linux)

Create `/etc/systemd/system/atlas-server.service`:

```ini
[Unit]
Description=Isometry RPG Server
After=network.target

[Service]
Type=simple
User=atlas
WorkingDirectory=/opt/atlas
ExecStart=/opt/atlas/atlas \
  --campaign=mycampaign \
  --network=server \
  --port=5000 \
  --username=server \
  --password=CHANGE_ME \
  --log-level=info
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Enable and start:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable atlas-server
sudo systemctl start atlas-server
sudo systemctl status atlas-server

# View logs
sudo journalctl -u atlas-server -f
```

### Docker Deployment (Advanced)

Example `Dockerfile`:

```dockerfile
FROM ubuntu:22.04

# Install dependencies (adjust for your build)
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    && rm -rf /var/lib/apt/lists/*

# Copy Isometry executable and campaigns
COPY atlas /opt/atlas/atlas
COPY campaigns/ /opt/atlas/campaigns/

WORKDIR /opt/atlas
EXPOSE 5000/udp

CMD ["./atlas", \
     "--campaign=${CAMPAIGN}", \
     "--network=server", \
     "--port=5000", \
     "--username=${USERNAME}", \
     "--password=${PASSWORD}"]
```

**Build and run:**

```bash
docker build -t atlas-server .

docker run -d \
  --name atlas \
  -p 5000:5000/udp \
  -e CAMPAIGN=mycampaign \
  -e USERNAME=server \
  -e PASSWORD=secret \
  atlas-server

# View logs
docker logs -f atlas

# Stop
docker stop atlas
```

## Port Forwarding and Firewall

### Port Forwarding (Home Router)

To host from home, configure port forwarding on your router:

1. **Find your local IP:**
   ```bash
   # Linux/Mac
   ip addr show
   # or
   ifconfig

   # Windows
   ipconfig
   ```
   Look for `192.168.x.x` or `10.0.x.x`

2. **Access your router:**
   - Visit `192.168.1.1` or `192.168.0.1` in a browser
   - Login with admin credentials

3. **Add port forwarding rule:**
   - **Service Name:** Isometry Server
   - **External Port:** 5000 (or your chosen port)
   - **Internal IP:** Your computer's local IP
   - **Internal Port:** 5000 (same as external)
   - **Protocol:** UDP (Isometry uses ENet over UDP)

4. **Find your public IP:**
   - Visit whatismyip.com
   - Give this IP to players

### Firewall Configuration

**Linux (ufw):**

```bash
# Allow UDP port 5000
sudo ufw allow 5000/udp

# Verify
sudo ufw status
```

**Linux (firewalld):**

```bash
# Allow UDP port 5000
sudo firewall-cmd --permanent --add-port=5000/udp
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-ports
```

**Windows Firewall:**

1. Open **Windows Defender Firewall**
2. Click **Advanced settings**
3. **Inbound Rules** → **New Rule**
4. **Port** → **Next**
5. **UDP**, **Specific ports: 5000** → **Next**
6. **Allow the connection** → **Next**
7. Apply to all profiles → **Next**
8. Name: "Isometry Server" → **Finish**

**Cloud Servers (AWS, DigitalOcean, etc.):**

Configure security groups to allow inbound UDP traffic on your port:

```bash
# AWS Security Group
# Add inbound rule: UDP, Port 5000, Source: 0.0.0.0/0

# DigitalOcean Firewall
# Inbound: UDP, Port 5000, All sources
```

## Player Management

### Authentication and User Accounts

Isometry doesn't include a built-in user database. As a server operator, you:

1. **Provide credentials to players**
   - Create username/password pairs
   - Share them securely with players
   - Keep a list of valid accounts

2. **Player data storage**
   - Player saves are stored in `data/<hash>.json`
   - Hash is based on username + password
   - Each player's progress is saved separately

3. **Revoking access**
   - Change the player's password
   - Remove their save file
   - Restart the server

### Player Capacity

**Default:** 4095 maximum concurrent players

**Practical limits:**
- **Host mode:** 2-10 players (depends on your hardware)
- **Server mode:** 10-100 players (depends on server specs and campaign complexity)

**Factors affecting capacity:**
- Number of NPCs on active maps
- Action complexity (AoE actions, triggers, timers)
- Network bandwidth
- Server CPU and RAM

### Monitoring Players

**Via logs:**

Enable trace logging to see connection events:

```bash
./atlas --campaign=mycampaign --network=server --log-level=trace
```

Log messages include:
- Player connections
- Authentication attempts
- Player spawns
- Disconnections
- Map transitions

**In-game (Host mode only):**

As the host (peer ID 1), you can see all connected players:
- Check the player list (implementation depends on campaign)
- Use `/public` chat to broadcast messages
- Monitor resource changes

## Server Configuration

### Command-Line Options

```bash
./atlas \
  --campaign=CAMPAIGN_NAME \     # Required: Campaign to load
  --network=server \              # Required: Server mode (or "2")
  --port=5000 \                   # Optional: Port (default 5000)
  --username=USERNAME \           # Required: Your username
  --password=PASSWORD \           # Required: Your password
  --log-level=info \              # Optional: trace|debug|info|warn|error
  --dir=/path/to/campaigns        # Optional: Campaign directory
```

### Log Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `trace` | Extremely verbose | Debugging connection issues |
| `debug` | Detailed information | Development and testing |
| `info` | General information | Production (default) |
| `warn` | Warnings only | Production (quiet) |
| `error` | Errors only | Production (very quiet) |

### Campaign Directory

By default, Isometry looks for campaigns in:
- Same directory as executable
- `~/.local/share/atlas/campaigns/` (Linux)
- `C:\Users\Name\AppData\Roaming\atlas\campaigns\` (Windows)

Override with `--dir`:

```bash
./atlas --campaign=mycampaign --network=server --dir=/opt/atlas/campaigns
```

### Data Directory

Player saves and server data are stored in:
- Linux: `~/.local/share/atlas/data/`
- Windows: `C:\Users\Name\AppData\Roaming\atlas\data\`

**Files:**
- `<hash>.json` - Player save files
- `.rsa/private.key` - Server private key
- `.rsa/public.pub` - Server public key

### Backup and Recovery

**What to backup:**
1. Campaign ZIP files
2. Player save files (`data/*.json`)
3. RSA keys (`.rsa/`)

**Backup script example:**

```bash
#!/bin/bash
BACKUP_DIR="/backup/atlas/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup campaign
cp campaigns/*.zip "$BACKUP_DIR/"

# Backup player data
cp -r ~/.local/share/atlas/data "$BACKUP_DIR/"

# Backup RSA keys
cp -r ~/.local/share/atlas/.rsa "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
```

**Recovery:**

```bash
# Restore player data
cp -r /backup/atlas/20250115/data/* ~/.local/share/atlas/data/

# Restore RSA keys
cp -r /backup/atlas/20250115/.rsa ~/.local/share/atlas/

# Restart server
systemctl restart atlas-server
```

## Performance Optimization

### Server Hardware Recommendations

**Minimum (10 players):**
- CPU: 2 cores, 2.0 GHz
- RAM: 2 GB
- Network: 10 Mbps up/down

**Recommended (50 players):**
- CPU: 4 cores, 3.0 GHz
- RAM: 8 GB
- Network: 50 Mbps up/down

**High-end (100+ players):**
- CPU: 8+ cores, 3.5+ GHz
- RAM: 16+ GB
- Network: 100+ Mbps up/down

### Reducing Server Load

1. **Limit NPC count**
   - Reduce deployments in campaign JSON
   - Despawn inactive NPCs
   - Use NPC pooling strategies

2. **Optimize actions**
   - Avoid excessive AoE actions
   - Limit timer/trigger frequency
   - Simplify AI behaviors

3. **Reduce map complexity**
   - Smaller tilemaps
   - Fewer parallax layers
   - Optimize asset sizes

## Troubleshooting

### Server won't start

**Error: "Campaign not found"**
- Verify the campaign ZIP exists
- Check the `--dir` path
- Ensure permissions allow reading the ZIP

**Error: "Port already in use"**
- Another process is using the port
- Use `sudo lsof -i :5000` (Linux) to find it
- Choose a different port with `--port`

### Players can't connect

**Firewall blocking:**
- Verify UDP port is open
- Test with `nc -u -l 5000` (server) and `nc -u SERVER_IP 5000` (client)

**Port forwarding not working:**
- Verify router configuration
- Check internal IP hasn't changed (use DHCP reservation)
- Test from outside your network

**Authentication fails:**
- Check username/password are correct
- Verify no invalid characters
- Check server logs for details

### Server crashes

**Out of memory:**
- Reduce player count
- Simplify campaign (fewer NPCs, smaller maps)
- Increase server RAM

**Segmentation fault:**
- Report bug with `--log-level=trace` output
- Check campaign validation
- Try a different campaign to isolate issue

### Performance degradation

**High CPU usage:**
- Too many NPCs with AI behaviors
- Complex actions executing frequently
- Reduce timer intervals
- Simplify behavior conditions

**High memory usage:**
- Memory leak in campaign logic
- Too many actors spawned
- Check for circular action references
- Monitor with `htop` or `top`

## Security Best Practices

See the [Network Security](networking.md) guide for detailed security information.

**Quick tips:**
- Use strong passwords
- Don't share your private RSA key
- Keep server software updated
- Monitor logs for suspicious activity
- Backup regularly
- Use firewall rules to limit access

---

**Next:** [Network Security](networking.md) | [Campaign Creation](campaign-basics.md) | [Back to Home](README.md)
