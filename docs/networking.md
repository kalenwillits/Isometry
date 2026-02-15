# Network Security and Advanced Networking

Comprehensive guide to Isometry networking, security, and advanced deployment scenarios.

## Table of Contents

- [Network Architecture](#network-architecture)
- [Authentication System](#authentication-system)
- [Campaign Checksum Validation](#campaign-checksum-validation)
- [Server Operator Responsibilities](#server-operator-responsibilities)
- [Security Best Practices](#security-best-practices)
- [Advanced Networking](#advanced-networking)

## Network Architecture

### Client-Server Model

Isometry uses an **authoritative server** architecture:

```
┌─────────┐         ┌─────────┐         ┌─────────┐
│ Client  │◄───────►│ Server  │◄───────►│ Client  │
│ (peer 2)│         │ (peer 1)│         │ (peer 3)│
└─────────┘         └─────────┘         └─────────┘
                         │
                         ▼
                    ┌─────────┐
                    │ Client  │
                    │ (peer 4)│
                    └─────────┘
```

**Key Points:**
- Server has peer ID **1**
- Clients have peer IDs **2+**
- NPCs have negative peer IDs (-1 to -9,999,999)
- All game state is authoritative on the server
- Clients send requests via RPC
- Server validates and broadcasts changes

### Network Protocol

**ENet (UDP-based):**
- Reliable, ordered UDP transport
- Lower latency than TCP
- Built-in packet fragmentation
- Connection management
- Sequencing and acknowledgment

**Port Configuration:**
- Default port: **5000**
- Protocol: **UDP** (not TCP)
- Configurable via `--port` argument

### Network Modes

| Mode | Value | Description |
|------|-------|-------------|
| **NONE** | 0 | Single-player offline mode |
| **HOST** | 1 | Play + host (peer ID 1 is player) |
| **SERVER** | 2 | Dedicated server (headless) |
| **CLIENT** | 3 | Connect to host/server |

Modes can be specified as integers or strings:
```bash
--network=none   # or --network=0
--network=host   # or --network=1
--network=server # or --network=2
--network=client # or --network=3
```

Abbreviations also work: `n`, `h`, `s`, `c`

## Authentication System

### RSA Encryption

Isometry uses **2048-bit RSA encryption** for authentication:

**Key Generation:**
- Server generates RSA keypair on first launch
- Private key: `<executable_dir>/.rsa/private.key`
- Public key: `<executable_dir>/.rsa/public.pub`
- Keys persist across server restarts

**Authentication Flow:**

```
Client                          Server
  │                               │
  │──── Request Public Key ──────►│
  │                               │
  │◄─── Send Public Key ─────────│
  │                               │
  │ (Encrypt credentials         │
  │  with public key)             │
  │                               │
  │──── Encrypted Token ─────────►│
  │                               │
  │                  (Decrypt with private key)
  │                  (Validate credentials)
  │                  (Load/create player data)
  │                               │
  │◄─── Spawn Actor ─────────────│
  │                               │
```

### Authentication Token

**Token Format:**
```
username.password.campaign_checksum
```

**Example:**
```
player1.secret123.a3f8d9e2b1c4...
```

**Encryption:**
1. Client builds token string
2. Client encrypts with server's public RSA key
3. Client sends encrypted token as `PackedByteArray`
4. Server decrypts with private RSA key
5. Server validates username, password, and checksum

### Credential Requirements

**Valid Characters:**
- Letters: `a-z`, `A-Z`
- Numbers: `0-9`
- Special: `_` (underscore), `-` (dash)

**Invalid Characters (will cause authentication to fail):**
```
< > : " / \ | ? * ~ ! @ # $ % ^ & ( ) = { } [ ] ; . `
```

**Best Practices:**
- Username: 3-20 characters, alphanumeric + underscore
- Password: 8+ characters, mix of letters and numbers
- Avoid special characters entirely

### User Management

**Isometry does NOT provide:**
- User database
- Registration system
- Password hashing
- Account management UI
- Permission system

**Server operators must:**
- Manually create username/password pairs
- Distribute credentials to players
- Keep a list of valid accounts
- Implement their own user management

**Example user list (server operator's notes):**
```
# Valid user accounts
player1:secret123
player2:password456
admin:supersecret789
```

### Player Data Storage

**Location:**
- Linux: `~/.local/share/isometry/data/`
- Windows: `C:\Users\Name\AppData\Roaming\isometry\data\`

**File Format:**
```
<hash>.json
```

**Hash Calculation:**
```
MD5(username + password)
```

**Save File Contents:**
```json
{
  "actor": "hero_warrior",
  "map": "dungeon_level_1",
  "location": {"x": 512, "y": 384},
  "resources": {
    "health": 85,
    "mana": 42,
    "gold": 1250
  },
  "discovery": {
    "waypoints": ["town_square", "forest_entrance"],
    "maps": ["town", "forest"]
  }
}
```

**Security Note:** Save files are **not encrypted**. Server operators can read and modify player data.

## Campaign Checksum Validation

### Purpose

Ensures all clients and the server have **identical campaign files**. Even minor differences (1 byte) will cause mismatches.

### Checksum Calculation

**Algorithm:** SHA-256 hash of campaign ZIP file

```gdscript
# Pseudocode
var file = FileAccess.open("campaign.zip", FileAccess.READ)
var bytes = file.get_buffer(file.get_length())
var hash = bytes.sha256_text()
# hash = "a3f8d9e2b1c4f5a6d7e8f9a0b1c2d3e4..."
```

### Validation Flow

```
Client                          Server
  │                               │
  │ Calculate campaign checksum   │
  │ checksum = sha256(ZIP)        │
  │                               │
  │──── Token (includes hash) ───►│
  │                               │
  │           (Server compares checksums)
  │           if client_hash != server_hash:
  │               send campaign_mismatch()
  │                               │
  │◄─── Campaign Mismatch ───────│
  │                               │
  │ (Disconnect and show error)   │
  │                               │
```

### Mismatch Causes

**Different campaign versions:**
- Server updated campaign, client didn't
- Client modified campaign JSON
- Different compression settings

**Corrupted files:**
- Partial download
- Filesystem corruption
- Transfer errors

**Resolution:**
1. Delete client's campaign ZIP
2. Download fresh copy from server operator
3. Verify file integrity
4. Reconnect

## Server Operator Responsibilities

### Network Security is Your Responsibility

**Isometry Framework provides:**
- ✅ RSA encryption for credentials
- ✅ Campaign checksum validation
- ✅ Basic authentication

**Isometry Framework does NOT provide:**
- ❌ DDoS protection
- ❌ Rate limiting
- ❌ IP banning
- ❌ Intrusion detection
- ❌ Encrypted game state
- ❌ Cheat prevention
- ❌ Audit logging

### Your Responsibilities

As a server operator, you must:

1. **Secure your server infrastructure**
   - Keep OS and dependencies updated
   - Use firewall rules
   - Monitor for attacks
   - Implement rate limiting (if needed)

2. **Manage user accounts**
   - Create strong passwords
   - Revoke access for banned players
   - Keep credentials confidential

3. **Protect player data**
   - Backup save files
   - Don't share player data
   - Comply with privacy laws (GDPR, etc.)

4. **Monitor and moderate**
   - Watch for abuse
   - Enforce server rules
   - Handle disputes

5. **Maintain campaign integrity**
   - Keep campaigns updated
   - Validate campaigns before deployment
   - Test changes before going live

### Legal Considerations

**Privacy:**
- Player data may be subject to GDPR (EU), CCPA (California), or other laws
- You may need a privacy policy
- Players may request data deletion

**Terms of Service:**
- Consider a TOS for your server
- Specify acceptable use policies
- Define consequences for violations

**Liability:**
- Server operators may be liable for data breaches
- Consider insurance or legal consultation
- Document your security practices

**Disclaimer:** This is not legal advice. Consult a lawyer for your jurisdiction.

## Security Best Practices

### Server Hardening

**1. Operating System:**
```bash
# Keep system updated
sudo apt update && sudo apt upgrade

# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Disable root login
sudo vi /etc/ssh/sshd_config
# Set: PermitRootLogin no
sudo systemctl restart sshd
```

**2. Firewall:**
```bash
# Allow only necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 5000/udp  # Isometry server
sudo ufw enable

# Limit SSH login attempts
sudo ufw limit ssh
```

**3. Dedicated User:**
```bash
# Create isometry user (no login)
sudo useradd -r -s /bin/false isometry

# Set ownership
sudo chown -R isometry:isometry /opt/isometry

# Run server as isometry user
sudo -u isometry /opt/isometry/isometry --network=server ...
```

**4. Monitoring:**
```bash
# Install fail2ban for brute-force protection
sudo apt install fail2ban

# Monitor logs
sudo journalctl -u isometry-server -f

# Set up alerts (example with email)
# Configure system to email on errors
```

### Password Security

**Strong Passwords:**
- Minimum 12 characters
- Mix of uppercase, lowercase, numbers
- Avoid dictionary words
- Use a password generator

**Example good passwords:**
```
xK9mP3nQ7vL2wR8t
FalconSword2025Blue
8Mountain!Dragon$5
```

**Don't:**
- Reuse passwords across accounts
- Share passwords in plain text
- Store passwords unencrypted
- Use simple passwords like "password123"

### Network Security

**1. Rate Limiting:**

Isometry doesn't include rate limiting. Consider using a proxy or firewall:

```bash
# iptables example (limit connections per IP)
sudo iptables -A INPUT -p udp --dport 5000 -m state --state NEW -m recent --set
sudo iptables -A INPUT -p udp --dport 5000 -m state --state NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
```

**2. VPN/Private Network:**

For private servers, use VPN:

```bash
# WireGuard example
# Players connect via VPN, server only accepts VPN traffic
sudo ufw allow from 10.0.0.0/24 to any port 5000
```

**3. Reverse Proxy:**

Consider a UDP reverse proxy with:
- Connection limiting
- IP whitelisting/blacklisting
- DDoS mitigation
- Logging

### Backup Strategy

**What to backup:**
1. Campaign ZIP files
2. Player save files (`data/*.json`)
3. RSA keys (`.rsa/`)
4. Server configuration
5. Logs (for forensics)

**Backup frequency:**
- **Critical data (saves):** Hourly
- **Campaign files:** On change
- **RSA keys:** Once (or on regeneration)
- **Logs:** Daily rotation

**Backup script:**
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/isometry/$DATE"
mkdir -p "$BACKUP_DIR"

# Backup player data
cp -r ~/.local/share/isometry/data "$BACKUP_DIR/"

# Backup campaigns
cp campaigns/*.zip "$BACKUP_DIR/"

# Backup keys
cp -r ~/.local/share/isometry/.rsa "$BACKUP_DIR/"

# Compress
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

# Keep only last 30 days
find /backup/isometry -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR.tar.gz"
```

**Automate with cron:**
```bash
# Edit crontab
crontab -e

# Add hourly backup
0 * * * * /opt/isometry/backup.sh
```

### Incident Response

**If you suspect a breach:**

1. **Immediately:**
   - Stop the server
   - Disconnect from network
   - Document everything

2. **Investigate:**
   - Check logs for suspicious activity
   - Review player save files for tampering
   - Check for unauthorized access

3. **Remediate:**
   - Reset all passwords
   - Regenerate RSA keys (forces all reconnections)
   - Restore from clean backup
   - Update and patch systems

4. **Notify:**
   - Inform affected players
   - Document the incident
   - Comply with legal requirements

## Advanced Networking

### Cloud Deployment

#### AWS EC2 Example

**1. Launch EC2 Instance:**
- **AMI:** Ubuntu Server 22.04 LTS
- **Instance Type:** t3.medium (2 vCPU, 4 GB RAM)
- **Storage:** 20 GB EBS

**2. Configure Security Group:**

| Type | Protocol | Port | Source |
|------|----------|------|--------|
| SSH | TCP | 22 | Your IP |
| Custom UDP | UDP | 5000 | 0.0.0.0/0 |

**3. Install Isometry:**

```bash
# SSH to instance
ssh -i key.pem ubuntu@ec2-xx-xx-xx-xx.compute.amazonaws.com

# Install dependencies (adjust for your build)
sudo apt update
sudo apt install -y libgl1-mesa-glx libxcursor1 libxinerama1 libxrandr2

# Upload Isometry
scp -i key.pem isometry ubuntu@ec2-xx-xx-xx-xx:~/

# Upload campaign
scp -i key.pem campaign.zip ubuntu@ec2-xx-xx-xx-xx:~/

# Make executable
chmod +x isometry

# Run server
./isometry --campaign=mycampaign --network=server --port=5000 --username=server --password=pass
```

**4. Use Elastic IP:**
- Allocate Elastic IP
- Associate with instance
- Provide this IP to players

#### DigitalOcean Droplet Example

**1. Create Droplet:**
- **Distribution:** Ubuntu 22.04 x64
- **Plan:** Basic ($12/mo - 2 GB RAM)
- **Region:** Choose nearest to players

**2. Add Firewall Rule:**
```bash
# Allow Isometry UDP traffic
sudo ufw allow 5000/udp
sudo ufw enable
```

**3. Deploy:**
```bash
# Upload files
scp isometry root@droplet-ip:~/
scp campaign.zip root@droplet-ip:~/

# SSH and run
ssh root@droplet-ip
./isometry --campaign=mycampaign --network=server --port=5000 --username=server --password=pass
```

### External Authentication Server

**Concept:** Separate authentication service from game server

```
┌─────────┐                    ┌─────────────┐
│ Client  │───── Auth ────────►│ Auth Server │
└─────────┘                    └─────────────┘
     │                                │
     │                          (Validate user)
     │                          (Issue token)
     │                                │
     │◄─────── Token ────────────────┘
     │
     │
     │ Token                    ┌─────────────┐
     └───────────────────────►  │ Game Server │
                                └─────────────┘
                                 (Verify token)
                                 (Spawn player)
```

**Implementation Notes:**

Isometry doesn't natively support external auth, but you could modify the authentication flow:

1. **Auth Server** (separate service):
   - REST API for login
   - Issues JWT tokens
   - Validates username/password against database
   - Logs authentication attempts

2. **Modified Isometry Server:**
   - Accept JWT token instead of password
   - Validate token signature
   - Extract username from token
   - Proceed with spawn

3. **Benefits:**
   - Centralized user database
   - Better security (no passwords sent to game server)
   - Account management UI
   - Multi-server support (one auth for many game servers)

**Example Architecture:**

```
Player
  │
  ├── HTTPS POST /login ────►┌─────────────┐
  │   {username, password}   │ Auth Server │
  │                          │ (Node.js)   │
  │◄────── JWT token ────────└─────────────┘
  │                                │
  │                          (PostgreSQL)
  │                          (User accounts)
  │
  ├── UDP (game traffic) ───►┌─────────────┐
  │   JWT in auth packet     │ Game Server │
  │                          │ (Isometry)     │
  │◄────── Game state ───────└─────────────┘
```

**This requires modifying Isometry source code** to implement custom authentication.

### Load Balancing

For very large deployments (100+ concurrent players):

```
              ┌─────────────┐
Players ─────►│  Nginx UDP  │
              │   Proxy     │
              └─────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
    ┌────▼───┐  ┌───▼────┐  ┌───▼────┐
    │Server 1│  │Server 2│  │Server 3│
    └────────┘  └────────┘  └────────┘
```

**Challenges:**
- Players on different servers can't interact
- Load balancing UDP is complex
- Campaign state isn't shared between servers

**Better approach:** Horizontal scaling per campaign/shard

```
Campaign A ────►┌─────────┐
                │ Server 1│
                └─────────┘

Campaign B ────►┌─────────┐
                │ Server 2│
                └─────────┘

Campaign C ────►┌─────────┐
                │ Server 3│
                └─────────┘
```

### DDoS Protection

**Isometry is vulnerable to UDP flood attacks.** Mitigation options:

**1. Cloud Provider DDoS Protection:**
- AWS Shield
- Cloudflare Spectrum (UDP support)
- DigitalOcean DDoS protection

**2. iptables Rate Limiting:**
```bash
# Limit new connections
sudo iptables -A INPUT -p udp --dport 5000 -m state --state NEW -m recent --name isometry --set
sudo iptables -A INPUT -p udp --dport 5000 -m state --state NEW -m recent --name isometry --update --seconds 10 --hitcount 5 -j DROP
```

**3. fail2ban:**
```bash
# Create fail2ban filter for Isometry
# Monitors logs and bans IPs with too many failed auths
```

**4. VPN or Whitelist:**
```bash
# Only accept traffic from known IPs
sudo ufw default deny incoming
sudo ufw allow from 1.2.3.4 to any port 5000
sudo ufw allow from 5.6.7.8 to any port 5000
```

### Monitoring and Observability

**Metrics to track:**
- **Player count** - Active connections
- **CPU usage** - Server load
- **Memory usage** - Potential leaks
- **Network traffic** - Bandwidth usage
- **Authentication attempts** - Failed logins
- **Errors** - Server crashes or exceptions

**Tools:**

**1. Prometheus + Grafana:**
```bash
# Export metrics from Isometry logs
# Visualize in Grafana dashboards
```

**2. CloudWatch (AWS):**
```bash
# Monitor EC2 metrics
# Set alarms for high CPU/memory
```

**3. Custom monitoring:**
```bash
# Parse logs and send to monitoring service
tail -f isometry.log | grep "Player connected" | wc -l
```

## Network Troubleshooting

### Connection Issues

**Can't connect to server:**

1. Verify server is running:
   ```bash
   sudo netstat -ulnp | grep 5000
   ```

2. Test connectivity:
   ```bash
   # Client side
   nc -u SERVER_IP 5000
   # Type anything, press Enter
   # If you see it echo back, UDP is working
   ```

3. Check firewall:
   ```bash
   sudo ufw status
   sudo iptables -L -n -v
   ```

4. Verify port forwarding (if behind router)

### Authentication Issues

**"Authentication failed":**

1. Check credentials don't have invalid characters
2. Verify server logs for specific error
3. Ensure campaign checksum matches

**"Campaign mismatch":**

1. Delete client campaign ZIP
2. Download exact copy from server operator
3. Verify SHA-256 hash matches server's

### Performance Issues

**High latency:**

1. Check network ping:
   ```bash
   ping SERVER_IP
   ```

2. Use server geographically close to players
3. Check for bandwidth saturation
4. Reduce action frequency in campaign

**Packet loss:**

1. ENet handles some packet loss automatically
2. Check for network congestion
3. Consider UDP QoS settings
4. Test with different server location

---

**Next:** [Campaign Creation](campaign-basics.md) | [Back to Hosting](hosting.md) | [Back to Home](README.md)
