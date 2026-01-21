---
name: raspi-server
description: Use this skill when the user asks about their Raspberry Pi server - managing torrents with Transmission, checking services, IPTV proxy, SSH access, Docker containers, or any server administration tasks on the Pi.
---

# Raspberry Pi Server Management

## Connection Details

- **Hostname**: `raspi`
- **IP Address**: `192.168.178.49`
- **User**: `pietz`
- **Password**: `tlp`

### SSH Connection

Always use `sshpass` to connect non-interactively:

```bash
sshpass -p 'tlp' ssh pietz@raspi "<command>"
```

For multiple commands, chain them or use a here-document.

---

## Services Running

### 1. Transmission BitTorrent Client

**Status**: Runs as systemd service, auto-starts on boot

| Property | Value |
|----------|-------|
| Service | `transmission-daemon.service` |
| Web UI | `http://192.168.178.49:9091/transmission/` |
| Username | `pietz` |
| Password | `tlp` |
| Downloads Dir | `/var/lib/transmission-daemon/downloads` |
| Peer Port | `51413` |
| Config File | `/etc/transmission-daemon/settings.json` |

**Common Commands:**

```bash
# Check status
sshpass -p 'tlp' ssh pietz@raspi "systemctl status transmission-daemon"

# Restart service
sshpass -p 'tlp' ssh pietz@raspi "sudo systemctl restart transmission-daemon"

# List downloads
sshpass -p 'tlp' ssh pietz@raspi "ls -la /var/lib/transmission-daemon/downloads"

# View active torrents (requires transmission-remote)
sshpass -p 'tlp' ssh pietz@raspi "transmission-remote -n pietz:tlp -l"
```

### 2. IPTV Proxy (Docker Container)

**Status**: Docker container with `unless-stopped` restart policy (auto-starts on boot)

| Property | Value |
|----------|-------|
| Container Name | `tvproxy` |
| Image | `stubenrein.org:63444/tvproxy` |
| Port | `64321` |
| URL | `http://192.168.178.49:64321` |
| Restart Policy | `unless-stopped` |

**Common Commands:**

```bash
# Check container status
sshpass -p 'tlp' ssh pietz@raspi "docker ps -a --filter name=tvproxy"

# View container logs
sshpass -p 'tlp' ssh pietz@raspi "docker logs tvproxy --tail 50"

# Restart container
sshpass -p 'tlp' ssh pietz@raspi "docker restart tvproxy"

# Stop container
sshpass -p 'tlp' ssh pietz@raspi "docker stop tvproxy"

# Start container
sshpass -p 'tlp' ssh pietz@raspi "docker start tvproxy"
```

---

## System Information

| Property | Value |
|----------|-------|
| Model | Raspberry Pi 4 Model B Rev 1.1 |
| RAM | 4 GB |
| Storage | 234 GB SD card |
| OS | Debian 12 (Bookworm) |
| Architecture | aarch64 (64-bit ARM) |

**System Commands:**

```bash
# Check system resources
sshpass -p 'tlp' ssh pietz@raspi "free -h && df -h"

# Check running services
sshpass -p 'tlp' ssh pietz@raspi "systemctl list-units --type=service --state=running"

# Check uptime and load
sshpass -p 'tlp' ssh pietz@raspi "uptime"

# Reboot the Pi (use with caution)
sshpass -p 'tlp' ssh pietz@raspi "sudo reboot"

# Shutdown the Pi (use with caution)
sshpass -p 'tlp' ssh pietz@raspi "sudo shutdown -h now"
```

---

## Quick Reference

| Service | URL | Credentials |
|---------|-----|-------------|
| SSH | `ssh pietz@raspi` | pw: `tlp` |
| Transmission Web UI | `http://192.168.178.49:9091/transmission/` | pietz / tlp |
| IPTV Proxy | `http://192.168.178.49:64321` | - |

---

## Troubleshooting

### If Transmission is not responding:
```bash
sshpass -p 'tlp' ssh pietz@raspi "sudo systemctl restart transmission-daemon && systemctl status transmission-daemon"
```

### If IPTV Proxy is down:
```bash
sshpass -p 'tlp' ssh pietz@raspi "docker restart tvproxy && docker ps"
```

### If Pi is unreachable:
- Check if it's powered on
- Verify network connectivity
- Try pinging: `ping raspi` or `ping 192.168.178.49`
