# Arch Linux AgentVM

The Arch Linux implementation of Oligarchy AgentVM provides a rolling release system with pacman package manager and AUR access, while maintaining full feature parity with the NixOS version.

## Quick Start

### Prerequisites

- Nix (for running the build scripts) or direct script execution
- QEMU/KVM for virtualization
- Approximately 15GB disk space for VM image and ISO
- Internet connection for package downloads

### Installation

#### Method 1: Using Nix (Recommended)
```bash
# Clone the repository
git clone https://github.com/ALH477/Oligarchy-Agent-VM.git
cd Oligarchy-Agent-VM

# Build Arch Linux VM
nix run .#arch-build-vm

# Launch the VM
nix run .#arch-run

# In a separate terminal, connect via SSH
ssh agent@127.0.0.1 -p 2222
```

#### Method 2: Direct Script Execution
```bash
# Clone the repository
git clone https://github.com/ALH477/Oligarchy-Agent-VM.git
cd Oligarchy-Agent-VM/arch-vm

# Build and launch VM
chmod +x scripts/build-vm.sh
./scripts/build-vm.sh

# Follow the on-screen instructions
```

## System Comparison

| Feature | NixOS | Arch Linux |
|---------|---------|------------|
| **Package Manager** | Nix (declarative) | pacman + AUR (imperative) |
| **Release Model** | Controlled | Rolling (latest) |
| **Reproducibility** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Package Availability** | Good | Excellent (AUR) |
| **Setup Complexity** | Higher | Lower |
| **System Size** | Larger | Smaller |
| **Update Frequency** | Less frequent | Continuous |
| **Configuration** | Declarative | Scripts + config files |

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    Host System                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Framework Laptop (Core 0: Host work)         │   │
│  │  /home/user/projects ←────────────────────┐       │   │
│  └─────────────────────────────────────────────────────┘   │
│                         │ virtiofs (ro)              │
└─────────────────────────┼───────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────┐
│              Arch Linux AgentVM                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Cores 1-7 (isolated via boot parameters)     │   │
│  │  8GB RAM                                         │   │
│  │                                                     │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────┐ │ │
│  │  │ SSH Server   │  │ FastAPI      │  │ Agents  │ │ │
│  │  │ Port 22      │  │ Port 8000    │  │         │ │ │
│  │  │              │  │              │  │ aider   │ │ │
│  │  │              │  │              │  │ opencode│ │ │
│  │  │              │  │              │  │ claude  │ │ │
│  │  └──────────────┘  └──────────────┘  └─────────┘ │ │
│  │                                                     │   │
│  │  /home/agent/agent-env (Python venv)               │   │
│  │  /home/agent/ssh-recordings (asciinema)          │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         │                    │
         │ SSH :2222          │ HTTP :8000
         ▼                    ▼
    Terminal              Custom UI
```

## Package Management

### Pacam Configuration

```bash
# Update system packages
sudo pacman -Syu

# Update AUR packages
yay -Syu

# Search packages
pacman -Ss <package-name>     # Official repos
yay -Ss <package-name>          # AUR

# Install packages
sudo pacman -S <package-name>   # Official repos
yay -S <package-name>           # AUR

# Remove packages
sudo pacman -R <package-name>

# Clean package cache
sudo pacman -Scc
```

### Package Lists

The system supports three deployment modes:

#### minimal-ssh-only
```bash
# Core packages only
base, base-devel, python, tmux, podman
```

#### standard-ssh
```bash
# Core + Docker + dev tools
standard packages + docker, nodejs, npm, rust
```

#### full-gui
```bash
# Standard + GUI support
standard packages + xorg, wayland, gtk4, firefox
```

## Agent Ecosystem

### AI Agents

All agents are installed in `/home/agent/agent-env/` Python virtual environment:

#### Aider
```bash
# Installation
cd /home/agent
source agent-env/bin/activate
pip install "aider-chat>=0.38.1"

# Usage
aider --model claude-3-5-sonnet-20241022 --message "Add error handling"
```

#### OpenCode
```bash
# Installation
cd /home/agent
source agent-env/bin/activate
pip install "opencode>=0.1.0"

# Usage
opencode "Implement new feature"
```

#### Claude Code
```bash
# Installation (global)
npm install -g "@anthropic-ai/claude-code@0.7.0"

# Usage
claude "Review this code"
```

### API Service

The FastAPI controller provides the same endpoints as NixOS version:

#### Configuration
Environment variables in `/home/agent/agent-api/.env`:
```bash
AGENTVM_API_KEY=your-production-key
DEBUG=false
LOG_LEVEL=INFO
MAX_AGENTS=20
```

#### Service Management
```bash
# Start service
sudo systemctl start agent-api

# Enable on boot
sudo systemctl enable agent-api

# Check status
sudo systemctl status agent-api

