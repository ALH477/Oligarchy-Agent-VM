#!/usr/bin/env bash
# ========================================
# Arch Linux VM Build Script
# ========================================
# Production-ready script for building Arch Linux AgentVM

set -euo pipefail

# Configuration
VM_NAME="agentvm-arch"
VM_DISK_SIZE="32G"
VM_MEMORY="8192"
VM_CPUS="6"
ISO_PATH="${ISO_PATH:-./iso/archlinux-latest-x86_64.iso}"
DISK_PATH="./disks/${VM_NAME}.qcow2"
HOST_PROJECTS_PATH="${HOST_PROJECTS_PATH:-/home/demod/projects}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
# Check Prerequisites
# ========================================
check_prerequisites() {
    log "Checking prerequisites..."
    
    local required_tools=("qemu-system-x86_64" "qemu-img" "wget" "curl" "git")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            log_error "$tool is not installed. Please install it first."
            exit 1
        fi
    done
    
    # Create directories
    mkdir -p ./disks
    mkdir -p ./iso
    mkdir -p ./cloud-init
    
    log_success "Prerequisites check completed"
}

# ========================================
# Download Arch ISO
# ========================================
download_arch_iso() {
    log "Downloading latest Arch Linux ISO..."
    
    if [[ ! -f "$ISO_PATH" ]]; then
        # Get latest ISO info
        local iso_url="https://mirror.archlinux.org/iso/latest/archlinux-x86_64.iso"
        local iso_sig_url="https://mirror.archlinux.org/iso/latest/archlinux-x86_64.iso.sig"
        
        log "Downloading Arch Linux ISO..."
        wget -O "$ISO_PATH" "$iso_url"
        wget -O "$ISO_PATH.sig" "$iso_sig_url"
        
        # Verify signature
        if command -v gpg >/dev/null; then
            log "Verifying ISO signature..."
            gpg --keyserver keys.gnupg.net --recv-keys 6AAE4F23DB6D9D3
            gpg --verify "$ISO_PATH.sig" "$ISO_PATH" 2>/dev/null && \
                log_success "ISO signature verified" || \
                log_warning "Could not verify ISO signature"
        fi
        
        log_success "Arch Linux ISO downloaded: $ISO_PATH"
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
    
    # Create cloud-init user-data
    cat > cloud-init/user-data <<'EOF'
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
  - python-virtualenv
  - tmux
  - openssh
  - sudo
  - systemd
  - networkmanager
  - reflector
  - docker
  - podman

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
      #!/bin/bash
      set -euo pipefail
      
      echo "[AgentVM] Starting production setup..."
      
      # Install yay (AUR helper)
      cd /tmp
      git clone https://aur.archlinux.org/yay.git
      chown agent:agent yay
      sudo -u agent cd yay && makepkg -si --noconfirm
      
      # Configure mirrors for performance
      reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
      
      # Install development environment
      sudo pacman -S --noconfirm nodejs npm
      
      # Download and install AI agents
      sudo -u agent bash -c '
        cd /home/agent
        python -m venv agent-env
        source /home/agent/agent-env/bin/activate
        
        # Install with specific production versions
        pip install "aider-chat>=0.38.1"
        pip install "opencode>=0.1.0"
        pip install "fastapi>=0.104.0"
        pip install "uvicorn[standard]>=0.24.0"
        pip install "pydantic>=2.5.0"
        pip install "requests>=2.31.0"
        pip install "websockets>=12.0"
        pip install "redis>=5.0.0"
        pip install "psycopg2-binary>=2.9.0"
        pip install "sqlalchemy>=2.0.0"
        pip install "alembic>=1.12.0"
        pip install "asyncpg>=0.29.0"
      '
      
      # Install claude-code
      sudo -u agent npm install -g "@anthropic-ai/claude-code@0.7.0"
      
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
        • Storage: $(df -h / | tail -1 | awk '{print $4}')
      
      Services:
        • SSH Port: 22
        • Agent API: http://localhost:8000
        • Docker: Enabled
        • Agent Environment: /home/agent/agent-env
      
      Commands:
        • Update system: sudo pacman -Syu && yay -Syu
        • Install packages: sudo pacman -S <package> or yay -S <package>
        • Search packages: pacman -Ss <package> or yay -Ss <package>
        • Activate environment: /opt/agentvm/activate.sh

EOF
    
    log_success "Cloud-init configuration generated"
}

