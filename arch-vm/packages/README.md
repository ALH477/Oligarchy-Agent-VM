# Arch Linux Packages for AgentVM

## Package Lists for Different Deployment Modes

### packages-minimal.txt
Base packages for minimal SSH-only deployment
```
# Core system
base
base-devel
linux
linux-firmware

# Essential tools
neovim
git
curl
wget
htop
btop
ripgrep
fd
openssh
sudo
systemd
networkmanager

# Container runtime
podman
podman-compose

# Development
python
python-pip
python-virtualenv
tmux
```

### packages-standard.txt
Standard packages for SSH + Docker deployment
```
# Include minimal packages
@packages-minimal.txt

# Additional container support
docker
docker-compose

# Development tools
nodejs
npm
rust
go
java-runtime

# Additional tools
asciinema
screen
tmux
```

### packages-full.txt
Full packages for GUI + SSH + Docker deployment
```
# Include standard packages
@packages-standard.txt

# GUI support
xorg-server
xorg-xinit
wayland
weston
gnome-session
gnome-shell

# Wayland components
gtk4
libadwaita
cairo
pango
glib
gdk-pixbuf

# Development GUI tools
gnome-terminal
nautilus
gedit

# Browser (for documentation access)
firefox
```

## AI Agent Packages

### ai-agents.txt
AI coding agents and dependencies
```
# Python packages (install via pip)
aider-chat
opencode
anthropic
fastapi
uvicorn
pydantic
requests
websockets
redis
psycopg2-binary
sqlalchemy

# Node.js packages (install via npm)
@anthropic-ai/claude-code

# AUR packages (install via yay)
-- Helper for AUR packages
yay

-- Alternative AI tools if needed
tabby-bin
shell-gpt
```

## Development Environment

### neovim-packages.txt
Neovim plugins and LSP servers
```
# Language servers
python-lsp-server
rust-analyzer
gopls
bash-language-server
lua-language-server
yaml-language-server
json-language-server

# Neovim plugins
-- Install via vim-plug after bootstrap
junegunn/fzf.vim
neoclide/coc.nvim
prabirshrestha/asynctasks.vim
nvim-treesitter/nvim-treesitter
nvim-lua/plenary.nvim
nvim-telescope/telescope.nvim
lewis6991/gitsigns.nvim
```

## System Utilities

### system-packages.txt
System monitoring and utilities
```
# System monitoring
htop
btop
iotop
nethogs
strace
lsof

# File system tools
tree
ncdu
rsync
unzip
zip
p7zip

# Network tools
net-tools
dnsutils
iproute2
wireguard-tools
openssh

# Security
fail2ban
ufw
audit

# Archive tools
tar
gzip
bzip2
xz
```

## Installation Scripts

### install-minimal.sh
```bash
#!/usr/bin/env bash
# Install minimal package set

set -euo pipefail

# Update package database
sudo pacman -Sy

# Install core packages
sudo pacman -S --needed $(cat packages-minimal.txt)

# Install yay (AUR helper)
cd /tmp
git clone https://aur.archlinux.org/yay.git
chown $USER:$USER yay
cd yay && makepkg -si --noconfirm

echo "Minimal installation completed"
```

### install-standard.sh
```bash
#!/usr/bin/env bash
# Install standard package set

set -euo pipefail

# Include minimal installation
./install-minimal.sh

# Install additional packages
sudo pacman -S --needed $(cat packages-standard.txt | grep -v '^#' | grep -v '^@')

# Setup Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

echo "Standard installation completed"
```

### install-full.sh
```bash
#!/usr/bin/env bash
# Install full package set with GUI

set -euo pipefail

# Include standard installation
./install-standard.sh

# Install GUI packages
sudo pacman -S --needed $(cat packages-full.txt | grep -v '^#' | grep -v '^@')

# Setup GUI
sudo systemctl enable gdm
sudo systemctl set-default graphical.target

echo "Full GUI installation completed"
```

## Package Management

### Update Commands
```bash
# Update system packages
sudo pacman -Syu

# Update AUR packages
yay -Syu

# Update both
sudo pacman -Syu && yay -Syu
```

### Search and Install
```bash
# Search official repos
pacman -Ss <package-name>

# Search AUR
yay -Ss <package-name>

# Install from official repos
sudo pacman -S <package-name>

# Install from AUR
yay -S <package-name>
```

### Maintenance
```bash
# Remove unused packages
sudo pacman -Rns $(pacman -Qtdq)

# Clean package cache
sudo pacman -Scc

# Orphaned packages cleanup
sudo pacman -Rns $(pacman -Qtdq)
```

## Configuration Files

### pacman.conf
Optimized pacman configuration for AgentVM
```conf
[options]
# Architecture
Architecture = auto

# Check space before installation
CheckSpace

# Verbose package lists
VerbosePkgLists

# Color output
Color

# Download with multiple connections
ParallelDownloads = 5

# Use delta for package differences
#Delta

[core]
SigLevel = PackageRequired
Server = https://mirror.archlinux.org/core/os/x86_64

[extra]
SigLevel = PackageRequired
Server = https://mirror.archlinux.org/extra/os/x86_64

[community]
SigLevel = PackageRequired
Server = https://mirror.archlinux.org/community/os/x86_64

[multilib]
SigLevel = PackageRequired
Server = https://mirror.archlinux.org/multilib/os/x86_64
```

## Mirror Configuration

### mirrorlist
Optimized mirror list for performance
```
## Worldwide
Server = https://mirror.archlinux.org/$repo/os/$arch

## United States
Server = https://america.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.us-west.k8s.us-west-2.amazonaws.com/$repo/os/$arch

## Europe
Server = https://mirrors.dotsrc.org/$repo/os/$arch
Server = https://mirror.freedif.org/$repo/os/$arch
```

## Update Scripts

### update-system.sh
Automated system update script
```bash
#!/usr/bin/env bash
# Automated system update with notifications

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Update mirrors
log "Updating mirror list..."
sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Update package databases
log "Updating package databases..."
sudo pacman -Sy

# Update system packages
log "Updating system packages..."
sudo pacman -Su --noconfirm

# Update AUR packages
if command -v yay &> /dev/null; then
    log "Updating AUR packages..."
    yay -Syu --noconfirm
fi

# Clean package cache
log "Cleaning package cache..."
sudo pacman -Scc --noconfirm

log "System update completed successfully"
```

## Security

### Security Hardening
```bash
# Enable firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 8000/tcp

# Enable fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Security updates
sudo pacman -Syu --ignore linux --ignore linux-lts
```

## Optimization

### Performance Tuning
```bash
# Enable parallel downloads
echo 'ParallelDownloads = 5' | sudo tee -a /etc/pacman.conf

# Use delta for better diffs
echo 'Delta' | sudo tee -a /etc/pacman.conf

# Optimize mirrors
sudo pacman -S reflector
sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

This package management system provides:
✅ Latest packages via rolling release
✅ AUR access for additional software
✅ Automated installation scripts
✅ Performance optimizations
✅ Security hardening options
✅ Multiple deployment modes support