# View logs
sudo journalctl -u agent-api -f
```

## System Services

### SSH with Tmux Wrapper

Each SSH connection gets a unique tmux session:

```bash
# Connect to VM
ssh agent@127.0.0.1 -p 2222

# Session naming format: ssh-agent-CLIENTIP-TIMESTAMP
# Recording enabled if TMUX_RECORD=true
```

### Recording Service

Automatic cleanup of old asciinema recordings:

```bash
# Service runs daily
systemctl list-timers cleanup-recordings.timer

# Manual cleanup
find ~/ssh-recordings -name "*.cast" -mtime +30 -delete
```

### Virtual Environment Activation

```bash
# Quick activation
sudo -u agent /opt/agentvm/activate.sh

# Manual activation
source /home/agent/agent-env/bin/activate

# Available agents
aider, opencode, claude
```

## Development Workflow

### Initial Setup

```bash
# Build and start VM
nix run .#arch-build-vm
nix run .#arch-run &

# Wait for boot (30-60 seconds)
sleep 45

# Verify services
curl http://127.0.0.1:8000/health
ssh agent@127.0.0.1 -p 2222 "echo 'SSH OK'"
```

### Daily Development

```bash
# Update system
sudo pacman -Syu && yay -Syu

# Connect and work
ssh agent@127.0.0.1 -p 2222
cd /mnt/host-projects/my-project

# Use agents
aider --model claude-3-5-sonnet-20241022 --message "Refactor module"
```

### Production Deployment

#### Security Hardening
```bash
# Configure firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 8000/tcp

# Enable fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Lock down SSH
sudo nano /etc/ssh/sshd_config
# PasswordAuthentication no
# PubkeyAuthentication yes
```

#### Monitoring
```bash
# System monitoring
htop
btop
iotop
nethogs

# Service monitoring
sudo systemctl status agent-api sshd
sudo journalctl -u agent-api --since "1 hour ago"
```

## Troubleshooting

### Common Issues

#### VM Won't Boot
```bash
# Check QEMU version
qemu-system-x86_64 --version

# Check KVM support
lsmod | grep kvm

# Rebuild VM disk
rm ./disks/agentvm-arch.qcow2
./build-vm.sh
```

#### Package Installation Failures
```bash
# Update keyring
sudo pacman -Sy archlinux-keyring

# Clear package cache
sudo pacman -Scc

# Refresh mirrors
sudo reflector --latest 20 --protocol https --sort rate
```

#### API Not Starting
```bash
# Check virtual environment
ls -la /home/agent/agent-env/

# Check API logs
sudo journalctl -u agent-api -n 50

# Manual API start
sudo -u agent /home/agent/agent-env/bin/uvicorn main:app \
    --host 0.0.0.0 --port 8000
```

## Migration from NixOS

If migrating from NixOS to Arch Linux:

1. **Export Configuration**:
   ```bash
   # Save current configuration
   nix eval .#nixosConfig --json > current-config.json
   ```

2. **Install Arch Linux**:
   ```bash
   nix run .#arch-build-vm
   nix run .#arch-run
   ```

3. **Import Data**:
   ```bash
   # Copy SSH keys and configurations
   scp -P 2222 ~/.ssh/id_rsa.pub agent@127.0.0.1:~/.ssh/
   ```

4. **Verify Functionality**:
   ```bash
   # Test agents and API
   curl http://127.0.0.1:8000/health
   ssh agent@127.0.0.1 -p 2222 "which aider"
   ```

## Performance

### System Requirements

| Component | Minimum | Recommended |
|-----------|----------|-------------|
| CPU       | 4 cores  | 6+ cores     |
| Memory    | 4GB      | 8GB+         |
| Storage   | 15GB     | 32GB+         |
| Network  | Broadband| Broadband     |

### Resource Usage

```
Component           Usage (Idle)   Usage (Active)
─────────────────────────────────────────────────
Base System          ~600MB          ~800MB
Docker               ~200MB          ~500MB
Python + Agents       ~400MB          ~1.5GB
API Service           ~100MB          ~200MB
─────────────────────────────────────────────────
Total (Arch Linux)    ~1.3GB          ~3.0GB
vs NixOS VM:         ~2.5GB          ~4.5GB
```

## Production Features

### Security
- ✅ systemd hardening with sandboxing
- ✅ Automatic security updates
- ✅ Package signature verification
- ✅ Fail2ban integration
- ✅ SSH key-based authentication

### Reliability
- ✅ Rolling release with latest patches
- ✅ AUR access for extended software
- ✅ Service monitoring and auto-restart
- ✅ Resource limits and quotas
- ✅ Comprehensive logging

### Maintainability
- ✅ Automated installation scripts
- ✅ Configuration management
- ✅ Service orchestration
- ✅ Health checks and diagnostics

This Arch Linux implementation provides maximum flexibility while maintaining production-ready security and reliability.