#!/bin/bash
# =============================================================================
# CCDC Practice Range Deployment Script
# Automates the deployment of the Ludus cybersecurity training environment
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Functions
print_header() {
    echo -e "\n${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=============================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if Ludus CLI is installed
check_ludus() {
    if ! command -v ludus &> /dev/null; then
        print_error "Ludus CLI is not installed or not in PATH"
        echo "Please install Ludus first: https://docs.ludus.cloud/docs/quick-start/install-ludus"
        exit 1
    fi
    print_success "Ludus CLI found"
}

# Check current range status
check_range_status() {
    print_info "Checking current range status..."
    ludus range status || true
}

# Add Ansible roles to Ludus
add_roles() {
    print_header "Adding Ansible Roles to Ludus"

    local roles_dir="$PROJECT_DIR/ansible/roles"

    for role in "$roles_dir"/*; do
        if [ -d "$role" ]; then
            role_name=$(basename "$role")
            print_info "Adding role: $role_name"
            ludus ansible role add -d "$role" || print_warning "Role $role_name may already exist"
        fi
    done

    print_success "Ansible roles added"
}

# Verify required templates exist
check_templates() {
    print_header "Checking Required Templates"

    local required_templates=(
        "win2019-server-x64-template"
        "win10-22h2-x64-enterprise-template"
        "ubuntu-22.04-x64-server-template"
        "debian-12-x64-server-template"
    )

    print_info "Fetching available templates..."
    local available_templates=$(ludus templates list 2>/dev/null || echo "")

    for template in "${required_templates[@]}"; do
        if echo "$available_templates" | grep -q "$template"; then
            print_success "Template available: $template"
        else
            print_warning "Template may need to be built: $template"
        fi
    done
}

# Set range configuration
set_config() {
    print_header "Setting Range Configuration"

    local config_file="$PROJECT_DIR/ludus-config.yml"

    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        exit 1
    fi

    print_info "Uploading configuration..."
    ludus range config set -f "$config_file"
    print_success "Configuration uploaded"
}

# Build templates if needed
build_templates() {
    print_header "Building Required Templates"

    print_info "This may take a while if templates need to be built..."
    print_info "Run 'ludus templates status' to check progress"

    # Build all unbuilt templates (limit parallelism to avoid resource issues)
    ludus templates build --all -p 2 || print_warning "Some templates may already be built"

    print_success "Template build initiated"
}

# Deploy the range
deploy_range() {
    print_header "Deploying Range"

    print_info "Starting range deployment..."
    print_info "This process includes:"
    echo "  1. Creating VMs from templates"
    echo "  2. Configuring networking"
    echo "  3. Joining Windows machines to domain"
    echo "  4. Running Ansible roles"
    echo ""
    print_warning "This may take 30-60 minutes depending on your hardware"

    ludus range deploy

    print_success "Range deployment initiated"
}

# Deploy only user-defined Ansible roles
deploy_roles_only() {
    print_header "Deploying Ansible Roles Only"

    print_info "Running user-defined Ansible roles..."
    ludus range deploy -t user-defined-roles

    print_success "Roles deployment completed"
}

# Show range status and connection info
show_connection_info() {
    print_header "Connection Information"

    echo "Range Status:"
    ludus range status || true

    echo ""
    echo "To access your range:"
    echo "  1. Connect to WireGuard VPN (see 'ludus user wireguard' for config)"
    echo "  2. Use the following credentials:"
    echo ""
    echo "  Domain Administrator:"
    echo "    Username: BLUE\\itmgr"
    echo "    Password: ITManager2024!"
    echo ""
    echo "  Local Administrator (all Windows machines):"
    echo "    Username: localuser"
    echo "    Password: password"
    echo ""
    echo "  Linux Machines:"
    echo "    Username: localuser"
    echo "    Password: password"
    echo ""
    echo "  Network Addresses (replace X with your range ID):"
    echo "    DC01:  10.X.10.10"
    echo "    WEB01: 10.X.10.20"
    echo "    DB01:  10.X.10.30"
    echo "    WS01:  10.X.10.50"
    echo ""
}

# Take snapshot of range
take_snapshot() {
    print_header "Taking Range Snapshot"

    local snapshot_name="${1:-pre-training}"

    print_info "Creating snapshot: $snapshot_name"
    ludus range snapshot -n "$snapshot_name"

    print_success "Snapshot created"
}

# Restore from snapshot
restore_snapshot() {
    print_header "Restoring Range from Snapshot"

    local snapshot_name="${1:-pre-training}"

    print_info "Restoring snapshot: $snapshot_name"
    ludus range restore -n "$snapshot_name"

    print_success "Snapshot restored"
}

# Enable testing mode (blocks internet, takes snapshot)
enable_testing() {
    print_header "Enabling Testing Mode"

    print_info "This will:"
    echo "  - Take a snapshot of all VMs"
    echo "  - Block internet access to simulate isolated environment"
    echo ""

    ludus range test

    print_success "Testing mode enabled"
}

# Disable testing mode (restores snapshot, enables internet)
disable_testing() {
    print_header "Disabling Testing Mode"

    ludus range untest

    print_success "Testing mode disabled"
}

# Destroy range
destroy_range() {
    print_header "Destroying Range"

    print_warning "This will PERMANENTLY DELETE all VMs in your range!"
    read -p "Are you sure? (type 'yes' to confirm): " confirm

    if [ "$confirm" == "yes" ]; then
        ludus range destroy
        print_success "Range destroyed"
    else
        print_info "Operation cancelled"
    fi
}

# Print usage
usage() {
    echo "CCDC Practice Range Deployment Script"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  check           Check prerequisites (Ludus CLI, templates)"
    echo "  setup           Add Ansible roles and set configuration"
    echo "  build           Build required VM templates"
    echo "  deploy          Deploy the full range"
    echo "  deploy-roles    Deploy only Ansible roles (after VMs exist)"
    echo "  status          Show range status and connection info"
    echo "  snapshot [name] Take a snapshot (default: pre-training)"
    echo "  restore [name]  Restore from snapshot (default: pre-training)"
    echo "  test            Enable testing mode (snapshot + block internet)"
    echo "  untest          Disable testing mode (restore + enable internet)"
    echo "  destroy         Destroy the entire range"
    echo "  full            Full deployment (check + setup + deploy)"
    echo ""
    echo "Examples:"
    echo "  $0 check        # Verify prerequisites"
    echo "  $0 full         # Complete deployment"
    echo "  $0 test         # Start a training exercise"
    echo "  $0 untest       # Reset after exercise"
    echo ""
}

# Main
main() {
    case "${1:-}" in
        check)
            print_header "Checking Prerequisites"
            check_ludus
            check_templates
            check_range_status
            ;;
        setup)
            check_ludus
            add_roles
            set_config
            ;;
        build)
            check_ludus
            build_templates
            ;;
        deploy)
            check_ludus
            deploy_range
            show_connection_info
            ;;
        deploy-roles)
            check_ludus
            deploy_roles_only
            ;;
        status)
            check_ludus
            show_connection_info
            ;;
        snapshot)
            check_ludus
            take_snapshot "${2:-pre-training}"
            ;;
        restore)
            check_ludus
            restore_snapshot "${2:-pre-training}"
            ;;
        test)
            check_ludus
            enable_testing
            ;;
        untest)
            check_ludus
            disable_testing
            ;;
        destroy)
            check_ludus
            destroy_range
            ;;
        full)
            print_header "Full CCDC Range Deployment"
            check_ludus
            check_templates
            add_roles
            set_config
            deploy_range
            show_connection_info
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
