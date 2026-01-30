#!/usr/bin/env bash
# ========================================
# Arch Linux Agent Installation Script
# ========================================
# Production-ready script for installing AI agents and services

set -euo pipefail

# Configuration
USER="agent"
GROUP="agent"
INSTALL_DIR="/opt/agentvm"
VENV_DIR="/opt/agentvm/venv"

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
# System Requirements Check
# ========================================
check_system() {
    log "Checking system requirements..."
    
    # Check if Arch Linux
    if ! grep -q "Arch Linux" /etc/os-release; then
        log_error "This script is designed for Arch Linux only"
        exit 1
    fi
    
    # Check internet connection
    if ! ping -c 1 archlinux.org >/dev/null 2>&1; then
        log_error "No internet connection. Required for package installation."
        exit 1
    fi
    
    log_success "System requirements met"
}

# ========================================
# Create Installation Directory
# ========================================
setup_directories() {
    log "Setting up installation directories..."
    
    # Create directories with proper permissions
    sudo mkdir -p "$INSTALL_DIR"
    sudo mkdir -p "$VENV_DIR"
    sudo chown -R $USER:$GROUP "$INSTALL_DIR"
    sudo chmod 755 "$INSTALL_DIR"
    
    log_success "Directories created"
}

# ========================================
# Install Python Virtual Environment
# ========================================
install_python_venv() {
    log "Installing Python virtual environment..."
    
    # Install Python and virtualenv if not present
    if ! command -v python3 >/dev/null; then
        sudo pacman -S --noconfirm python python-virtualenv
    fi
    
    # Create virtual environment
    sudo -u $USER python3 -m venv "$VENV_DIR"
    
    log_success "Python virtual environment created"
}

# ========================================
# Install Aider Agent
# ========================================
install_aider() {
    log "Installing aider-chat..."
    
    source "$VENV_DIR/bin/activate"
    
    # Install aider from PyPI with specific version for stability
    pip install "aider-chat>=0.38.1"
    
    # Verify installation
    if command -v aide >/dev/null; then
        log_success "aider-chat installed successfully"
        aide --version
    else
        log_error "aider installation failed"
        exit 1
    fi
}

# ========================================
# Install OpenCode Agent
# ========================================
install_opencode() {
    log "Installing opencode..."
    
    source "$VENV_DIR/bin/activate"
    
    # Install opencode from PyPI
    pip install "opencode>=0.1.0"
    
    # Verify installation
    if command -v opencode >/dev/null; then
        log_success "opencode installed successfully"
    else
        log_error "opencode installation failed"
        exit 1
    fi
}

# ========================================
# Install Claude Code Agent
# ========================================
install_claude_code() {
    log "Installing claude-code..."
    
    # Install Node.js if not present
    if ! command -v npm >/dev/null; then
        sudo pacman -S --noconfirm nodejs npm
    fi
    
    # Install claude-code globally with specific version
    sudo npm install -g "@anthropic-ai/claude-code@0.7.0"
    
    # Verify installation
    if command -v claude >/dev/null; then
        log_success "claude-code installed successfully"
        claude --version
    else
        log_error "claude-code installation failed"
        exit 1
    fi
}

# ========================================
# Install API Dependencies
# ========================================
install_api_dependencies() {
    log "Installing API dependencies..."
    
    source "$VENV_DIR/bin/activate"
    
    # Install production-grade versions with specific versions
    pip install "fastapi>=0.104.0" \
            "uvicorn[standard]>=0.24.0" \
            "pydantic>=2.5.0" \
            "requests>=2.31.0" \
            "websockets>=12.0" \
            "redis>=5.0.0" \
            "psycopg2-binary>=2.9.0" \
            "sqlalchemy>=2.0.0" \
            "alembic>=1.12.0" \
            "asyncpg>=0.29.0"
    
    log_success "API dependencies installed"
}

# ========================================
# Setup API Service
# ========================================
setup_api_service() {
    log "Setting up API service..."
    
    # Copy API files from shared directory
    sudo mkdir -p /home/$USER/agent-api
    sudo chown -R $USER:$GROUP /home/$USER/agent-api
    
    # Create API startup script
    sudo tee /home/$USER/agent-api/start.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Load virtual environment
source /opt/agentvm/venv/bin/activate

# Set environment variables
export PYTHONPATH=/home/$USER/agent-api
export AGENT_ENV=production

# Start API server
exec uvicorn main:app --host 0.0.0.0 --port 8000 --no-access-log --workers 4
EOF
    
    sudo chmod +x /home/$USER/agent-api/start.sh
    sudo chown $USER:$GROUP /home/$USER/agent-api/start.sh
    
    # Create systemd service
    sudo tee /etc/systemd/system/agent-api.service > /dev/null <<EOF
[Unit]
Description=Oligarchy AgentVM API Service
Documentation=https://github.com/ALH477/Oligarchy-Agent-VM
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=/home/$USER/agent-api
Environment=PATH=/opt/agentvm/venv/bin:/usr/local/bin:/usr/bin
Environment=PYTHONPATH=/home/$USER/agent-api
Environment=AGENT_ENV=production

ExecStart=/home/$USER/agent-api/start.sh

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/home/$USER/agent-api /opt/agentvm/venv

# Resource limits
MemoryLimit=2G
CPUQuota=50%
Restart=always
RestartSec=5s

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=agentvm-api

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable agent-api.service
    sudo systemctl start agent-api.service
    
    log_success "API service configured and started"
}

# ========================================
# Setup SSH Tmux Wrapper
# ========================================
setup_ssh_wrapper() {
    log "Setting up SSH tmux wrapper..."
    
    # Copy wrapper script
    sudo mkdir -p /opt/agentvm
    sudo cp /home/asher/Downloads/Oligarchy-Agent-VM/arch-vm/scripts/ssh-tmux-wrapper.sh \
        /opt/agentvm/ssh-tmux-wrapper.sh
    sudo chmod +x /opt/agentvm/ssh-tmux-wrapper.sh
    
    # Configure SSH to use wrapper
    sudo tee -a /etc/ssh/sshd_config > /dev/null <<'EOF'

# AgentVM SSH tmux wrapper
Match User $USER
    ForceCommand /opt/agentvm/ssh-tmux-wrapper.sh
EOF
    
    # Restart SSH service
    sudo systemctl reload sshd.service
    
    log_success "SSH tmux wrapper configured"
}

# ========================================
# Setup Recording Cleanup
# ========================================
setup_recording_cleanup() {
    log "Setting up recording cleanup service..."
    
    # Copy service and timer
    sudo cp /home/asher/Downloads/Oligarchy-Agent-VM/arch-vm/systemd/cleanup-recordings.service \
        /etc/systemd/system/
    sudo cp /home/asher/Downloads/Oligarchy-Agent-VM/arch-vm/systemd/cleanup-recordings.timer \
        /etc/systemd/system/
    
    # Enable timer
    sudo systemctl daemon-reload
    sudo systemctl enable cleanup-recordings.timer
    sudo systemctl start cleanup-recordings.timer
    
    log_success "Recording cleanup service configured"
}

# ========================================
# Create Virtual Environment Activation Script
# ========================================
create_activation_script() {
    log "Creating virtual environment activation script..."
    
    sudo tee /opt/agentvm/activate.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
# AgentVM Virtual Environment Activation Script

export AGENTVM_VENV="/opt/agentvm/venv"
export PATH="/opt/agentvm/venv/bin:$PATH"

# Activate virtual environment
source "/opt/agentvm/venv/bin/activate"

echo "[AgentVM] Virtual environment activated"
echo "[AgentVM] Python: $(which python)"
echo "[AgentVM] Available agents: aider, opencode, claude"
echo "[AgentVM] API: http://localhost:8000"
EOF
    
    sudo chmod +x /opt/agentvm/activate.sh
    
    log_success "Activation script created"
}

# ========================================
# Production Configuration
# ========================================
setup_production_config() {
    log "Setting up production configuration..."
    
    # Create environment file for API key
    sudo tee /home/$USER/agent-api/.env > /dev/null <<'EOF'
# AgentVM Production Configuration
# Set your actual API key here
AGENTVM_API_KEY=CHANGE-THIS-IN-PRODUCTION

# Production settings
DEBUG=false
LOG_LEVEL=INFO
MAX_AGENTS=20
AUTO_SPAWN=true
EOF
    
    sudo chmod 600 /home/$USER/agent-api/.env
    sudo chown $USER:$GROUP /home/$USER/agent-api/.env
    
    log_success "Production configuration created"
    log_warning "Remember to update AGENTVM_API_KEY in /home/$USER/agent-api/.env"
}

# ========================================
# Health Check
# ========================================
health_check() {
    log "Performing health checks..."
    
    # Check API service
    if sudo systemctl is-active --quiet agent-api.service; then
        log_success "API service is running"
    else
        log_error "API service is not running"
        return 1
    fi
    
    # Check virtual environment
    if [[ -f "$VENV_DIR/bin/activate" ]]; then
        log_success "Virtual environment is ready"
    else
        log_error "Virtual environment not found"
        return 1
    fi
    
    # Check agent installations
    local agents=("aide" "opencode" "claude")
    for agent in "${agents[@]}"; do
        if command -v $agent >/dev/null; then
            log_success "$agent is installed"
        else
            log_warning "$agent is not installed"
        fi
    done
    
    log_success "Health checks completed"
}

# ========================================
# Main Installation Function
# ========================================
main() {
    log "Starting production-ready AgentVM agent installation for Arch Linux..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Run installation steps
    check_system
    setup_directories
    install_python_venv
    install_aider
    install_opencode
    install_claude_code
    install_api_dependencies
    setup_api_service
    setup_ssh_wrapper
    setup_recording_cleanup
    create_activation_script
    setup_production_config
    
    # Final health check
    sleep 5  # Give services time to start
    health_check
    
    log_success "AgentVM agent installation completed successfully!"
    echo ""
    echo "========================================="
    echo "POST-INSTALLATION STEPS:"
    echo "========================================="
    echo "1. Update API key:"
    echo "   sudo nano /home/$USER/agent-api/.env"
    echo ""
    echo "2. Restart services if needed:"
    echo "   sudo systemctl restart agent-api"
    echo "   sudo systemctl restart sshd"
    echo ""
    echo "3. Test as user '$USER':"
    echo "   sudo -u $USER /opt/agentvm/activate.sh"
    echo "   aider --help"
    echo "   opencode --help"
    echo "   claude --help"
    echo ""
    echo "4. Access API:"
    echo "   curl http://localhost:8000/health"
    echo "   curl http://localhost:8000/docs"
    echo ""
    echo "5. Connect via SSH:"
    echo "   ssh $USER@localhost -p 2222"
    echo "========================================="
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi