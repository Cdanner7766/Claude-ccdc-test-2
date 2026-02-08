#!/bin/bash
#===============================================================================
# Linux Vulnerability Scanner and Remediation Tool
# For CCDC Practice Range - Blue Team Training
#
# This script scans for common Linux security vulnerabilities and offers
# interactive remediation with user authorization.
#
# Usage: sudo ./linux-vuln-scanner.sh [OPTIONS]
#
# Options:
#   --scan-only      Only scan, don't offer fixes
#   --category CAT   Scan specific category (ssh, firewall, users, web, db, files, services, network, all)
#   --auto-backup    Automatically create backups before fixes
#   --report FILE    Save report to file
#   --no-color       Disable colored output
#   -h, --help       Show this help message
#
# Author: CCDC Practice Range
# Version: 1.0.0
#===============================================================================

set -o pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
VERSION="1.0.0"
SCRIPT_NAME=$(basename "$0")
LOG_DIR="/var/log/vuln-scanner"
BACKUP_DIR="/var/backups/vuln-scanner"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/scan_${TIMESTAMP}.log"
REPORT_FILE=""
SCAN_ONLY=false
AUTO_BACKUP=false
USE_COLOR=true
SELECTED_CATEGORY="all"

# Vulnerability counters
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0
INFO_COUNT=0
FIXED_COUNT=0
SKIPPED_COUNT=0

#-------------------------------------------------------------------------------
# Color Definitions
#-------------------------------------------------------------------------------
setup_colors() {
    if [[ "$USE_COLOR" == true ]] && [[ -t 1 ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[0;37m'
        BOLD='\033[1m'
        UNDERLINE='\033[4m'
        NC='\033[0m' # No Color
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        MAGENTA=''
        CYAN=''
        WHITE=''
        BOLD=''
        UNDERLINE=''
        NC=''
    fi
}

#-------------------------------------------------------------------------------
# Utility Functions
#-------------------------------------------------------------------------------
print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
 _     _                    __     __    _         ____
| |   (_)_ __  _   ___  __ \ \   / /   _| |_ __   / ___|  ___ __ _ _ __  _ __   ___ _ __
| |   | | '_ \| | | \ \/ /  \ \ / / | | | | '_ \  \___ \ / __/ _` | '_ \| '_ \ / _ \ '__|
| |___| | | | | |_| |>  <    \ V /| |_| | | | | |  ___) | (_| (_| | | | | | | |  __/ |
|_____|_|_| |_|\__,_/_/\_\    \_/  \__,_|_|_| |_| |____/ \___\__,_|_| |_|_| |_|\___|_|

EOF
    echo -e "${NC}"
    echo -e "${BOLD}Linux Vulnerability Scanner v${VERSION}${NC}"
    echo -e "${YELLOW}CCDC Practice Range - Blue Team Training Tool${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${BLUE}┌──────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${BLUE}│${NC} ${BOLD}${WHITE}$title${NC}"
    echo -e "${BOLD}${BLUE}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

print_finding() {
    local severity="$1"
    local vuln_id="$2"
    local title="$3"

    case "$severity" in
        CRITICAL)
            echo -e "${RED}${BOLD}[CRITICAL]${NC} ${RED}$vuln_id: $title${NC}"
            ((CRITICAL_COUNT++))
            ;;
        HIGH)
            echo -e "${MAGENTA}${BOLD}[HIGH]${NC} ${MAGENTA}$vuln_id: $title${NC}"
            ((HIGH_COUNT++))
            ;;
        MEDIUM)
            echo -e "${YELLOW}${BOLD}[MEDIUM]${NC} ${YELLOW}$vuln_id: $title${NC}"
            ((MEDIUM_COUNT++))
            ;;
        LOW)
            echo -e "${CYAN}${BOLD}[LOW]${NC} ${CYAN}$vuln_id: $title${NC}"
            ((LOW_COUNT++))
            ;;
        INFO)
            echo -e "${BLUE}${BOLD}[INFO]${NC} ${BLUE}$vuln_id: $title${NC}"
            ((INFO_COUNT++))
            ;;
    esac

    log_message "$severity" "$vuln_id: $title"
}

print_ok() {
    local message="$1"
    echo -e "${GREEN}[✓]${NC} $message"
}

print_info() {
    local message="$1"
    echo -e "${BLUE}[i]${NC} $message"
}

create_backup() {
    local file="$1"
    local backup_name="$2"

    if [[ -f "$file" ]]; then
        local backup_path="${BACKUP_DIR}/${backup_name}_${TIMESTAMP}"
        mkdir -p "$BACKUP_DIR"
        cp "$file" "$backup_path"
        echo "$backup_path"
        log_message "INFO" "Created backup: $backup_path"
    fi
}

prompt_fix() {
    local vuln_id="$1"
    local description="$2"
    local changes="$3"
    local revert_info="$4"
    local fix_function="$5"

    if [[ "$SCAN_ONLY" == true ]]; then
        return 1
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${WHITE}Vulnerability Details: $vuln_id${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Description:${NC}"
    echo -e "  $description"
    echo ""
    echo -e "${YELLOW}What will be changed:${NC}"
    echo -e "  $changes"
    echo ""
    echo -e "${GREEN}How to revert:${NC}"
    echo -e "  $revert_info"
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    while true; do
        echo -e -n "${BOLD}Apply this fix? [y]es / [n]o / [s]kip all / [q]uit: ${NC}"
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS])
                log_message "INFO" "User authorized fix for $vuln_id"
                $fix_function
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}${BOLD}[✓] Fix applied successfully${NC}"
                    ((FIXED_COUNT++))
                    log_message "INFO" "Fix applied for $vuln_id"
                else
                    echo -e "${RED}${BOLD}[✗] Fix failed - please review manually${NC}"
                    log_message "ERROR" "Fix failed for $vuln_id"
                fi
                return 0
                ;;
            [nN]|[nN][oO])
                echo -e "${YELLOW}[→] Skipped${NC}"
                ((SKIPPED_COUNT++))
                log_message "INFO" "User skipped fix for $vuln_id"
                return 1
                ;;
            [sS])
                echo -e "${YELLOW}[→] Skipping all remaining fixes${NC}"
                SCAN_ONLY=true
                ((SKIPPED_COUNT++))
                return 1
                ;;
            [qQ])
                echo -e "${RED}Exiting...${NC}"
                print_summary
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please enter y, n, s, or q.${NC}"
                ;;
        esac
    done
}

#-------------------------------------------------------------------------------
# SSH Security Checks
#-------------------------------------------------------------------------------
check_ssh_security() {
    print_section "SSH Configuration Security"

    local sshd_config="/etc/ssh/sshd_config"

    if [[ ! -f "$sshd_config" ]]; then
        print_info "SSH server not installed - skipping SSH checks"
        return
    fi

    # Check for root login
    local root_login=$(grep -E "^PermitRootLogin" "$sshd_config" 2>/dev/null | awk '{print $2}')
    if [[ "$root_login" == "yes" ]] || [[ -z "$root_login" && $(grep -c "^#PermitRootLogin" "$sshd_config") -gt 0 ]]; then
        print_finding "CRITICAL" "SSH-001" "Root login is permitted via SSH"

        prompt_fix "SSH-001" \
            "Allowing root login via SSH is dangerous. Attackers who compromise root credentials
  can directly access the system. This is against CIS Benchmark recommendations and
  allows for brute-force attacks against the root account." \
            "The file /etc/ssh/sshd_config will be modified to set 'PermitRootLogin no'.
  SSH service will be restarted." \
            "To revert: Edit /etc/ssh/sshd_config and set 'PermitRootLogin yes' or restore from
  backup at ${BACKUP_DIR}/sshd_config_${TIMESTAMP}
  Then run: sudo systemctl restart sshd" \
            fix_ssh_root_login
    else
        print_ok "Root login is disabled"
    fi

    # Check for password authentication
    local pass_auth=$(grep -E "^PasswordAuthentication" "$sshd_config" 2>/dev/null | awk '{print $2}')
    if [[ "$pass_auth" == "yes" ]] || [[ -z "$pass_auth" ]]; then
        print_finding "MEDIUM" "SSH-002" "Password authentication is enabled"

        prompt_fix "SSH-002" \
            "Password authentication is less secure than key-based authentication. It's vulnerable
  to brute-force attacks and credential theft. Key-based authentication is recommended." \
            "The file /etc/ssh/sshd_config will be modified to set 'PasswordAuthentication no'.
  ${RED}WARNING: Ensure you have SSH key access before applying this fix!${NC}
  SSH service will be restarted." \
            "To revert: Edit /etc/ssh/sshd_config and set 'PasswordAuthentication yes'
  Then run: sudo systemctl restart sshd" \
            fix_ssh_password_auth
    else
        print_ok "Password authentication is disabled (key-based auth only)"
    fi

    # Check for empty passwords
    local empty_pass=$(grep -E "^PermitEmptyPasswords" "$sshd_config" 2>/dev/null | awk '{print $2}')
    if [[ "$empty_pass" == "yes" ]]; then
        print_finding "CRITICAL" "SSH-003" "Empty passwords are permitted"

        prompt_fix "SSH-003" \
            "Allowing empty passwords is extremely dangerous. Any account without a password
  can be accessed remotely. This should never be enabled on any system." \
            "The file /etc/ssh/sshd_config will be modified to set 'PermitEmptyPasswords no'.
  SSH service will be restarted." \
            "To revert: Edit /etc/ssh/sshd_config and set 'PermitEmptyPasswords yes'
  Then run: sudo systemctl restart sshd" \
            fix_ssh_empty_passwords
    else
        print_ok "Empty passwords are not permitted"
    fi

    # Check for X11 forwarding
    local x11_fwd=$(grep -E "^X11Forwarding" "$sshd_config" 2>/dev/null | awk '{print $2}')
    if [[ "$x11_fwd" == "yes" ]]; then
        print_finding "LOW" "SSH-004" "X11 forwarding is enabled"

        prompt_fix "SSH-004" \
            "X11 forwarding can be exploited to tunnel graphical applications and potentially
  execute malicious code. Unless specifically needed, it should be disabled." \
            "The file /etc/ssh/sshd_config will be modified to set 'X11Forwarding no'.
  SSH service will be restarted." \
            "To revert: Edit /etc/ssh/sshd_config and set 'X11Forwarding yes'
  Then run: sudo systemctl restart sshd" \
            fix_ssh_x11_forwarding
    else
        print_ok "X11 forwarding is disabled"
    fi

    # Check SSH protocol version
    local protocol=$(grep -E "^Protocol" "$sshd_config" 2>/dev/null | awk '{print $2}')
    if [[ "$protocol" == "1" ]] || [[ "$protocol" == "1,2" ]]; then
        print_finding "CRITICAL" "SSH-005" "SSH Protocol 1 is enabled (insecure)"

        prompt_fix "SSH-005" \
            "SSH Protocol 1 has known cryptographic weaknesses and should never be used.
  It's vulnerable to man-in-the-middle attacks and other exploits." \
            "The file /etc/ssh/sshd_config will be modified to set 'Protocol 2'.
  SSH service will be restarted." \
            "To revert: Edit /etc/ssh/sshd_config and restore the Protocol setting
  Then run: sudo systemctl restart sshd" \
            fix_ssh_protocol
    else
        print_ok "SSH Protocol 2 only (or not explicitly set, defaults to 2)"
    fi

    # Check MaxAuthTries
    local max_auth=$(grep -E "^MaxAuthTries" "$sshd_config" 2>/dev/null | awk '{print $2}')
    if [[ -z "$max_auth" ]] || [[ "$max_auth" -gt 6 ]]; then
        print_finding "MEDIUM" "SSH-006" "MaxAuthTries is not set or too high (${max_auth:-default})"

        prompt_fix "SSH-006" \
            "A high MaxAuthTries value allows more brute-force attempts before disconnection.
  CIS recommends setting this to 4 or less." \
            "The file /etc/ssh/sshd_config will be modified to set 'MaxAuthTries 4'.
  SSH service will be restarted." \
            "To revert: Edit /etc/ssh/sshd_config and remove or change MaxAuthTries
  Then run: sudo systemctl restart sshd" \
            fix_ssh_max_auth
    else
        print_ok "MaxAuthTries is appropriately configured ($max_auth)"
    fi

    # Check for SSH on non-standard port
    local ssh_port=$(grep -E "^Port" "$sshd_config" 2>/dev/null | awk '{print $2}')
    if [[ -z "$ssh_port" ]] || [[ "$ssh_port" == "22" ]]; then
        print_finding "INFO" "SSH-007" "SSH running on default port 22"
        print_info "  Consider changing to a non-standard port to reduce automated attacks"
    else
        print_ok "SSH running on non-standard port ($ssh_port)"
    fi

    # Check ClientAliveInterval
    local alive_interval=$(grep -E "^ClientAliveInterval" "$sshd_config" 2>/dev/null | awk '{print $2}')
    if [[ -z "$alive_interval" ]] || [[ "$alive_interval" -eq 0 ]]; then
        print_finding "LOW" "SSH-008" "ClientAliveInterval not configured (idle sessions won't timeout)"

        prompt_fix "SSH-008" \
            "Without ClientAliveInterval, idle SSH sessions remain open indefinitely.
  This can leave sessions vulnerable if a user walks away from their terminal." \
            "The file /etc/ssh/sshd_config will be modified to set 'ClientAliveInterval 300'
  and 'ClientAliveCountMax 2' (10 minute timeout). SSH service will be restarted." \
            "To revert: Edit /etc/ssh/sshd_config and remove ClientAliveInterval/ClientAliveCountMax
  Then run: sudo systemctl restart sshd" \
            fix_ssh_alive_interval
    else
        print_ok "ClientAliveInterval is configured ($alive_interval seconds)"
    fi

    # Check for weak ciphers
    local ciphers=$(grep -E "^Ciphers" "$sshd_config" 2>/dev/null)
    if echo "$ciphers" | grep -qE "(arcfour|3des|blowfish)" 2>/dev/null; then
        print_finding "HIGH" "SSH-009" "Weak SSH ciphers are enabled"

        prompt_fix "SSH-009" \
            "Weak ciphers like arcfour, 3des-cbc, and blowfish-cbc have known vulnerabilities.
  Only strong, modern ciphers should be used." \
            "The file /etc/ssh/sshd_config will be modified to use only strong ciphers:
  chacha20-poly1305, aes256-gcm, aes128-gcm, aes256-ctr, aes192-ctr, aes128-ctr" \
            "To revert: Edit /etc/ssh/sshd_config and remove or modify the Ciphers line
  Then run: sudo systemctl restart sshd" \
            fix_ssh_ciphers
    else
        print_ok "No weak ciphers detected in configuration"
    fi

    # Check for AllowUsers/AllowGroups
    local allow_users=$(grep -E "^AllowUsers|^AllowGroups" "$sshd_config" 2>/dev/null)
    if [[ -z "$allow_users" ]]; then
        print_finding "MEDIUM" "SSH-010" "No AllowUsers or AllowGroups restriction configured"
        print_info "  Consider restricting SSH access to specific users/groups"
    else
        print_ok "SSH access restricted: $allow_users"
    fi
}

fix_ssh_root_login() {
    create_backup "/etc/ssh/sshd_config" "sshd_config"
    if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
        sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    else
        echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
}

fix_ssh_password_auth() {
    create_backup "/etc/ssh/sshd_config" "sshd_config"
    if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    else
        echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
}

fix_ssh_empty_passwords() {
    create_backup "/etc/ssh/sshd_config" "sshd_config"
    if grep -q "^PermitEmptyPasswords" /etc/ssh/sshd_config; then
        sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    else
        echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
}

fix_ssh_x11_forwarding() {
    create_backup "/etc/ssh/sshd_config" "sshd_config"
    if grep -q "^X11Forwarding" /etc/ssh/sshd_config; then
        sed -i 's/^X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
    else
        echo "X11Forwarding no" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
}

fix_ssh_protocol() {
    create_backup "/etc/ssh/sshd_config" "sshd_config"
    if grep -q "^Protocol" /etc/ssh/sshd_config; then
        sed -i 's/^Protocol.*/Protocol 2/' /etc/ssh/sshd_config
    else
        echo "Protocol 2" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
}

fix_ssh_max_auth() {
    create_backup "/etc/ssh/sshd_config" "sshd_config"
    if grep -q "^MaxAuthTries" /etc/ssh/sshd_config; then
        sed -i 's/^MaxAuthTries.*/MaxAuthTries 4/' /etc/ssh/sshd_config
    else
        echo "MaxAuthTries 4" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
}

fix_ssh_alive_interval() {
    create_backup "/etc/ssh/sshd_config" "sshd_config"

    if grep -q "^ClientAliveInterval" /etc/ssh/sshd_config; then
        sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
    else
        echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
    fi

    if grep -q "^ClientAliveCountMax" /etc/ssh/sshd_config; then
        sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
    else
        echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
    fi

    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
}

fix_ssh_ciphers() {
    create_backup "/etc/ssh/sshd_config" "sshd_config"
    local strong_ciphers="chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"

    if grep -q "^Ciphers" /etc/ssh/sshd_config; then
        sed -i "s/^Ciphers.*/Ciphers ${strong_ciphers}/" /etc/ssh/sshd_config
    else
        echo "Ciphers ${strong_ciphers}" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
}

#-------------------------------------------------------------------------------
# Firewall Security Checks
#-------------------------------------------------------------------------------
check_firewall_security() {
    print_section "Firewall Configuration Security"

    # Check UFW status
    if command -v ufw &>/dev/null; then
        local ufw_status=$(ufw status 2>/dev/null | head -1)
        if echo "$ufw_status" | grep -q "inactive"; then
            print_finding "CRITICAL" "FW-001" "UFW firewall is disabled"

            prompt_fix "FW-001" \
                "The UFW firewall is disabled, leaving the system exposed to network attacks.
  A firewall is essential for controlling incoming and outgoing traffic." \
                "UFW will be enabled with default deny incoming and allow outgoing policy.
  SSH (port 22) will be allowed before enabling to prevent lockout." \
                "To revert: Run 'sudo ufw disable'
  To check status: Run 'sudo ufw status verbose'" \
                fix_ufw_enable
        else
            print_ok "UFW firewall is active"

            # Check default policies
            local default_incoming=$(ufw status verbose 2>/dev/null | grep "Default:" | grep "incoming" | awk '{print $2}')
            if [[ "$default_incoming" != "deny" ]]; then
                print_finding "HIGH" "FW-002" "UFW default incoming policy is not 'deny' ($default_incoming)"

                prompt_fix "FW-002" \
                    "The default incoming policy should be 'deny' to block all unsolicited traffic.
  Only explicitly allowed services should be accessible." \
                    "UFW default incoming policy will be set to 'deny'.
  Existing rules will be preserved." \
                    "To revert: Run 'sudo ufw default allow incoming'" \
                    fix_ufw_default_deny
            else
                print_ok "UFW default incoming policy is 'deny'"
            fi
        fi
    elif command -v firewalld &>/dev/null; then
        if ! systemctl is-active --quiet firewalld; then
            print_finding "CRITICAL" "FW-001" "Firewalld is not running"

            prompt_fix "FW-001" \
                "The firewalld service is not running, leaving the system exposed to network attacks.
  A firewall is essential for controlling incoming and outgoing traffic." \
                "Firewalld will be started and enabled to run at boot.
  Default zone will be set to 'public' which blocks most incoming traffic." \
                "To revert: Run 'sudo systemctl stop firewalld && sudo systemctl disable firewalld'" \
                fix_firewalld_enable
        else
            print_ok "Firewalld is active"
        fi
    elif command -v iptables &>/dev/null; then
        local iptables_rules=$(iptables -L -n 2>/dev/null | wc -l)
        if [[ "$iptables_rules" -lt 10 ]]; then
            print_finding "HIGH" "FW-003" "iptables has minimal/no rules configured"
            print_info "  Consider implementing proper iptables rules or using UFW/firewalld"
        else
            print_ok "iptables has rules configured ($iptables_rules lines)"
        fi
    else
        print_finding "CRITICAL" "FW-000" "No firewall detected (UFW, firewalld, or iptables)"
        print_info "  Install and configure a firewall: sudo apt install ufw && sudo ufw enable"
    fi

    # Check for common vulnerable open ports
    if command -v ss &>/dev/null; then
        echo ""
        print_info "Checking for potentially dangerous open ports..."

        # Check for Telnet
        if ss -tlnp 2>/dev/null | grep -q ":23 "; then
            print_finding "CRITICAL" "FW-010" "Telnet service (port 23) is listening - INSECURE"
            print_info "  Telnet transmits data in plaintext. Use SSH instead."
        fi

        # Check for FTP
        if ss -tlnp 2>/dev/null | grep -q ":21 "; then
            print_finding "HIGH" "FW-011" "FTP service (port 21) is listening"
            print_info "  FTP transmits credentials in plaintext. Consider SFTP or FTPS."
        fi

        # Check for rsh/rlogin
        if ss -tlnp 2>/dev/null | grep -qE ":(513|514) "; then
            print_finding "CRITICAL" "FW-012" "rsh/rlogin services are listening - INSECURE"
            print_info "  These services have no encryption. Use SSH instead."
        fi

        # Check for SNMP
        if ss -ulnp 2>/dev/null | grep -q ":161 "; then
            print_finding "MEDIUM" "FW-013" "SNMP service (port 161) is listening"
            print_info "  Ensure SNMP v3 is configured with authentication and encryption."
        fi

        # Check for NFS
        if ss -tlnp 2>/dev/null | grep -q ":2049 "; then
            print_finding "MEDIUM" "FW-014" "NFS service (port 2049) is listening"
            print_info "  Ensure NFS exports are properly secured and restricted."
        fi

        # Check for MySQL exposed externally
        if ss -tlnp 2>/dev/null | grep ":3306 " | grep -v "127.0.0.1"; then
            print_finding "HIGH" "FW-015" "MySQL is listening on external interface"
            print_info "  Database should typically only listen on localhost."
        fi

        # Check for PostgreSQL exposed externally
        if ss -tlnp 2>/dev/null | grep ":5432 " | grep -v "127.0.0.1"; then
            print_finding "HIGH" "FW-016" "PostgreSQL is listening on external interface"
            print_info "  Database should typically only listen on localhost."
        fi

        # Check for Redis exposed externally
        if ss -tlnp 2>/dev/null | grep ":6379 " | grep -v "127.0.0.1"; then
            print_finding "CRITICAL" "FW-017" "Redis is listening on external interface"
            print_info "  Redis should never be exposed externally without authentication."
        fi

        # Check for MongoDB exposed externally
        if ss -tlnp 2>/dev/null | grep ":27017 " | grep -v "127.0.0.1"; then
            print_finding "CRITICAL" "FW-018" "MongoDB is listening on external interface"
            print_info "  MongoDB should not be exposed externally without authentication."
        fi
    fi
}

fix_ufw_enable() {
    # Allow SSH first to prevent lockout
    ufw allow ssh
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    # Enable UFW (--force to skip confirmation)
    echo "y" | ufw enable
}

fix_ufw_default_deny() {
    ufw default deny incoming
}

fix_firewalld_enable() {
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --set-default-zone=public
}

#-------------------------------------------------------------------------------
# User Account Security Checks
#-------------------------------------------------------------------------------
check_user_security() {
    print_section "User Account Security"

    # Check for users with UID 0 (root equivalent)
    local root_users=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)
    if [[ -n "$root_users" ]]; then
        print_finding "CRITICAL" "USER-001" "Non-root users with UID 0 found: $root_users"
        print_info "  Only root should have UID 0. These accounts have full system access."
    else
        print_ok "No non-root users with UID 0"
    fi

    # Check for users with empty passwords
    if [[ -r /etc/shadow ]]; then
        local empty_pass_users=$(awk -F: '($2 == "" || $2 == "!!" || $2 == "*") && $1 !~ /^(root|sync|shutdown|halt|operator)$/ {print $1}' /etc/shadow 2>/dev/null)
        # Filter out system accounts
        local real_empty_users=""
        for user in $empty_pass_users; do
            local uid=$(id -u "$user" 2>/dev/null)
            if [[ -n "$uid" ]] && [[ "$uid" -ge 1000 ]]; then
                real_empty_users="$real_empty_users $user"
            fi
        done

        if [[ -n "$real_empty_users" ]]; then
            print_finding "CRITICAL" "USER-002" "Users with empty/no password:$real_empty_users"
            print_info "  These accounts can be accessed without a password!"
        else
            print_ok "No regular users with empty passwords"
        fi
    else
        print_info "Cannot read /etc/shadow - run as root for full checks"
    fi

    # Check for users with weak shells
    local users_with_shell=$(awk -F: '$7 ~ /sh$|bash$/ && $3 >= 1000 {print $1":"$7}' /etc/passwd)
    print_info "Users with login shells:"
    echo "$users_with_shell" | while read line; do
        echo "    $line"
    done

    # Check for duplicate UIDs
    local dup_uids=$(cut -d: -f3 /etc/passwd | sort | uniq -d)
    if [[ -n "$dup_uids" ]]; then
        print_finding "HIGH" "USER-003" "Duplicate UIDs found: $dup_uids"
        print_info "  Each user should have a unique UID."
    else
        print_ok "No duplicate UIDs found"
    fi

    # Check for duplicate GIDs
    local dup_gids=$(cut -d: -f3 /etc/group | sort | uniq -d)
    if [[ -n "$dup_gids" ]]; then
        print_finding "MEDIUM" "USER-004" "Duplicate GIDs found: $dup_gids"
    else
        print_ok "No duplicate GIDs found"
    fi

    # Check password aging policies
    local max_days=$(grep "^PASS_MAX_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
    local min_days=$(grep "^PASS_MIN_DAYS" /etc/login.defs 2>/dev/null | awk '{print $2}')
    local warn_age=$(grep "^PASS_WARN_AGE" /etc/login.defs 2>/dev/null | awk '{print $2}')

    if [[ -z "$max_days" ]] || [[ "$max_days" -gt 365 ]] || [[ "$max_days" == "99999" ]]; then
        print_finding "MEDIUM" "USER-005" "Password maximum age not properly configured (${max_days:-not set})"

        prompt_fix "USER-005" \
            "Password aging ensures users regularly change their passwords.
  CIS recommends PASS_MAX_DAYS of 365 or less for regular password rotation." \
            "The file /etc/login.defs will be modified to set PASS_MAX_DAYS to 90.
  This affects only new users; existing users need 'chage' command." \
            "To revert: Edit /etc/login.defs and change PASS_MAX_DAYS back to original value" \
            fix_pass_max_days
    else
        print_ok "Password maximum age is configured ($max_days days)"
    fi

    if [[ -z "$min_days" ]] || [[ "$min_days" -lt 1 ]]; then
        print_finding "LOW" "USER-006" "Password minimum age not set (prevents rapid password cycling)"

        prompt_fix "USER-006" \
            "Without a minimum password age, users can immediately change their password
  multiple times to cycle back to their original password, defeating password history." \
            "The file /etc/login.defs will be modified to set PASS_MIN_DAYS to 1." \
            "To revert: Edit /etc/login.defs and set PASS_MIN_DAYS to 0" \
            fix_pass_min_days
    else
        print_ok "Password minimum age is configured ($min_days days)"
    fi

    # Check for accounts that should be locked
    local system_accounts="daemon bin sys games man lp mail news uucp proxy www-data backup list irc gnats nobody"
    for account in $system_accounts; do
        if id "$account" &>/dev/null; then
            local shell=$(getent passwd "$account" | cut -d: -f7)
            if [[ "$shell" != "/usr/sbin/nologin" ]] && [[ "$shell" != "/bin/false" ]] && [[ "$shell" != "/sbin/nologin" ]]; then
                print_finding "MEDIUM" "USER-007" "System account '$account' has login shell: $shell"
            fi
        fi
    done

    # Check sudo configuration
    if [[ -f /etc/sudoers ]]; then
        if grep -q "NOPASSWD" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
            print_finding "HIGH" "USER-008" "NOPASSWD sudo entries found"
            print_info "  Users can run sudo without password verification:"
            grep "NOPASSWD" /etc/sudoers /etc/sudoers.d/* 2>/dev/null | head -5 | while read line; do
                echo "    $line"
            done
        else
            print_ok "No NOPASSWD sudo entries found"
        fi

        # Check for dangerous sudo configurations
        if grep -qE "ALL.*ALL.*ALL" /etc/sudoers /etc/sudoers.d/* 2>/dev/null | grep -v "^root"; then
            print_finding "MEDIUM" "USER-009" "Overly permissive sudo rules found"
        fi
    fi

    # Check for unauthorized users in sudo/wheel group
    local sudo_group="sudo"
    if ! getent group sudo &>/dev/null; then
        sudo_group="wheel"
    fi

    if getent group "$sudo_group" &>/dev/null; then
        local sudo_members=$(getent group "$sudo_group" | cut -d: -f4)
        print_info "Users in $sudo_group group: ${sudo_members:-none}"
    fi

    # Check for .rhosts and .netrc files
    for home_dir in /home/* /root; do
        if [[ -d "$home_dir" ]]; then
            if [[ -f "$home_dir/.rhosts" ]]; then
                print_finding "CRITICAL" "USER-010" "Found .rhosts file in $home_dir"
                print_info "  .rhosts allows passwordless remote access - should be removed"
            fi
            if [[ -f "$home_dir/.netrc" ]]; then
                print_finding "HIGH" "USER-011" "Found .netrc file in $home_dir"
                print_info "  .netrc may contain plaintext credentials"
            fi
        fi
    done
}

fix_pass_max_days() {
    create_backup "/etc/login.defs" "login.defs"
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
}

fix_pass_min_days() {
    create_backup "/etc/login.defs" "login.defs"
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
}

#-------------------------------------------------------------------------------
# Web Server Security Checks
#-------------------------------------------------------------------------------
check_web_security() {
    print_section "Web Server Security"

    # Check for Apache
    if command -v apache2 &>/dev/null || command -v httpd &>/dev/null; then
        print_info "Apache web server detected"

        local apache_conf=""
        if [[ -f /etc/apache2/apache2.conf ]]; then
            apache_conf="/etc/apache2/apache2.conf"
        elif [[ -f /etc/httpd/conf/httpd.conf ]]; then
            apache_conf="/etc/httpd/conf/httpd.conf"
        fi

        if [[ -n "$apache_conf" ]]; then
            # Check ServerTokens
            local server_tokens=$(grep -E "^ServerTokens" "$apache_conf" /etc/apache2/conf-enabled/* /etc/httpd/conf.d/* 2>/dev/null | head -1 | awk '{print $2}')
            if [[ "$server_tokens" != "Prod" ]] && [[ "$server_tokens" != "ProductOnly" ]]; then
                print_finding "MEDIUM" "WEB-001" "Apache ServerTokens not set to Prod (version info exposed)"

                prompt_fix "WEB-001" \
                    "The Apache server exposes version information in HTTP headers and error pages.
  This helps attackers identify specific vulnerabilities for your version." \
                    "ServerTokens will be set to 'Prod' in Apache security configuration.
  Only the product name (Apache) will be shown, not the version." \
                    "To revert: Edit the Apache config and set 'ServerTokens Full' or remove the line
  Then run: sudo systemctl restart apache2" \
                    fix_apache_servertokens
            else
                print_ok "Apache ServerTokens set to Prod"
            fi

            # Check ServerSignature
            local server_sig=$(grep -E "^ServerSignature" "$apache_conf" /etc/apache2/conf-enabled/* /etc/httpd/conf.d/* 2>/dev/null | head -1 | awk '{print $2}')
            if [[ "$server_sig" != "Off" ]]; then
                print_finding "LOW" "WEB-002" "Apache ServerSignature not disabled"

                prompt_fix "WEB-002" \
                    "ServerSignature adds server version to error pages and directory listings.
  This information helps attackers identify vulnerabilities." \
                    "ServerSignature will be set to 'Off' in Apache configuration." \
                    "To revert: Edit the Apache config and set 'ServerSignature On'
  Then run: sudo systemctl restart apache2" \
                    fix_apache_serversignature
            else
                print_ok "Apache ServerSignature is Off"
            fi

            # Check for directory listing
            if grep -rq "Options.*Indexes" /etc/apache2/ /etc/httpd/ 2>/dev/null | grep -v "#"; then
                print_finding "MEDIUM" "WEB-003" "Directory listing (Indexes) may be enabled"
                print_info "  Check your Apache configuration for 'Options Indexes'"
            fi

            # Check for .htaccess override
            local allow_override=$(grep -E "AllowOverride" "$apache_conf" 2>/dev/null | grep -v "#" | head -1)
            if echo "$allow_override" | grep -q "All"; then
                print_finding "LOW" "WEB-004" "AllowOverride All is enabled (can be security risk)"
            fi
        fi

        # Check if Apache is running as root
        local apache_user=$(ps aux | grep -E "[a]pache2|[h]ttpd" | grep -v root | head -1 | awk '{print $1}')
        if [[ -z "$apache_user" ]]; then
            if ps aux | grep -E "[a]pache2|[h]ttpd" | grep -q root; then
                print_finding "CRITICAL" "WEB-005" "Apache appears to be running as root"
            fi
        else
            print_ok "Apache running as user: $apache_user"
        fi
    fi

    # Check for Nginx
    if command -v nginx &>/dev/null; then
        print_info "Nginx web server detected"

        local nginx_conf="/etc/nginx/nginx.conf"
        if [[ -f "$nginx_conf" ]]; then
            # Check server_tokens
            if ! grep -q "server_tokens off" "$nginx_conf" /etc/nginx/conf.d/* /etc/nginx/sites-enabled/* 2>/dev/null; then
                print_finding "MEDIUM" "WEB-010" "Nginx server_tokens not disabled (version exposed)"

                prompt_fix "WEB-010" \
                    "Nginx exposes version information in HTTP headers by default.
  This helps attackers identify specific vulnerabilities." \
                    "The directive 'server_tokens off;' will be added to nginx.conf." \
                    "To revert: Edit /etc/nginx/nginx.conf and remove 'server_tokens off;'
  Then run: sudo systemctl restart nginx" \
                    fix_nginx_servertokens
            else
                print_ok "Nginx server_tokens is off"
            fi
        fi
    fi

    # Check for PHP vulnerabilities
    local php_ini=""
    for php_path in /etc/php/*/apache2/php.ini /etc/php/*/fpm/php.ini /etc/php.ini; do
        if [[ -f "$php_path" ]]; then
            php_ini="$php_path"
            break
        fi
    done

    if [[ -n "$php_ini" ]]; then
        print_info "PHP configuration found: $php_ini"

        # Check expose_php
        local expose_php=$(grep -E "^expose_php" "$php_ini" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
        if [[ "$expose_php" == "On" ]]; then
            print_finding "LOW" "WEB-020" "PHP version exposed in headers (expose_php = On)"

            prompt_fix "WEB-020" \
                "PHP adds X-Powered-By header exposing the PHP version.
  This information helps attackers target version-specific vulnerabilities." \
                "The php.ini will be modified to set 'expose_php = Off'." \
                "To revert: Edit $php_ini and set 'expose_php = On'
  Then restart Apache/PHP-FPM" \
                fix_php_expose
        else
            print_ok "PHP expose_php is Off"
        fi

        # Check display_errors
        local display_errors=$(grep -E "^display_errors" "$php_ini" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
        if [[ "$display_errors" == "On" ]]; then
            print_finding "HIGH" "WEB-021" "PHP display_errors is On (exposes sensitive info)"

            prompt_fix "WEB-021" \
                "Displaying PHP errors to users can expose sensitive information like
  file paths, database credentials, and code structure to attackers." \
                "The php.ini will be modified to set 'display_errors = Off'.
  Errors will still be logged to the PHP error log." \
                "To revert: Edit $php_ini and set 'display_errors = On'
  Then restart Apache/PHP-FPM" \
                fix_php_display_errors
        else
            print_ok "PHP display_errors is Off"
        fi

        # Check allow_url_include
        local url_include=$(grep -E "^allow_url_include" "$php_ini" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
        if [[ "$url_include" == "On" ]]; then
            print_finding "CRITICAL" "WEB-022" "PHP allow_url_include is On (Remote File Inclusion risk)"

            prompt_fix "WEB-022" \
                "allow_url_include enables Remote File Inclusion (RFI) attacks.
  Attackers can include malicious remote PHP files in your application." \
                "The php.ini will be modified to set 'allow_url_include = Off'." \
                "To revert: Edit $php_ini and set 'allow_url_include = On'
  Then restart Apache/PHP-FPM" \
                fix_php_url_include
        else
            print_ok "PHP allow_url_include is Off"
        fi

        # Check disable_functions
        local disable_funcs=$(grep -E "^disable_functions" "$php_ini" 2>/dev/null | awk -F= '{print $2}')
        if [[ -z "$disable_funcs" ]] || [[ "$disable_funcs" == " " ]]; then
            print_finding "MEDIUM" "WEB-023" "PHP dangerous functions not disabled"
            print_info "  Consider disabling: exec, passthru, shell_exec, system, proc_open, popen"
        else
            print_ok "PHP has disabled functions configured"
        fi
    fi

    # Check for common vulnerable files in webroot
    local webroot="/var/www/html"
    if [[ -d "$webroot" ]]; then
        print_info "Checking webroot: $webroot"

        # Check for phpinfo
        if find "$webroot" -name "phpinfo.php" -o -name "info.php" 2>/dev/null | grep -q .; then
            print_finding "HIGH" "WEB-030" "phpinfo.php or info.php found in webroot"
            print_info "  These files expose sensitive server configuration"
        fi

        # Check for backup files
        local backup_files=$(find "$webroot" -name "*.bak" -o -name "*.old" -o -name "*.sql" -o -name "*~" -o -name "*.swp" 2>/dev/null | head -5)
        if [[ -n "$backup_files" ]]; then
            print_finding "HIGH" "WEB-031" "Backup/temporary files found in webroot"
            echo "$backup_files" | while read file; do
                echo "    $file"
            done
        fi

        # Check for .git directory
        if [[ -d "$webroot/.git" ]]; then
            print_finding "CRITICAL" "WEB-032" ".git directory found in webroot (source code exposure)"

            prompt_fix "WEB-032" \
                "The .git directory contains the entire repository history including
  potentially sensitive configuration files and credentials." \
                "The .git directory will be removed from $webroot." \
                "To revert: If you need the git repo, restore from backup or re-clone" \
                fix_webroot_git
        fi

        # Check for config files
        local config_files=$(find "$webroot" -name "config.php" -o -name "settings.php" -o -name "database.php" -o -name "*.conf" 2>/dev/null)
        if [[ -n "$config_files" ]]; then
            print_finding "MEDIUM" "WEB-033" "Configuration files found in webroot"
            print_info "  These should be moved outside webroot or protected:"
            echo "$config_files" | head -5 | while read file; do
                echo "    $file"
            done
        fi

        # Check for world-writable directories
        local writable_dirs=$(find "$webroot" -type d -perm -0002 2>/dev/null | head -5)
        if [[ -n "$writable_dirs" ]]; then
            print_finding "HIGH" "WEB-034" "World-writable directories in webroot"
            echo "$writable_dirs" | while read dir; do
                echo "    $dir"
            done

            prompt_fix "WEB-034" \
                "World-writable directories allow any user to create or modify files,
  potentially allowing attackers to upload malicious scripts." \
                "World-writable permission will be removed from directories in webroot.
  Owner write permission will be preserved." \
                "To revert: Run 'chmod o+w <directory>' for each directory that needs it" \
                fix_webroot_writable
        fi
    fi
}

fix_apache_servertokens() {
    local security_conf="/etc/apache2/conf-available/security.conf"
    if [[ -f "$security_conf" ]]; then
        create_backup "$security_conf" "apache_security.conf"
        sed -i 's/^ServerTokens.*/ServerTokens Prod/' "$security_conf"
    else
        echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
    fi
    systemctl restart apache2 2>/dev/null || systemctl restart httpd 2>/dev/null
}

fix_apache_serversignature() {
    local security_conf="/etc/apache2/conf-available/security.conf"
    if [[ -f "$security_conf" ]]; then
        create_backup "$security_conf" "apache_security.conf"
        sed -i 's/^ServerSignature.*/ServerSignature Off/' "$security_conf"
    else
        echo "ServerSignature Off" >> /etc/apache2/apache2.conf
    fi
    systemctl restart apache2 2>/dev/null || systemctl restart httpd 2>/dev/null
}

fix_nginx_servertokens() {
    create_backup "/etc/nginx/nginx.conf" "nginx.conf"
    if grep -q "server_tokens" /etc/nginx/nginx.conf; then
        sed -i 's/server_tokens.*/server_tokens off;/' /etc/nginx/nginx.conf
    else
        sed -i '/http {/a\    server_tokens off;' /etc/nginx/nginx.conf
    fi
    systemctl restart nginx
}

fix_php_expose() {
    for php_ini in /etc/php/*/apache2/php.ini /etc/php/*/fpm/php.ini /etc/php.ini; do
        if [[ -f "$php_ini" ]]; then
            create_backup "$php_ini" "php.ini"
            sed -i 's/^expose_php.*/expose_php = Off/' "$php_ini"
        fi
    done
    systemctl restart apache2 2>/dev/null
    systemctl restart php*-fpm 2>/dev/null
}

fix_php_display_errors() {
    for php_ini in /etc/php/*/apache2/php.ini /etc/php/*/fpm/php.ini /etc/php.ini; do
        if [[ -f "$php_ini" ]]; then
            create_backup "$php_ini" "php.ini"
            sed -i 's/^display_errors.*/display_errors = Off/' "$php_ini"
        fi
    done
    systemctl restart apache2 2>/dev/null
    systemctl restart php*-fpm 2>/dev/null
}

fix_php_url_include() {
    for php_ini in /etc/php/*/apache2/php.ini /etc/php/*/fpm/php.ini /etc/php.ini; do
        if [[ -f "$php_ini" ]]; then
            create_backup "$php_ini" "php.ini"
            sed -i 's/^allow_url_include.*/allow_url_include = Off/' "$php_ini"
        fi
    done
    systemctl restart apache2 2>/dev/null
    systemctl restart php*-fpm 2>/dev/null
}

fix_webroot_git() {
    rm -rf /var/www/html/.git
}

fix_webroot_writable() {
    find /var/www/html -type d -perm -0002 -exec chmod o-w {} \;
}

#-------------------------------------------------------------------------------
# Database Security Checks
#-------------------------------------------------------------------------------
check_database_security() {
    print_section "Database Security"

    # Check MySQL/MariaDB
    if command -v mysql &>/dev/null; then
        print_info "MySQL/MariaDB detected"

        # Check if MySQL is running
        if systemctl is-active --quiet mysql 2>/dev/null || systemctl is-active --quiet mariadb 2>/dev/null; then
            print_ok "MySQL/MariaDB service is running"

            # Check bind-address
            local mysql_conf=""
            for conf in /etc/mysql/mariadb.conf.d/*.cnf /etc/mysql/mysql.conf.d/*.cnf /etc/my.cnf /etc/mysql/my.cnf; do
                if [[ -f "$conf" ]]; then
                    mysql_conf="$conf"
                    break
                fi
            done

            if [[ -n "$mysql_conf" ]]; then
                local bind_addr=$(grep -E "^bind-address" "$mysql_conf" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
                if [[ "$bind_addr" == "0.0.0.0" ]] || [[ -z "$bind_addr" ]]; then
                    print_finding "HIGH" "DB-001" "MySQL is listening on all interfaces"

                    prompt_fix "DB-001" \
                        "MySQL is accepting connections from any network interface.
  This exposes the database to network-based attacks. It should typically
  only listen on localhost (127.0.0.1) unless remote access is required." \
                        "MySQL will be configured to bind only to 127.0.0.1.
  Remote connections will no longer be possible." \
                        "To revert: Edit MySQL config and set 'bind-address = 0.0.0.0'
  Then run: sudo systemctl restart mysql" \
                        fix_mysql_bind
                elif [[ "$bind_addr" == "127.0.0.1" ]]; then
                    print_ok "MySQL bound to localhost only"
                fi

                # Check local_infile
                local local_infile=$(grep -E "^local_infile" "$mysql_conf" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
                if [[ "$local_infile" != "0" ]] && [[ "$local_infile" != "OFF" ]]; then
                    print_finding "MEDIUM" "DB-002" "MySQL local_infile may be enabled (file read risk)"
                fi
            fi

            # Try to connect without password (common vulnerability)
            if mysql -u root -e "SELECT 1" &>/dev/null; then
                print_finding "CRITICAL" "DB-003" "MySQL root can login without password!"
                print_info "  Run 'mysql_secure_installation' to set a root password"
            fi

            # Check for anonymous users (requires root access to MySQL)
            if mysql -u root -e "SELECT User,Host FROM mysql.user WHERE User=''" &>/dev/null 2>&1; then
                local anon_users=$(mysql -u root -N -e "SELECT COUNT(*) FROM mysql.user WHERE User=''" 2>/dev/null)
                if [[ "$anon_users" -gt 0 ]]; then
                    print_finding "HIGH" "DB-004" "MySQL has anonymous user accounts"
                    print_info "  Run 'mysql_secure_installation' to remove anonymous users"
                fi
            fi

            # Check for test database
            if mysql -u root -e "SHOW DATABASES LIKE 'test'" 2>/dev/null | grep -q test; then
                print_finding "LOW" "DB-005" "MySQL test database exists"
                print_info "  The test database is publicly accessible and should be removed"
            fi
        fi
    fi

    # Check PostgreSQL
    if command -v psql &>/dev/null; then
        print_info "PostgreSQL detected"

        if systemctl is-active --quiet postgresql 2>/dev/null; then
            print_ok "PostgreSQL service is running"

            # Check pg_hba.conf for trust authentication
            local pg_hba=$(find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -1)
            if [[ -f "$pg_hba" ]]; then
                if grep -qE "^\s*(local|host).*trust" "$pg_hba"; then
                    print_finding "CRITICAL" "DB-010" "PostgreSQL has 'trust' authentication (no password required)"
                    print_info "  Check $pg_hba and change 'trust' to 'md5' or 'scram-sha-256'"
                fi

                if grep -qE "^\s*host.*0\.0\.0\.0/0" "$pg_hba"; then
                    print_finding "HIGH" "DB-011" "PostgreSQL accepts connections from any IP"
                fi
            fi

            # Check listen_addresses
            local pg_conf=$(find /etc/postgresql -name "postgresql.conf" 2>/dev/null | head -1)
            if [[ -f "$pg_conf" ]]; then
                local listen_addr=$(grep -E "^listen_addresses" "$pg_conf" 2>/dev/null | awk -F\' '{print $2}')
                if [[ "$listen_addr" == "*" ]]; then
                    print_finding "HIGH" "DB-012" "PostgreSQL listening on all interfaces"
                fi
            fi
        fi
    fi

    # Check MongoDB
    if command -v mongod &>/dev/null; then
        print_info "MongoDB detected"

        if systemctl is-active --quiet mongod 2>/dev/null; then
            local mongo_conf="/etc/mongod.conf"
            if [[ -f "$mongo_conf" ]]; then
                # Check bindIp
                local bind_ip=$(grep -E "^\s*bindIp:" "$mongo_conf" | awk '{print $2}')
                if [[ "$bind_ip" == "0.0.0.0" ]]; then
                    print_finding "CRITICAL" "DB-020" "MongoDB listening on all interfaces"
                fi

                # Check authorization
                if ! grep -q "authorization: enabled" "$mongo_conf"; then
                    print_finding "CRITICAL" "DB-021" "MongoDB authorization is not enabled"
                    print_info "  Anyone can connect without authentication!"
                fi
            fi
        fi
    fi

    # Check Redis
    if command -v redis-server &>/dev/null; then
        print_info "Redis detected"

        if systemctl is-active --quiet redis 2>/dev/null || systemctl is-active --quiet redis-server 2>/dev/null; then
            local redis_conf="/etc/redis/redis.conf"
            if [[ -f "$redis_conf" ]]; then
                # Check bind address
                local redis_bind=$(grep -E "^bind" "$redis_conf" | awk '{print $2}')
                if [[ -z "$redis_bind" ]] || [[ "$redis_bind" == "0.0.0.0" ]]; then
                    print_finding "CRITICAL" "DB-030" "Redis listening on all interfaces"
                fi

                # Check requirepass
                if ! grep -qE "^requirepass" "$redis_conf"; then
                    print_finding "CRITICAL" "DB-031" "Redis has no password configured"
                    print_info "  Anyone can connect and run commands!"
                fi

                # Check protected-mode
                local protected=$(grep -E "^protected-mode" "$redis_conf" | awk '{print $2}')
                if [[ "$protected" == "no" ]]; then
                    print_finding "HIGH" "DB-032" "Redis protected-mode is disabled"
                fi
            fi
        fi
    fi
}

fix_mysql_bind() {
    local mysql_conf=""
    for conf in /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mysql.conf.d/mysqld.cnf /etc/my.cnf; do
        if [[ -f "$conf" ]]; then
            mysql_conf="$conf"
            break
        fi
    done

    if [[ -n "$mysql_conf" ]]; then
        create_backup "$mysql_conf" "mysql.conf"
        if grep -q "^bind-address" "$mysql_conf"; then
            sed -i 's/^bind-address.*/bind-address = 127.0.0.1/' "$mysql_conf"
        else
            echo "bind-address = 127.0.0.1" >> "$mysql_conf"
        fi
        systemctl restart mysql 2>/dev/null || systemctl restart mariadb 2>/dev/null
    fi
}

#-------------------------------------------------------------------------------
# File Permission Security Checks
#-------------------------------------------------------------------------------
check_file_security() {
    print_section "File Permission Security"

    # Check /etc/passwd permissions
    local passwd_perms=$(stat -c "%a" /etc/passwd 2>/dev/null)
    if [[ "$passwd_perms" != "644" ]]; then
        print_finding "MEDIUM" "FILE-001" "/etc/passwd has incorrect permissions: $passwd_perms (should be 644)"

        prompt_fix "FILE-001" \
            "/etc/passwd should be readable by all but writable only by root.
  Incorrect permissions could allow unauthorized modifications." \
            "Permissions on /etc/passwd will be set to 644 (rw-r--r--)." \
            "To revert: Run 'chmod $passwd_perms /etc/passwd'" \
            "chmod 644 /etc/passwd"
    else
        print_ok "/etc/passwd permissions are correct (644)"
    fi

    # Check /etc/shadow permissions
    local shadow_perms=$(stat -c "%a" /etc/shadow 2>/dev/null)
    if [[ "$shadow_perms" != "640" ]] && [[ "$shadow_perms" != "600" ]] && [[ "$shadow_perms" != "000" ]]; then
        print_finding "HIGH" "FILE-002" "/etc/shadow has incorrect permissions: $shadow_perms (should be 640 or 600)"

        prompt_fix "FILE-002" \
            "/etc/shadow contains password hashes and should be readable only by root
  and the shadow group. Incorrect permissions could expose password hashes." \
            "Permissions on /etc/shadow will be set to 640 (rw-r-----)." \
            "To revert: Run 'chmod $shadow_perms /etc/shadow'" \
            "chmod 640 /etc/shadow"
    else
        print_ok "/etc/shadow permissions are correct ($shadow_perms)"
    fi

    # Check /etc/gshadow permissions
    if [[ -f /etc/gshadow ]]; then
        local gshadow_perms=$(stat -c "%a" /etc/gshadow 2>/dev/null)
        if [[ "$gshadow_perms" != "640" ]] && [[ "$gshadow_perms" != "600" ]] && [[ "$gshadow_perms" != "000" ]]; then
            print_finding "MEDIUM" "FILE-003" "/etc/gshadow has incorrect permissions: $gshadow_perms"
        else
            print_ok "/etc/gshadow permissions are correct ($gshadow_perms)"
        fi
    fi

    # Check for world-writable files
    print_info "Scanning for world-writable files (this may take a moment)..."
    local world_writable=$(find / -xdev -type f -perm -0002 -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | head -20)
    if [[ -n "$world_writable" ]]; then
        print_finding "HIGH" "FILE-004" "World-writable files found"
        echo "$world_writable" | while read file; do
            echo "    $file"
        done
        if [[ $(echo "$world_writable" | wc -l) -eq 20 ]]; then
            print_info "  (Output limited to first 20 files)"
        fi
    else
        print_ok "No world-writable files found"
    fi

    # Check for world-writable directories without sticky bit
    local world_writable_dirs=$(find / -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | head -10)
    if [[ -n "$world_writable_dirs" ]]; then
        print_finding "HIGH" "FILE-005" "World-writable directories without sticky bit"
        echo "$world_writable_dirs" | while read dir; do
            echo "    $dir"
        done
    else
        print_ok "No world-writable directories without sticky bit"
    fi

    # Check for SUID/SGID files
    print_info "Scanning for SUID/SGID files..."
    local suid_files=$(find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null)
    local suid_count=$(echo "$suid_files" | grep -c .)
    print_info "Found $suid_count SUID/SGID files"

    # Check for unusual SUID files (not in standard locations)
    local unusual_suid=$(echo "$suid_files" | grep -vE "^/(usr|bin|sbin)/" | head -10)
    if [[ -n "$unusual_suid" ]]; then
        print_finding "HIGH" "FILE-006" "SUID/SGID files in non-standard locations"
        echo "$unusual_suid" | while read file; do
            echo "    $file"
        done
    fi

    # Check for unowned files
    print_info "Scanning for unowned files..."
    local unowned=$(find / -xdev \( -nouser -o -nogroup \) -not -path "/proc/*" 2>/dev/null | head -10)
    if [[ -n "$unowned" ]]; then
        print_finding "MEDIUM" "FILE-007" "Files without valid owner or group"
        echo "$unowned" | while read file; do
            echo "    $file"
        done
    else
        print_ok "No unowned files found"
    fi

    # Check /tmp permissions
    local tmp_perms=$(stat -c "%a" /tmp 2>/dev/null)
    if [[ "$tmp_perms" != "1777" ]]; then
        print_finding "MEDIUM" "FILE-008" "/tmp has incorrect permissions: $tmp_perms (should be 1777)"
    else
        print_ok "/tmp permissions are correct (1777 with sticky bit)"
    fi

    # Check for credentials in common locations
    print_info "Checking for potential credential files..."

    # Check for private keys
    local private_keys=$(find /home /root /etc -name "*.pem" -o -name "id_rsa" -o -name "id_dsa" -o -name "id_ecdsa" -o -name "id_ed25519" 2>/dev/null)
    if [[ -n "$private_keys" ]]; then
        print_info "Private key files found:"
        echo "$private_keys" | while read key; do
            local key_perms=$(stat -c "%a" "$key" 2>/dev/null)
            if [[ "$key_perms" != "600" ]] && [[ "$key_perms" != "400" ]]; then
                print_finding "HIGH" "FILE-009" "Private key with weak permissions: $key ($key_perms)"
            else
                echo "    $key (permissions OK)"
            fi
        done
    fi

    # Check for .env files
    local env_files=$(find /var/www /home /opt -name ".env" -o -name ".env.*" 2>/dev/null | head -10)
    if [[ -n "$env_files" ]]; then
        print_finding "MEDIUM" "FILE-010" ".env files found (may contain secrets)"
        echo "$env_files" | while read file; do
            echo "    $file"
        done
    fi

    # Check for password files
    local pass_files=$(find / -xdev -name "*password*" -o -name "*passwd*" -o -name "*credential*" -o -name "*secret*" 2>/dev/null | grep -vE "(^/proc|^/sys|/usr/share|\.pyc$|\.go$|\.h$|\.c$|\.md$|\.txt$|/man/)" | head -10)
    if [[ -n "$pass_files" ]]; then
        print_finding "MEDIUM" "FILE-011" "Files with password-related names found"
        echo "$pass_files" | while read file; do
            echo "    $file"
        done
    fi
}

#-------------------------------------------------------------------------------
# Service Security Checks
#-------------------------------------------------------------------------------
check_service_security() {
    print_section "Service and Process Security"

    # Check for unnecessary services
    local dangerous_services="telnet rsh rlogin rexec finger talk ntalk tftp xinetd"
    for service in $dangerous_services; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            print_finding "CRITICAL" "SVC-001" "Insecure service running: $service"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            print_finding "HIGH" "SVC-002" "Insecure service enabled: $service"
        fi
    done
    print_ok "Checked for dangerous legacy services"

    # Check for avahi-daemon (mDNS)
    if systemctl is-active --quiet avahi-daemon 2>/dev/null; then
        print_finding "LOW" "SVC-003" "Avahi daemon (mDNS) is running"
        print_info "  Unless needed for service discovery, consider disabling"
    fi

    # Check for CUPS (printing)
    if systemctl is-active --quiet cups 2>/dev/null; then
        print_finding "INFO" "SVC-004" "CUPS printing service is running"
        print_info "  Unless printing is needed, consider disabling"
    fi

    # Check for NFS services
    if systemctl is-active --quiet nfs-server 2>/dev/null; then
        print_finding "MEDIUM" "SVC-005" "NFS server is running"
        print_info "  Ensure NFS exports are properly secured"

        if [[ -f /etc/exports ]]; then
            if grep -qE "\s+\*\s+" /etc/exports; then
                print_finding "HIGH" "SVC-006" "NFS exports allow access from any host"
            fi
        fi
    fi

    # Check for rsync daemon
    if systemctl is-active --quiet rsync 2>/dev/null; then
        print_finding "MEDIUM" "SVC-007" "rsync daemon is running"
        if [[ -f /etc/rsyncd.conf ]]; then
            if ! grep -q "auth users" /etc/rsyncd.conf; then
                print_finding "HIGH" "SVC-008" "rsync may allow anonymous access"
            fi
        fi
    fi

    # Check for fail2ban
    if ! command -v fail2ban-client &>/dev/null; then
        print_finding "MEDIUM" "SVC-010" "fail2ban is not installed"
        print_info "  fail2ban helps protect against brute-force attacks"

        prompt_fix "SVC-010" \
            "fail2ban monitors log files and bans IPs that show malicious activity
  like too many failed login attempts. It's essential for internet-facing servers." \
            "fail2ban will be installed and enabled with default SSH protection." \
            "To revert: Run 'sudo apt remove fail2ban' or 'sudo yum remove fail2ban'" \
            fix_install_fail2ban
    elif ! systemctl is-active --quiet fail2ban 2>/dev/null; then
        print_finding "MEDIUM" "SVC-011" "fail2ban is installed but not running"

        prompt_fix "SVC-011" \
            "fail2ban is installed but the service is not running.
  Without it, the system is vulnerable to brute-force attacks." \
            "fail2ban service will be started and enabled." \
            "To revert: Run 'sudo systemctl stop fail2ban && sudo systemctl disable fail2ban'" \
            fix_start_fail2ban
    else
        print_ok "fail2ban is active"

        # Check if SSH jail is enabled
        if ! fail2ban-client status sshd &>/dev/null; then
            print_finding "LOW" "SVC-012" "fail2ban SSH jail may not be enabled"
        fi
    fi

    # Check for unattended-upgrades (Debian/Ubuntu)
    if [[ -f /etc/debian_version ]]; then
        if ! dpkg -l | grep -q unattended-upgrades; then
            print_finding "MEDIUM" "SVC-020" "unattended-upgrades not installed"
            print_info "  Automatic security updates are recommended"
        elif ! systemctl is-active --quiet unattended-upgrades 2>/dev/null; then
            print_finding "LOW" "SVC-021" "unattended-upgrades not active"
        else
            print_ok "Automatic security updates configured"
        fi
    fi

    # Check for cron jobs running as root
    print_info "Checking cron jobs..."
    if [[ -d /etc/cron.d ]]; then
        for cronfile in /etc/cron.d/*; do
            if [[ -f "$cronfile" ]]; then
                local perms=$(stat -c "%a" "$cronfile")
                if [[ "${perms:2:1}" != "0" ]]; then
                    print_finding "MEDIUM" "SVC-030" "Cron file world-readable/writable: $cronfile"
                fi
            fi
        done
    fi

    # Check for suspicious processes
    print_info "Checking for suspicious processes..."

    # Check for processes running from /tmp
    local tmp_procs=$(ps aux | awk '$11 ~ /^\/tmp/ {print $11}' | head -5)
    if [[ -n "$tmp_procs" ]]; then
        print_finding "HIGH" "SVC-040" "Processes running from /tmp directory"
        echo "$tmp_procs" | while read proc; do
            echo "    $proc"
        done
    fi

    # Check for processes running from home directories
    local home_procs=$(ps aux | awk '$11 ~ /^\/home/ {print $11}' | head -5)
    if [[ -n "$home_procs" ]]; then
        print_finding "MEDIUM" "SVC-041" "Processes running from /home directories"
        echo "$home_procs" | while read proc; do
            echo "    $proc"
        done
    fi

    # Check for hidden processes (names starting with .)
    local hidden_procs=$(ps aux | awk '$11 ~ /^\./ || $11 ~ /\/\./ {print $2, $11}' | head -5)
    if [[ -n "$hidden_procs" ]]; then
        print_finding "HIGH" "SVC-042" "Processes with hidden names detected"
        echo "$hidden_procs" | while read proc; do
            echo "    $proc"
        done
    fi
}

fix_install_fail2ban() {
    if command -v apt &>/dev/null; then
        apt update && apt install -y fail2ban
    elif command -v yum &>/dev/null; then
        yum install -y fail2ban
    elif command -v dnf &>/dev/null; then
        dnf install -y fail2ban
    fi
    systemctl enable fail2ban
    systemctl start fail2ban
}

fix_start_fail2ban() {
    systemctl enable fail2ban
    systemctl start fail2ban
}

#-------------------------------------------------------------------------------
# Network Security Checks
#-------------------------------------------------------------------------------
check_network_security() {
    print_section "Network Security"

    # Check IP forwarding
    local ip_forward=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)
    if [[ "$ip_forward" == "1" ]]; then
        print_finding "MEDIUM" "NET-001" "IPv4 forwarding is enabled"
        print_info "  Unless this is a router, IP forwarding should be disabled"

        prompt_fix "NET-001" \
            "IP forwarding allows this system to route packets between networks.
  Unless this is intentionally configured as a router, it should be disabled
  to prevent the system from being used in network attacks." \
            "IPv4 forwarding will be disabled via sysctl.
  The change will be made persistent in /etc/sysctl.conf." \
            "To revert: Run 'sysctl -w net.ipv4.ip_forward=1'
  And edit /etc/sysctl.conf to set net.ipv4.ip_forward=1" \
            fix_ip_forward
    else
        print_ok "IPv4 forwarding is disabled"
    fi

    # Check ICMP redirects
    local icmp_redirect=$(cat /proc/sys/net/ipv4/conf/all/accept_redirects 2>/dev/null)
    if [[ "$icmp_redirect" == "1" ]]; then
        print_finding "MEDIUM" "NET-002" "ICMP redirects are accepted"

        prompt_fix "NET-002" \
            "ICMP redirects can be used to alter routing tables maliciously.
  Unless specifically needed, they should be ignored." \
            "ICMP redirect acceptance will be disabled via sysctl." \
            "To revert: Run 'sysctl -w net.ipv4.conf.all.accept_redirects=1'" \
            fix_icmp_redirects
    else
        print_ok "ICMP redirects are ignored"
    fi

    # Check source routing
    local source_route=$(cat /proc/sys/net/ipv4/conf/all/accept_source_route 2>/dev/null)
    if [[ "$source_route" == "1" ]]; then
        print_finding "HIGH" "NET-003" "Source routing is accepted"

        prompt_fix "NET-003" \
            "Source routing allows senders to specify the route packets take.
  This can be used to bypass network security controls." \
            "Source routing acceptance will be disabled via sysctl." \
            "To revert: Run 'sysctl -w net.ipv4.conf.all.accept_source_route=1'" \
            fix_source_route
    else
        print_ok "Source routing is disabled"
    fi

    # Check SYN cookies
    local syncookies=$(cat /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null)
    if [[ "$syncookies" != "1" ]]; then
        print_finding "MEDIUM" "NET-004" "SYN cookies are disabled"

        prompt_fix "NET-004" \
            "SYN cookies help protect against SYN flood attacks by not allocating
  resources until the TCP handshake is complete." \
            "SYN cookies will be enabled via sysctl." \
            "To revert: Run 'sysctl -w net.ipv4.tcp_syncookies=0'" \
            fix_syncookies
    else
        print_ok "SYN cookies are enabled"
    fi

    # Check for promiscuous mode
    local promisc_ifaces=$(ip link show 2>/dev/null | grep -i promisc | awk -F: '{print $2}')
    if [[ -n "$promisc_ifaces" ]]; then
        print_finding "HIGH" "NET-005" "Network interfaces in promiscuous mode:$promisc_ifaces"
        print_info "  This may indicate packet sniffing activity"
    else
        print_ok "No interfaces in promiscuous mode"
    fi

    # Check for IPv6
    local ipv6_enabled=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null)
    if [[ "$ipv6_enabled" == "0" ]]; then
        print_finding "INFO" "NET-006" "IPv6 is enabled"
        print_info "  If not using IPv6, consider disabling it to reduce attack surface"
    fi

    # Check DNS configuration
    if [[ -f /etc/resolv.conf ]]; then
        local nameservers=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}')
        print_info "DNS servers configured:"
        echo "$nameservers" | while read ns; do
            echo "    $ns"
        done

        # Check for localhost DNS (might indicate local resolver)
        if echo "$nameservers" | grep -q "127.0.0."; then
            print_info "  Local DNS resolver detected (127.0.0.x)"
        fi
    fi

    # Check for ARP spoofing protection
    if ! command -v arpwatch &>/dev/null && ! command -v arpon &>/dev/null; then
        print_finding "LOW" "NET-007" "No ARP spoofing protection detected"
        print_info "  Consider installing arpwatch or arpon"
    fi

    # Check TCP wrappers
    if [[ -f /etc/hosts.allow ]] || [[ -f /etc/hosts.deny ]]; then
        print_ok "TCP wrappers configuration files exist"

        if [[ -f /etc/hosts.deny ]]; then
            if ! grep -q "ALL:" /etc/hosts.deny; then
                print_finding "LOW" "NET-008" "/etc/hosts.deny does not have default deny rule"
            fi
        fi
    else
        print_finding "LOW" "NET-009" "TCP wrappers not configured"
    fi
}

fix_ip_forward() {
    sysctl -w net.ipv4.ip_forward=0
    create_backup "/etc/sysctl.conf" "sysctl.conf"
    if grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf; then
        sed -i 's/^net.ipv4.ip_forward.*/net.ipv4.ip_forward=0/' /etc/sysctl.conf
    else
        echo "net.ipv4.ip_forward=0" >> /etc/sysctl.conf
    fi
}

fix_icmp_redirects() {
    sysctl -w net.ipv4.conf.all.accept_redirects=0
    sysctl -w net.ipv4.conf.default.accept_redirects=0

    create_backup "/etc/sysctl.conf" "sysctl.conf"
    echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf
    echo "net.ipv4.conf.default.accept_redirects=0" >> /etc/sysctl.conf
}

fix_source_route() {
    sysctl -w net.ipv4.conf.all.accept_source_route=0
    sysctl -w net.ipv4.conf.default.accept_source_route=0

    create_backup "/etc/sysctl.conf" "sysctl.conf"
    echo "net.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf
    echo "net.ipv4.conf.default.accept_source_route=0" >> /etc/sysctl.conf
}

fix_syncookies() {
    sysctl -w net.ipv4.tcp_syncookies=1

    create_backup "/etc/sysctl.conf" "sysctl.conf"
    echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
}

#-------------------------------------------------------------------------------
# Summary and Reporting
#-------------------------------------------------------------------------------
print_summary() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${WHITE}                           SCAN SUMMARY                                      ${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BOLD}Vulnerabilities Found:${NC}"
    echo -e "  ${RED}Critical:${NC}  $CRITICAL_COUNT"
    echo -e "  ${MAGENTA}High:${NC}      $HIGH_COUNT"
    echo -e "  ${YELLOW}Medium:${NC}    $MEDIUM_COUNT"
    echo -e "  ${CYAN}Low:${NC}       $LOW_COUNT"
    echo -e "  ${BLUE}Info:${NC}      $INFO_COUNT"
    echo ""
    local total=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))
    echo -e "${BOLD}Total Issues:${NC} $total"
    echo ""

    if [[ "$SCAN_ONLY" == false ]]; then
        echo -e "${BOLD}Remediation:${NC}"
        echo -e "  ${GREEN}Fixed:${NC}     $FIXED_COUNT"
        echo -e "  ${YELLOW}Skipped:${NC}   $SKIPPED_COUNT"
        echo ""
    fi

    echo -e "${BOLD}Log file:${NC} $LOG_FILE"
    echo -e "${BOLD}Backups:${NC}  $BACKUP_DIR"

    if [[ -n "$REPORT_FILE" ]]; then
        generate_report
        echo -e "${BOLD}Report:${NC}   $REPORT_FILE"
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Risk assessment
    echo ""
    if [[ $CRITICAL_COUNT -gt 0 ]]; then
        echo -e "${RED}${BOLD}⚠ CRITICAL: This system has critical vulnerabilities that require immediate attention!${NC}"
    elif [[ $HIGH_COUNT -gt 0 ]]; then
        echo -e "${MAGENTA}${BOLD}⚠ HIGH RISK: This system has high-severity issues that should be addressed soon.${NC}"
    elif [[ $MEDIUM_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}${BOLD}⚠ MODERATE RISK: This system has moderate issues that should be reviewed.${NC}"
    elif [[ $LOW_COUNT -gt 0 ]]; then
        echo -e "${CYAN}${BOLD}✓ LOW RISK: Only minor issues detected.${NC}"
    else
        echo -e "${GREEN}${BOLD}✓ SECURE: No significant vulnerabilities detected.${NC}"
    fi
    echo ""
}

generate_report() {
    cat > "$REPORT_FILE" << EOF
================================================================================
                    LINUX VULNERABILITY SCAN REPORT
================================================================================

Scan Date: $(date)
Hostname:  $(hostname)
Scanner:   Linux Vulnerability Scanner v${VERSION}

--------------------------------------------------------------------------------
                              SUMMARY
--------------------------------------------------------------------------------

Vulnerabilities Found:
  Critical:  $CRITICAL_COUNT
  High:      $HIGH_COUNT
  Medium:    $MEDIUM_COUNT
  Low:       $LOW_COUNT
  Info:      $INFO_COUNT

Total Issues: $((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))

Remediation:
  Fixed:     $FIXED_COUNT
  Skipped:   $SKIPPED_COUNT

--------------------------------------------------------------------------------
                           DETAILED FINDINGS
--------------------------------------------------------------------------------

EOF

    cat "$LOG_FILE" >> "$REPORT_FILE"

    cat >> "$REPORT_FILE" << EOF

--------------------------------------------------------------------------------
                           RECOMMENDATIONS
--------------------------------------------------------------------------------

1. Address all CRITICAL vulnerabilities immediately
2. Plan remediation for HIGH severity issues within 7 days
3. Schedule fixes for MEDIUM issues within 30 days
4. Review LOW and INFO findings during regular maintenance

For detailed remediation steps, refer to:
  - docs/REMEDIATION.md (if using CCDC Practice Range)
  - CIS Benchmarks for your Linux distribution
  - NIST Security Configuration Guides

================================================================================
                          END OF REPORT
================================================================================
EOF
}

#-------------------------------------------------------------------------------
# Main Function
#-------------------------------------------------------------------------------
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --scan-only)
                SCAN_ONLY=true
                shift
                ;;
            --category)
                SELECTED_CATEGORY="$2"
                shift 2
                ;;
            --auto-backup)
                AUTO_BACKUP=true
                shift
                ;;
            --report)
                REPORT_FILE="$2"
                shift 2
                ;;
            --no-color)
                USE_COLOR=false
                shift
                ;;
            -h|--help)
                echo "Usage: $SCRIPT_NAME [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --scan-only       Only scan, don't offer fixes"
                echo "  --category CAT    Scan specific category:"
                echo "                    ssh, firewall, users, web, db, files, services, network, all"
                echo "  --auto-backup     Automatically create backups before fixes"
                echo "  --report FILE     Save report to file"
                echo "  --no-color        Disable colored output"
                echo "  -h, --help        Show this help message"
                echo ""
                echo "Examples:"
                echo "  sudo $SCRIPT_NAME                    # Full scan with interactive fixes"
                echo "  sudo $SCRIPT_NAME --scan-only        # Scan without offering fixes"
                echo "  sudo $SCRIPT_NAME --category ssh     # Only check SSH security"
                echo "  sudo $SCRIPT_NAME --report scan.txt  # Save report to file"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done

    # Setup
    setup_colors

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}${BOLD}Error: This script must be run as root${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi

    # Create directories
    mkdir -p "$LOG_DIR" "$BACKUP_DIR"

    # Print banner
    print_banner

    echo -e "${BOLD}Scan started at $(date)${NC}"
    echo -e "Log file: ${LOG_FILE}"
    echo ""

    if [[ "$SCAN_ONLY" == true ]]; then
        echo -e "${YELLOW}Running in scan-only mode - no fixes will be applied${NC}"
        echo ""
    fi

    log_message "INFO" "Scan started"
    log_message "INFO" "Hostname: $(hostname)"
    log_message "INFO" "Scan mode: $(if [[ "$SCAN_ONLY" == true ]]; then echo "scan-only"; else echo "interactive"; fi)"

    # Run selected checks
    case "$SELECTED_CATEGORY" in
        ssh)
            check_ssh_security
            ;;
        firewall)
            check_firewall_security
            ;;
        users)
            check_user_security
            ;;
        web)
            check_web_security
            ;;
        db)
            check_database_security
            ;;
        files)
            check_file_security
            ;;
        services)
            check_service_security
            ;;
        network)
            check_network_security
            ;;
        all|*)
            check_ssh_security
            check_firewall_security
            check_user_security
            check_web_security
            check_database_security
            check_file_security
            check_service_security
            check_network_security
            ;;
    esac

    # Print summary
    print_summary

    log_message "INFO" "Scan completed"
}

# Run main function
main "$@"