# ========================================
# Create VM Build Script
# ========================================
create_build_script() {
    log "Creating VM build script..."
    
    # CPU isolation parameters
    local cpu_params=""
    if [[ -n "${CPU_ISOLATION:-}" ]]; then
        cpu_params="-cpu host -smp $VM_CPUS -enable-kvm"
    else
        cpu_params="-cpu host,-kvm"
    fi
    
    cat > build-vm.sh <<'EOF'
#!/usr/bin/env bash
# ========================================
# Arch Linux VM Build and Launch Script
# ========================================

set -euo pipefail

VM_NAME="$VM_NAME"
ISO_PATH="$ISO_PATH"
DISK_PATH="$DISK_PATH"
HOST_PROJECTS_PATH="$HOST_PROJECTS_PATH"

# Network configuration
net_opts="-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8000-:8000"

# Virtiofs for host directory sharing
if [[ -n "\$HOST_PROJECTS_PATH" ]]; then
    virtiofs_opts="-fsdev local,id=host,path=\$HOST_PROJECTS_PATH,security_model=passthrough -device virtiofs-pci,id=host,fsdev=host"
else
    virtiofs_opts=""
fi

# CPU configuration
if [[ -n "\${CPU_ISOLATION:-}" ]]; then
    cpu_opts="-cpu host -smp $VM_CPUS -enable-kvm"
else
    cpu_opts="-cpu host,-kvm"
fi

echo "========================================="
echo "Building Arch Linux AgentVM"
echo "========================================="
echo "VM Name: \$VM_NAME"
echo "CPU Cores: $VM_CPUS"
echo "Memory: ${VM_MEMORY}MB"
echo "Disk: \$DISK_PATH"
echo "ISO: \$ISO_PATH"
echo "Host Projects: \${HOST_PROJECTS_PATH:-disabled}"
echo "========================================="

# Launch QEMU for installation
echo "Starting QEMU VM for installation..."
qemu-system-x86_64 \
    -M q35 \
    $cpu_opts \
    -m $VM_MEMORY \
    -drive file="\$DISK_PATH",format=qcow2,if=virtio,cache=none \
    -drive file="\$ISO_PATH",media=cdrom,readonly=on \
    -net nic,model=virtio \
    \$net_opts \
    \$virtiofs_opts \
    -device virtio-gpu-pci \
    -display none \
    -nographic \
    -cdrom "\$ISO_PATH" \
    -boot once=d

echo ""
echo "VM is booting. Installation will proceed automatically."
echo "After installation completes, you can connect via: ssh agent@127.0.0.1 -p 2222"
echo "API will be available at: http://127.0.0.1:8000"
echo ""
echo "Press Ctrl+A then X to quit QEMU"
EOF
    
    chmod +x build-vm.sh
    log_success "VM build script created: build-vm.sh"
}

# ========================================
# Main Function
# ========================================
main() {
    log "Starting Arch Linux AgentVM build process..."
    
    check_prerequisites
    download_arch_iso
    create_vm_disk
    generate_cloud_init
    create_build_script
    
    log_success "Build process completed!"
    echo ""
    echo "========================================="
    echo "NEXT STEPS:"
    echo "========================================="
    echo "1. Build VM:"
    echo "   ./build-vm.sh"
    echo ""
    echo "2. Connect after boot:"
    echo "   ssh agent@127.0.0.1 -p 2222"
    echo ""
    echo "3. Access API:"
    echo "   curl http://127.0.0.1:8000/health"
    echo "   curl http://127.0.0.1:8000/docs"
    echo "========================================="
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi