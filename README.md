# CCDC Practice Range - Ludus Cybersecurity Lab

A comprehensive cybersecurity practice environment built on [Ludus](https://ludus.cloud) for Collegiate Cyber Defense Competition (CCDC) training. This range simulates a small business network with realistic services, users, and configurations.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Deployment](#detailed-deployment)
- [Network Configuration](#network-configuration)
- [User Accounts](#user-accounts)
- [Services](#services)
- [Training Scenarios](#training-scenarios)
- [Troubleshooting](#troubleshooting)
- [Customization](#customization)

---

## Overview

### What is This?

This repository contains a complete Ludus range configuration that deploys a simulated corporate network environment for cybersecurity training. It's designed specifically for community college CCDC teams to practice:

- **Blue Team Skills**: Defending systems, hardening configurations, incident response
- **System Administration**: Managing Windows and Linux servers in a domain environment
- **Security Monitoring**: Log analysis, event correlation, threat detection

### Design Philosophy

The environment was designed with these principles:

1. **Realistic**: Mimics a typical small business IT infrastructure
2. **Educational**: Includes intentional learning opportunities (audit logging enabled, sample data)
3. **Repeatable**: Snapshot and restore capabilities for iterative training
4. **Scalable**: Easy to expand with additional systems or services

### What's Included

| System | OS | Role | IP Address |
|--------|-----|------|------------|
| DC01 | Windows Server 2019 | Domain Controller + File Server | 10.X.10.10 |
| WEB01 | Ubuntu 22.04 LTS | Apache Web Server | 10.X.10.20 |
| DB01 | Debian 12 | MySQL Database Server | 10.X.10.30 |
| WS01 | Windows 10 Enterprise | Employee Workstation | 10.X.10.50 |

*Note: X = your Ludus range ID number*

---

## Architecture

### Network Diagram

```
                                    ┌─────────────────────────────────────────────────────────┐
                                    │                   VLAN 10 - Corporate                    │
                                    │                   10.X.10.0/24                           │
                                    │                                                          │
┌──────────────┐                    │  ┌─────────────┐        ┌─────────────┐                 │
│   Internet   │◄───────────────────┤  │    DC01     │        │    WEB01    │                 │
│              │                    │  │ Win 2019    │        │ Ubuntu 22   │                 │
└──────────────┘                    │  │ .10.10      │        │ .10.20      │                 │
       │                            │  │             │        │             │                 │
       │                            │  │ - AD/DNS    │        │ - Apache    │                 │
       ▼                            │  │ - File Svc  │        │ - PHP       │                 │
┌──────────────┐                    │  │ - DHCP      │        │ - SSL/TLS   │                 │
│   Ludus      │                    │  └─────────────┘        └─────────────┘                 │
│   Router     │────────────────────┤                                                          │
│  10.X.10.254 │                    │  ┌─────────────┐        ┌─────────────┐                 │
└──────────────┘                    │  │    DB01     │        │    WS01     │                 │
       │                            │  │ Debian 12   │        │ Windows 10  │                 │
       │                            │  │ .10.30      │        │ .10.50      │                 │
       ▼                            │  │             │        │             │                 │
┌──────────────┐                    │  │ - MySQL     │        │ - Domain    │                 │
│  WireGuard   │                    │  │ - Sample DB │        │   Joined    │                 │
│    VPN       │                    │  │             │        │ - Sysmon    │                 │
│ Your Access  │                    │  └─────────────┘        └─────────────┘                 │
└──────────────┘                    │                                                          │
                                    └─────────────────────────────────────────────────────────┘
```

### Domain Structure

```
blue.lab (Forest Root Domain)
│
├── OU=Staff
│   ├── OU=IT
│   │   ├── Alex Thompson (itmgr) - Domain Admin
│   │   ├── Sarah Lee (slee) - Help Desk
│   │   └── Kevin Wong (kwong) - Developer
│   │
│   ├── OU=Sales
│   │   └── John Smith (jsmith)
│   │
│   ├── OU=HR
│   │   └── Maria Johnson (mjohnson)
│   │
│   ├── OU=Finance
│   │   └── Brian Williams (bwilliams)
│   │
│   └── OU=Marketing
│       └── David Garcia (dgarcia)
│
├── Security Groups
│   ├── IT
│   ├── Sales
│   ├── HR
│   ├── Finance
│   ├── Marketing
│   ├── Help Desk
│   └── Developers
│
└── Computers
    ├── DC01 (Domain Controller)
    └── WS01 (Workstation)
```

---

## Prerequisites

### Hardware Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU Cores | 8 | 16+ |
| RAM | 24 GB | 32+ GB |
| Storage | 200 GB SSD | 500+ GB NVMe |

### Software Requirements

1. **Ludus Server** - Installed and configured ([Installation Guide](https://docs.ludus.cloud/docs/quick-start/install-ludus))
2. **Ludus CLI** - Installed on your management machine
3. **WireGuard** - For VPN access to the range

### Required Templates

The following Ludus templates must be available:

- `win2019-server-x64-template`
- `win10-22h2-x64-enterprise-template`
- `ubuntu-22.04-x64-server-template`
- `debian-12-x64-server-template`

Check available templates:
```bash
ludus templates list
```

Build missing templates:
```bash
ludus templates build --all
```

---

## Quick Start

### One-Command Deployment

```bash
# Clone this repository
git clone <repository-url>
cd ccdc-practice-range

# Run full deployment
./scripts/deploy.sh full
```

### Step-by-Step Quick Start

```bash
# 1. Check prerequisites
./scripts/deploy.sh check

# 2. Add roles and set configuration
./scripts/deploy.sh setup

# 3. Deploy the range
./scripts/deploy.sh deploy

# 4. View connection information
./scripts/deploy.sh status
```

---

## Detailed Deployment

### Step 1: Verify Prerequisites

```bash
# Check Ludus CLI is installed
ludus version

# Check available templates
ludus templates list

# Check your range status
ludus range status
```

### Step 2: Add Ansible Roles

The custom Ansible roles must be added to your Ludus server:

```bash
# Add all roles from this repository
ludus ansible role add -d ./ansible/roles/ccdc-windows-base
ludus ansible role add -d ./ansible/roles/ccdc-file-services
ludus ansible role add -d ./ansible/roles/ccdc-web-server
ludus ansible role add -d ./ansible/roles/ccdc-database-server
ludus ansible role add -d ./ansible/roles/ccdc-workstation-config

# Verify roles were added
ludus ansible role list
```

### Step 3: Set Range Configuration

```bash
# Upload the configuration
ludus range config set -f ludus-config.yml

# Verify configuration
ludus range config get
```

### Step 4: Deploy the Range

```bash
# Start deployment
ludus range deploy

# Monitor progress (in another terminal)
watch ludus range status
```

**Expected deployment time: 30-60 minutes**

### Step 5: Verify Deployment

```bash
# Check all VMs are running
ludus range status

# Get WireGuard configuration
ludus user wireguard

# Test connectivity (after connecting to VPN)
ping 10.X.10.10  # DC01
ping 10.X.10.20  # WEB01
```

---

## Network Configuration

### IP Addressing

All VMs are on VLAN 10 with the subnet `10.X.10.0/24` where X is your range ID.

| Hostname | IP Address | Services/Ports |
|----------|------------|----------------|
| DC01 | 10.X.10.10 | DNS (53), LDAP (389), Kerberos (88), SMB (445), WinRM (5985) |
| WEB01 | 10.X.10.20 | HTTP (80), HTTPS (443), SSH (22) |
| DB01 | 10.X.10.30 | MySQL (3306), SSH (22) |
| WS01 | 10.X.10.50 | RDP (3389), WinRM (5985) |
| Router | 10.X.10.254 | Gateway, DNS forwarding |

### DNS Configuration

- Primary DNS: DC01 (10.X.10.10)
- The domain `blue.lab` resolves all internal hostnames
- External DNS queries are forwarded through the Ludus router

### Firewall Rules

Default policies allow internal VLAN traffic. Key rules:

- All internal traffic within VLAN 10 is allowed
- Web server (port 80/443) accessible from all internal hosts
- Database (port 3306) only accessible from web server
- Internet access enabled for updates (can be disabled for exercises)

---

## User Accounts

### Domain Administrator

| Username | Password | Description |
|----------|----------|-------------|
| BLUE\itmgr | ITManager2024! | IT Manager - Full Domain Admin |

### Standard Domain Users

| Username | Password | Department | Groups |
|----------|----------|------------|--------|
| BLUE\jsmith | JSmith2024! | Sales | Domain Users, Sales |
| BLUE\mjohnson | MJohnson2024! | HR | Domain Users, HR |
| BLUE\bwilliams | BWilliams2024! | Finance | Domain Users, Finance |
| BLUE\slee | SLee2024! | IT | Domain Users, IT, Help Desk |
| BLUE\dgarcia | DGarcia2024! | Marketing | Domain Users, Marketing |
| BLUE\kwong | KWong2024! | IT | Domain Users, IT, Developers |

### Local Accounts (All Systems)

| Username | Password | Notes |
|----------|----------|-------|
| localuser | password | Ludus default local admin |
| Administrator | CCDCAdmin2024! | Windows built-in (DC only) |

### Database Users

| Username | Password | Database | Privileges |
|----------|----------|----------|------------|
| webapp | WebApp2024! | inventory | SELECT, INSERT, UPDATE, DELETE |
| hrapp | HRApp2024! | employees | SELECT, INSERT, UPDATE |

---

## Services

### Domain Controller (DC01)

**Active Directory Domain Services**
- Domain: blue.lab
- Forest/Domain Functional Level: Windows Server 2016
- DNS integrated with AD

**File Services**
- Share: `\\DC01\SharedFiles` (mapped as S: drive on workstations)
- Departmental folders with appropriate permissions
- Public folder for general file sharing

**Security Configuration**
- Advanced audit policies enabled
- PowerShell script block logging
- DNS query logging
- Command-line process auditing

### Web Server (WEB01)

**Apache HTTP Server**
- Document root: `/var/www/html`
- SSL enabled with self-signed certificate
- Sample corporate intranet site deployed

**Security**
- UFW firewall (ports 22, 80, 443)
- Fail2ban for brute force protection
- ModSecurity WAF installed

**Access**
- URL: https://intranet.blue.lab (or https://10.X.10.20)
- SSH: `ssh localuser@10.X.10.20`

### Database Server (DB01)

**MySQL/MariaDB**
- Port: 3306
- Databases: inventory, employees, helpdesk

**Sample Data Included**
- Product inventory system
- Employee records
- IT helpdesk tickets

**Security**
- UFW firewall (ports 22, 3306)
- MySQL connections restricted to internal network
- Root remote login disabled

**Access**
- MySQL: `mysql -h 10.X.10.30 -u webapp -p inventory`
- SSH: `ssh localuser@10.X.10.30`

### Workstation (WS01)

**Windows 10 Enterprise**
- Domain joined to blue.lab
- Sysmon installed for endpoint monitoring
- Network drive mapped to file share

**Security**
- Windows Defender enabled
- Audit policies configured
- PowerShell logging enabled

**Access**
- RDP: `mstsc /v:10.X.10.50`
- Login as any domain user

---

## Training Scenarios

### Getting Started Exercises

1. **Explore the Network**
   - Log into WS01 as a domain user
   - Browse the file share on DC01
   - Access the intranet website
   - Query the database from the web server

2. **Review Security Configurations**
   - Examine Windows audit policies on DC01
   - Review Apache security headers on WEB01
   - Check MySQL user permissions on DB01

### Blue Team Exercises

1. **Baseline Documentation**
   - Document all running services
   - List all user accounts and group memberships
   - Map network connections between systems

2. **Hardening Exercise**
   - Review and improve firewall rules
   - Disable unnecessary services
   - Implement additional logging

3. **Incident Response Preparation**
   - Configure centralized logging
   - Create monitoring dashboards
   - Develop incident response procedures

### Using Testing Mode

Testing mode creates snapshots and blocks internet access to simulate competition conditions:

```bash
# Start a training exercise
./scripts/deploy.sh test

# Conduct your exercise...

# Reset to clean state
./scripts/deploy.sh untest
```

### Snapshot Management

```bash
# Create named snapshot before exercise
./scripts/deploy.sh snapshot pre-exercise

# After exercise, restore to clean state
./scripts/deploy.sh restore pre-exercise
```

---

## Troubleshooting

### Common Issues

**VMs not deploying**
```bash
# Check template status
ludus templates list

# Build missing templates
ludus templates build -n <template-name>
```

**Cannot connect to VMs**
```bash
# Verify WireGuard is connected
wg show

# Check VM status
ludus range status

# Verify your range ID and IP addresses
ludus range config get | grep range_id
```

**Domain join failures**
```bash
# Check DC is running first
ludus range status

# Redeploy domain configuration
ludus range deploy -t ad-dc
```

**Ansible role failures**
```bash
# Check role logs
ludus range logs

# Redeploy specific role
ludus range deploy -t user-defined-roles --limit <hostname>
```

### Useful Commands

```bash
# View deployment logs
ludus range logs

# SSH to Linux VM
ludus range ssh <vm-name>

# Open RDP to Windows VM
ludus range rdp <vm-name>

# Get Ansible inventory
ludus range inventory

# Force redeploy specific VM
ludus range deploy --limit <vm-name>
```

---

## Customization

### Adding More VMs

Edit `ludus-config.yml` to add additional systems:

```yaml
ludus:
  # ... existing VMs ...

  - vm_name: "{{ range_id }}-new-server"
    hostname: "NEWSRV01"
    template: ubuntu-22.04-x64-server-template
    vlan: 10
    ip_last_octet: 40
    ram_gb: 4
    cpus: 2
    linux: true
```

### Adding Users

Add users to the `global_role_vars.domain_users` list in `ludus-config.yml`:

```yaml
global_role_vars:
  domain_users:
    # ... existing users ...
    - username: "newuser"
      password: "NewUser2024!"
      first_name: "New"
      last_name: "User"
      display_name: "New User"
      description: "New Employee"
      groups:
        - "Domain Users"
        - "Sales"
      ou: "OU=Sales,OU=Staff,DC=blue,DC=lab"
```

### Modifying Network Rules

Edit the `network` section in `ludus-config.yml`:

```yaml
network:
  inter_vlan_default: REJECT  # More restrictive
  rules:
    - name: "Custom rule"
      vlan_src: 10
      ip_last_octet_src: 50
      vlan_dst: 10
      ip_last_octet_dst: 30
      protocol: tcp
      ports: 3306
      action: ACCEPT
```

### Creating Custom Ansible Roles

1. Create role structure:
```bash
mkdir -p ansible/roles/my-custom-role/{tasks,handlers,templates,files,vars,defaults,meta}
```

2. Add tasks in `tasks/main.yml`

3. Add to Ludus:
```bash
ludus ansible role add -d ./ansible/roles/my-custom-role
```

4. Reference in VM configuration:
```yaml
- vm_name: "{{ range_id }}-myvm"
  # ...
  roles:
    - my-custom-role
```

---

## File Structure

```
ccdc-practice-range/
├── ludus-config.yml           # Main Ludus range configuration
├── README.md                  # This documentation
├── ansible/
│   └── roles/
│       ├── ccdc-windows-base/       # Windows baseline security
│       ├── ccdc-file-services/      # Windows file sharing
│       ├── ccdc-web-server/         # Linux Apache web server
│       ├── ccdc-database-server/    # Linux MySQL database
│       └── ccdc-workstation-config/ # Windows 10 workstation
└── scripts/
    └── deploy.sh              # Deployment automation script
```

---

## Support

### Resources

- [Ludus Documentation](https://docs.ludus.cloud)
- [Ludus GitHub](https://github.com/badsectorlabs/ludus)
- [Ansible Documentation](https://docs.ansible.com)

### Getting Help

1. Check the [Troubleshooting](#troubleshooting) section
2. Review Ludus logs: `ludus range logs`
3. Join the [Ludus Discord](https://discord.gg/ludus)

---

## License

This project is provided for educational purposes. See individual component licenses for details.

---

## Acknowledgments

- [Ludus](https://ludus.cloud) by Bad Sector Labs
- Community college cybersecurity programs
- CCDC competition organizers
