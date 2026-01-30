#!/usr/bin/env bash
# ========================================
# Arch Linux Automated Installation Script
# ========================================
# This script installs Arch Linux in a QEMU VM for AgentVM
# Compatible with the minimal Arch ISO

set -euo pipefail

# Configuration Variables
VM_NAME="agentvm-arch"
VM_DISK_SIZE="32G"
VM_MEMORY="8192"
VM_CPUS="6"
ISO_PATH="${ISO_PATH:-./iso/archlinux-latest-x86_64.iso}"
DISK_PATH="./disks/${VM_NAME}.qcow2"
ARCH_MIRROR="https://mirror.archlinux.org/iso/latest/"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ========================================
# Prerequisites Check
# ========================================
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if required tools are installed
    local required_tools=("qemu-system-x86_64" "qemu-img" "wget" "curl")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is not installed. Please install it first."
            exit 1
        fi
    done
    
    # Create directories
    mkdir -p ./disks
    mkdir -p ./iso
    
    log_success "Prerequisites check completed"
}

# ========================================
# Download Arch ISO
# ========================================
download_arch_iso() {
    log "Downloading latest Arch Linux ISO..."
    
    if [[ ! -f "$ISO_PATH" ]]; then
        # Get latest ISO info
        local iso_info=$(curl -s "$ARCH_MIRROR" | grep -o 'archlinux-[0-9]*\.[0-9]*\.[0-9]*-x86_64.iso' | head -1)
        
        if [[ -z "$iso_info" ]]; then
            log_error "Could not determine latest Arch Linux ISO"
            exit 1
        fi
        
        log "Downloading $iso_info..."
        wget -O "$ISO_PATH" "$ARCH_MIRROR$iso_info"
        log_success "Arch Linux ISO downloaded"
    else
        log "Arch Linux ISO already exists: $ISO_PATH"
    fi
}

# ========================================
# Create VM Disk
# ========================================
create_vm_disk() {
    log "Creating VM disk image..."
    
    if [[ ! -f "$DISK_PATH" ]]; then
        qemu-img create -f qcow2 "$DISK_PATH" "$VM_DISK_SIZE"
        log_success "VM disk created: $DISK_PATH ($VM_DISK_SIZE)"
    else
        log "VM disk already exists: $DISK_PATH"
    fi
}

# ========================================
# Generate Cloud-Init Configuration
# ========================================
generate_cloud_init() {
    log "Generating cloud-init configuration..."
    
    cat > cloud-init/user-data << 'EOF'
#cloud-config
# -*- mode: yaml -*-
# vim: syntax=yaml

# System configuration
timezone: UTC
locale: en_US.UTF-8
keyboard:
  layout: us
  variant: us

# SSH configuration
ssh_pwauth: true
ssh_deletekeys: false
chpasswd:
  list: |
    agent:agent
  expire: false

# Create agent user with sudo access
users:
  - name: agent
    groups: [wheel, docker, video, input]
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]

# Package installation (first boot)
packages:
  - base-devel
  - linux
  - linux-firmware
  - neovim
  - git
  - curl
  - wget
  - htop
  - btop
  - ripgrep
  - fd
  - python
  - python-pip
  - docker
  - podman
  - tmux
  - openssh
  - sudo
  - systemd
  - networkmanager

# Enable services
runcmd:
  - systemctl enable sshd
  - systemctl enable NetworkManager
  - systemctl enable docker
  - systemctl enable podman

# Post-installation script
write_files:
  - path: /etc/systemd/system/agent-setup.service
    permissions: '0644'
    content: |
      [Unit]
      Description=AgentVM Setup Script
      After=network-online.target
      
      [Service]
      Type=oneshot
      User=root
      ExecStart=/opt/agentvm/setup.sh
      
      [Install]
      WantedBy=multi-user.target

  - path: /opt/agentvm/setup.sh
    permissions: '0755'
    content: |
      #!/bin/bin/bash
      set -euo pipefail
      
      echo "[AgentVM] Starting setup..."
      
      # Install yay (AUR helper)
      cd /tmp
      git clone https://aur.archlinux.org/yay.git
      chown agent:agent yay
      sudo -u agent cd yay && makepkg -si --noconfirm
      
      # Configure mirrors
      pacman -S --noconfirm reflector
      reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
      
      # Install development environment
      pacman -S --noconfirm python-virtualenv
      pacman -S --noconfirm nodejs npm
      pacman -S --noconfirm base-devel
      pacman -S --noconfirm alsa-utils
      pacman -S --noconfirm mesa
      pacman -S --noconfirm vulkan-tools
      
      # Download and install AI agents
      sudo -u agent bash -c '
        cd /home/agent
        python -m venv agent-env
        source /home/agent/agent-env/bin/activate
        
        # Install aider
        pip install aider-chat
        
        # Install opencode
        pip install opencode
        
        # Install claude-code
        npm install -g @anthropic-ai/claude-code
      '
      
      echo "[AgentVM] Setup completed successfully"
      
  - path: /etc/motd
    permissions: '0644'
    content: |
      ╔═══════════════════════════════════════════════════════════╗
      ║         Oligarchy AgentVM — Arch Linux Edition          ║
      ╚═══════════════════════════════════════════════════════════╝
      
      System Information:
        • Distribution: Arch Linux (rolling release)
        • Package Manager: pacman + AUR (yay)
        • Kernel: $(uname -r)
        • Disk Space: $(df -h / | tail -1 | awk '{print $4}')
      
      Services:
        • SSH Port: 22
        • Agent API: http://localhost:8000
        • Docker: Enabled
        • Agent Environment: /home/agent/agent-env
      
      Help:
        • Update system: sudo pacman -Syu && yay -Syu
        • Install packages: pacman -S <package> or yay -S <package>
        • Search packages: pacman -Ss <package> or yay -Ss <package>
        
EOF
    
    log_success "Cloud-init configuration generated"
}

# ========================================
# Launch QEMU VM for Installation
# ========================================
launch_install_vm() {
    log "Starting QEMU VM for installation..."
    
    # Network configuration for port forwarding
    local net_opts="-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8000-:8000"
    
    # virtiofs for host directory sharing
    local virtiofs_opts="-fsdev local,id=host,path=/home/demod/projects,security_model=passthrough -device virtiofs-pci,id=host,fsdev=host"
    
    # Launch QEMU with cloud-init
    qemu-system-x86_64 \
        -M q35 \
        -cpu host \
        -smp "$VM_CPUS" \
        -m "$VM_MEMORY" \
        -drive file="$DISK_PATH",format=qcow2,if=virtio,cache=none \
        -drive file="$ISO_PATH",media=cdrom,readonly=on \
        -net nic,model=virtio \
        $net_opts \
        $virtiofs_opts \
        -device virtio-gpu-pci \
        -display none \
        -enable-kvm \
        -nographic \
        -cdrom "$ISO_PATH" \
        -boot once=d
        
    log_success "VM started. Installation will proceed automatically."
    log "After installation completes, you can connect via: ssh agent@127.0.0.1 -p 2222"
}

# ========================================
# Main Function
# ========================================
main() {
    log "Starting Arch Linux AgentVM setup..."
    
    check_prerequisites
    download_arch_iso
    create_vm_disk
    generate_cloud_init
    launch_install_vm
    
    log_success "Setup complete! VM is booting with automated installation."
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi