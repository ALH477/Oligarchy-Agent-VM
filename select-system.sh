#!/usr/bin/env bash
# ========================================
# AgentVM System Selection Script
# ========================================
# Interactive helper to choose between NixOS and Arch Linux

set -euo pipefail

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# UI Elements
header() {
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC} $1${NC}$(printf "%*s" $(($1-1)) " " | sed "s/ / /${PURPLE}║${NC}/g")"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════╝${NC}"
}

box() {
    local text="$1"
    local color="${2:-$BLUE}"
    local width=60
    
    # Create box with text
    echo -e "${color}┌$(printf '%.0s' $((width-2)))┐${NC}"
    echo -e "${color}│${NC} ${text}$(printf "%*s" $(($width-2-${#text})) " " | sed "s/ / /${color}│${NC}/g")"
    echo -e "${color}└$(printf '%.0s' $((width-2)))┘${NC}"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# ========================================
# System Information
# ========================================
show_system_info() {
    header "OLIGARCHY AGENTVM - SYSTEM SELECTION"
    
    echo ""
    echo -e "${WHITE}Choose your preferred base system for AgentVM:${NC}"
    echo ""
    
    # NixOS Option
    box "🔄 NIXOS (Declarative)" "$GREEN"
    echo ""
    echo "  • Package Manager: Nix (declarative, reproducible)"
    echo "  • Release Model: Controlled releases"
    echo "  • Updates: Predicable, tested packages"
    echo "  • Best For: Production environments, maximum reproducibility"
    echo "  • Setup: nix build .#nixos-agent-vm-qcow2 && nix run .#nixos-run"
    echo ""
    
    # Arch Linux Option
    box "🐧 ARCH LINUX (Pacman + AUR)" "$BLUE"
    echo ""
    echo "  • Package Manager: pacman + AUR (latest packages)"
    echo "  • Release Model: Rolling release (continuous updates)"
    echo "  • Updates: Latest software, AUR access"
    echo "  • Best For: Development, latest tools, flexibility"
    echo "  • Setup: nix run .#arch-build-vm && nix run .#arch-run"
    echo ""
    
    # Feature Comparison
    echo -e "${WHITE}┌────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${WHITE}│${NC} ${CYAN}Feature Comparison${NC}$(printf "%*s" 42 " " | sed "s/ / /${WHITE}│${NC}/g")"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC} Feature           │${NC} NixOS    │${NC} Arch Linux │${NC}$(printf "%*s" 11 " " | sed "s/ / /${WHITE}│${NC}/g")"
    echo -e "${WHITE}├────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${WHITE}│${NC} Packages          │${NC} Declarative │${NC} Latest + AUR │${NC}$(printf "%*s" 11 " " | sed "s/ / /${WHITE}│${NC}/g")"
    echo -e "${WHITE}│${NC} Updates           │${NC} Controlled  │${NC} Rolling      │${NC}$(printf "%*s" 11 " " | sed "s/ / /${WHITE}│${NC}/g")"
    echo -e "${WHITE}│${NC} Reproducibility  │${NC} ⭐⭐⭐⭐⭐  │${NC} ⭐⭐⭐       │${NC}$(printf "%*s" 11 " " | sed "s/ / /${WHITE}│${NC}/g")"
    echo -e "${WHITE}│${NC} Setup Complexity  │${NC} Higher      │${NC} Lower        │${NC}$(printf "%*s" 11 " " | sed "s/ / /${WHITE}│${NC}/g")"
    echo -e "${WHITE}│${NC} Package Choice    │${NC} Good        │${NC} Excellent    │${NC}$(printf "%*s" 11 " " | sed "s/ / /${WHITE}│${NC}/g")"
    echo -e "${WHITE}└────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ========================================
# Interactive Selection
# ========================================
select_system() {
    echo -e "${WHITE}Select your preferred system:${NC}"
    echo ""
    echo -e "${GREEN}1${NC}) NixOS (Declarative, Reproducible)"
    echo -e "${BLUE}2${NC}) Arch Linux (Latest packages, AUR)"
    echo ""
    echo -e "${YELLOW}q${NC}) Quit"
    echo ""
    
    while true; do
        read -p "Enter your choice [1/2/q]: " choice
        case $choice in
            1|nixos|NIXOS)
                return "nixos"
                ;;
            2|arch|ARCH|arch-linux|ARCH-LINUX)
                return "arch"
                ;;
            q|quit|QUIT)
                info "Goodbye!"
                exit 0
                ;;
            *)
                warning "Invalid choice. Please enter 1, 2, or q."
                ;;
        esac
    done
}

# ========================================
# Quick Start
# ========================================
quick_start() {
    local system="$1"
    
    echo ""
    header "QUICK START - $system"
    
    case $system in
        "nixos")
            echo -e "${GREEN}Building and starting NixOS AgentVM...${NC}"
            echo ""
            echo "Commands to run manually:"
            echo -e "${CYAN}nix build .#nixos-agent-vm-qcow2${NC}"
            echo -e "${CYAN}nix run .#nixos-run${NC}"
            echo ""
            read -p "Press Enter to build NixOS VM: " confirm
            if [[ $confirm == [Yy]* ]]; then
                echo -e "${YELLOW}Building NixOS VM...${NC}"
                nix build .#nixos-agent-vm-qcow2
                success "NixOS VM build completed!"
                echo ""
                read -p "Press Enter to start NixOS VM: " confirm
                nix run .#nixos-run &
                success "NixOS VM is starting..."
                info "Connect with: ssh user@127.0.0.1 -p 2222"
                info "API at: http://127.0.0.1:8000/docs"
            fi
            ;;
        "arch")
            echo -e "${BLUE}Building and starting Arch Linux AgentVM...${NC}"
            echo ""
            echo "Commands to run manually:"
            echo -e "${CYAN}nix run .#arch-build-vm${NC}"
            echo -e "${CYAN}nix run .#arch-run${NC}"
            echo ""
            read -p "Press Enter to build Arch Linux VM: " confirm
            if [[ $confirm == [Yy]* ]]; then
                echo -e "${YELLOW}Building Arch Linux VM...${NC}"
                nix run .#arch-build-vm
                success "Arch Linux VM build completed!"
                echo ""
                read -p "Press Enter to start Arch Linux VM: " confirm
                nix run .#arch-run &
                success "Arch Linux VM is starting..."
                info "Connect with: ssh agent@127.0.0.1 -p 2222"
                info "API at: http://127.0.0.1:8000/docs"
            fi
            ;;
    esac
}

# ========================================
# Help Information
# ========================================
show_help() {
    header "AGENTVM SYSTEM SELECTION - HELP"
    
    echo ""
    echo -e "${WHITE}Usage:${NC}"
    echo "  $0 [options]"
    echo ""
    echo -e "${WHITE}Options:${NC}"
    echo "  ${GREEN}--nixos${NC}       Quick start with NixOS"
    echo "  ${BLUE}--arch${NC}        Quick start with Arch Linux"
    echo "  ${CYAN}--help${NC}         Show this help message"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo "  $0                Interactive system selection"
    echo "  $0 --nixos        Direct NixOS setup"
    echo "  $0 --arch          Direct Arch Linux setup"
    echo ""
}

# ========================================
# Main Function
# ========================================
main() {
    case "${1:-}" in
        --help|-h|help)
            show_help
            ;;
        --nixos)
            quick_start "nixos"
            ;;
        --arch)
            quick_start "arch"
            ;;
        "")
            show_system_info
            local system_choice=$(select_system)
            quick_start "$system_choice"
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for available options"
            exit 1
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi