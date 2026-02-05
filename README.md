# CCDC Practice Range - VULNERABLE TRAINING ENVIRONMENT

> **WARNING**: This branch contains INTENTIONALLY VULNERABLE configurations for blue team training. DO NOT deploy in production environments!

A cybersecurity practice environment built on [Ludus](https://ludus.cloud) for Collegiate Cyber Defense Competition (CCDC) training. This vulnerable version simulates a compromised corporate network that blue teams must audit, secure, and defend.

## Branch Information

| Branch | Purpose |
|--------|---------|
| `main` | Secure baseline configuration |
| `vulnerable-training-env` | **THIS BRANCH** - Intentionally vulnerable for training |

## Training Documentation

This vulnerable environment includes comprehensive documentation:

| Document | Description |
|----------|-------------|
| [VULNERABILITIES.md](docs/VULNERABILITIES.md) | Complete list of all 70+ vulnerabilities with severity ratings and MITRE ATT&CK mapping |
| [DETECTION.md](docs/DETECTION.md) | Step-by-step instructions for detecting each vulnerability |
| [REMEDIATION.md](docs/REMEDIATION.md) | Detailed fix instructions for each vulnerability |

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Vulnerability Summary](#vulnerability-summary)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Training Exercises](#training-exercises)
- [User Accounts](#user-accounts)
- [Troubleshooting](#troubleshooting)

---

## Overview

### What is This?

This repository contains a Ludus range configuration that deploys a **deliberately vulnerable** corporate network environment. It's designed specifically for community college CCDC teams to practice:

- **Blue Team Skills**: Finding vulnerabilities, hardening configurations, incident response
- **Security Auditing**: Learning to identify misconfigurations and security gaps
- **Remediation**: Practicing how to fix common security issues
- **Documentation**: Recording findings professionally

### Design Philosophy

The vulnerable environment was designed with these principles:

1. **Realistic Vulnerabilities**: Issues commonly found in real-world environments
2. **Progressive Difficulty**: Mix of easy-to-find and subtle vulnerabilities
3. **Educational**: Each vulnerability maps to CIS benchmarks and MITRE ATT&CK
4. **Documented**: Complete detection and remediation guidance provided

### What's Included

| System | OS | Role | Vulnerability Categories |
|--------|-----|------|--------------------------|
| DC01 | Windows Server 2019 | Domain Controller + File Server | 20+ Windows & AD vulnerabilities |
| WEB01 | Ubuntu 22.04 LTS | Apache Web Server | 15+ web application vulnerabilities |
| DB01 | Debian 12 | MySQL Database Server | 13+ database security issues |
| WS01 | Windows 10 Enterprise | Employee Workstation | 14+ workstation vulnerabilities |

*Note: See [VULNERABILITIES.md](docs/VULNERABILITIES.md) for the complete list*

---

## Architecture

### Network Diagram

```
                                    ┌─────────────────────────────────────────────────────────┐
                                    │                   VLAN 10 - Corporate                    │
                                    │                   10.X.10.0/24                           │
                                    │                                                          │
                                    │  ┌─────────────────┐    ┌─────────────────┐             │
                                    │  │      DC01       │    │      WEB01      │             │
                                    │  │   Win 2019      │    │   Ubuntu 22     │             │
                                    │  │   .10.10        │    │   .10.20        │             │
                                    │  │                 │    │                 │             │
                                    │  │ VULNERABILITIES │    │ VULNERABILITIES │             │
                                    │  │ - Firewall OFF  │    │ - SQL Injection │             │
                                    │  │ - Weak GPO      │    │ - Cmd Injection │             │
                                    │  │ - SMB issues    │    │ - Dir Listing   │             │
                                    │  │ - Null sessions │    │ - No Firewall   │             │
                                    │  └─────────────────┘    └─────────────────┘             │
                                    │                                                          │
                                    │  ┌─────────────────┐    ┌─────────────────┐             │
                                    │  │      DB01       │    │      WS01       │             │
                                    │  │   Debian 12     │    │   Windows 10    │             │
                                    │  │   .10.30        │    │   .10.50        │             │
                                    │  │                 │    │                 │             │
                                    │  │ VULNERABILITIES │    │ VULNERABILITIES │             │
                                    │  │ - Root remote   │    │ - UAC Disabled  │             │
                                    │  │ - Weak passwords│    │ - SMBv1 Enabled │             │
                                    │  │ - Anonymous usr │    │ - Backdoor acct │             │
                                    │  │ - No Firewall   │    │ - AutoRun ON    │             │
                                    │  └─────────────────┘    └─────────────────┘             │
                                    │                                                          │
                                    └─────────────────────────────────────────────────────────┘
```

---

## Vulnerability Summary

### By System

| System | Critical | High | Medium | Low | Total |
|--------|----------|------|--------|-----|-------|
| DC01 (Windows) | 5 | 8 | 6 | 3 | 22 |
| File Services | 2 | 4 | 2 | 0 | 8 |
| WEB01 (Linux) | 3 | 6 | 4 | 2 | 15 |
| DB01 (Database) | 4 | 5 | 3 | 1 | 13 |
| WS01 (Workstation) | 3 | 6 | 4 | 1 | 14 |
| **Total** | **17** | **29** | **19** | **7** | **72** |

### By Category

| Category | Count | Examples |
|----------|-------|----------|
| Authentication | 12 | Weak passwords, null sessions, anonymous access |
| Network Security | 10 | Disabled firewalls, SMB signing off, SMBv1 |
| Access Control | 9 | Everyone Full Control, excessive privileges |
| Logging/Monitoring | 8 | Audit policies disabled, no fail2ban |
| Web Application | 7 | SQL injection, command injection, XSS |
| Configuration | 14 | UAC disabled, WDigest enabled, weak SSH |
| Data Protection | 8 | Passwords in plaintext, sensitive data exposed |
| Persistence | 4 | Scheduled tasks, backdoor accounts |

---

## Prerequisites

### Hardware Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU Cores | 8 | 16+ |
| RAM | 24 GB | 32+ GB |
| Storage | 200 GB SSD | 500+ GB NVMe |

### Software Requirements

1. **Ludus Server** - Installed and configured
2. **Ludus CLI** - Installed on your management machine
3. **WireGuard** - For VPN access to the range

### Required Templates

- `win2019-server-x64-template`
- `win10-22h2-x64-enterprise-template`
- `ubuntu-22.04-x64-server-template`
- `debian-12-x64-server-template`

---

## Quick Start

### One-Command Deployment

```bash
# Clone this repository and checkout vulnerable branch
git clone <repository-url>
cd ccdc-practice-range
git checkout vulnerable-training-env

# Run full deployment
./scripts/deploy.sh full
```

### Manual Deployment

```bash
# 1. Add Ansible roles
ludus ansible role add -d ./ansible/roles/ccdc-windows-base
ludus ansible role add -d ./ansible/roles/ccdc-file-services
ludus ansible role add -d ./ansible/roles/ccdc-web-server
ludus ansible role add -d ./ansible/roles/ccdc-database-server
ludus ansible role add -d ./ansible/roles/ccdc-workstation-config

# 2. Set range configuration
ludus range config set -f ludus-config.yml

# 3. Deploy
ludus range deploy

# 4. Monitor progress
watch ludus range status
```

**Expected deployment time: 30-60 minutes**

---

## Training Exercises

### Exercise 1: Security Audit (Beginner)

**Objective**: Identify obvious security misconfigurations

**Tasks**:
1. Log into each system and document:
   - Firewall status
   - Antivirus/Defender status
   - User accounts and group memberships
   - Running services
2. Use [DETECTION.md](docs/DETECTION.md) to verify your findings
3. Prioritize vulnerabilities by severity

**Time**: 2-3 hours

### Exercise 2: Vulnerability Remediation (Intermediate)

**Objective**: Fix critical and high severity vulnerabilities

**Tasks**:
1. Review [VULNERABILITIES.md](docs/VULNERABILITIES.md) for the full list
2. Create a remediation plan prioritized by risk
3. Use [REMEDIATION.md](docs/REMEDIATION.md) to fix issues
4. Verify fixes using detection commands
5. Document all changes made

**Time**: 4-6 hours

### Exercise 3: Hardening Challenge (Advanced)

**Objective**: Secure the environment without breaking services

**Tasks**:
1. Create snapshots before starting
2. Implement all security controls
3. Verify services still function:
   - Web application accessible
   - Database queries work
   - File shares accessible to authorized users
   - Domain authentication works
4. Document what broke and how you fixed it

**Time**: Full day

### Exercise 4: Incident Response (Advanced)

**Objective**: Investigate and respond to compromised systems

**Setup**: Instructor deploys range, runs simulated attack, then students investigate

**Tasks**:
1. Identify indicators of compromise
2. Determine attack vector
3. Contain the threat
4. Eradicate malicious artifacts
5. Recover services
6. Write incident report

**Time**: 4-8 hours

### Competition Simulation

**Objective**: Practice CCDC-style defense scenario

**Rules**:
1. No internet access (test mode)
2. 4-hour time limit
3. Score based on:
   - Services uptime (50%)
   - Vulnerabilities fixed (30%)
   - Incident response (20%)

```bash
# Start competition mode (creates snapshot, blocks internet)
./scripts/deploy.sh test

# After competition, reset
./scripts/deploy.sh untest
```

---

## User Accounts

### Vulnerable Credentials (Intentionally Weak)

These accounts have weak passwords for training purposes:

| Account | Password | Location | Vulnerability |
|---------|----------|----------|---------------|
| BLUE\svc_backup | admin | Domain | V-WIN-EXTRA |
| BLUE\helpdesk | HelpDesk1 | Domain | V-WIN-EXTRA |
| backdoor | admin | WS01 Local | V-WS-006 |
| support | support | WS01 Local | V-WS-006 |
| root (MySQL) | root | DB01 | V-DB-001 |
| webapp | webapp | DB01 MySQL | V-DB-008 |
| admin | admin | DB01 MySQL | V-DB-009 |

### Domain Administrator

| Username | Password | Description |
|----------|----------|-------------|
| BLUE\itmgr | ITManager2024! | IT Manager - Full Domain Admin |

### Standard Domain Users

| Username | Password | Department |
|----------|----------|------------|
| BLUE\jsmith | JSmith2024! | Sales |
| BLUE\mjohnson | MJohnson2024! | HR |
| BLUE\bwilliams | BWilliams2024! | Finance |
| BLUE\slee | SLee2024! | IT |
| BLUE\dgarcia | DGarcia2024! | Marketing |
| BLUE\kwong | KWong2024! | IT |

### Local System Access

| Username | Password | Notes |
|----------|----------|-------|
| localuser | password | Ludus default |
| Administrator | CCDCAdmin2024! | Windows built-in |
| adminuser | AdminUser2024! | Linux servers |

---

## Scoring Checklist

Use this checklist during exercises to track progress:

### Critical Fixes (Must Complete)
- [ ] Enable Windows Firewall on all Windows systems
- [ ] Enable Windows Defender
- [ ] Remove/secure backdoor accounts
- [ ] Fix SQL injection vulnerability
- [ ] Fix command injection vulnerability
- [ ] Secure MySQL root access
- [ ] Enable UFW on Linux systems

### High Priority Fixes
- [ ] Enable audit policies
- [ ] Enable SMB signing
- [ ] Disable SMBv1
- [ ] Enable UAC
- [ ] Configure account lockout
- [ ] Remove anonymous MySQL user
- [ ] Secure SSH configuration
- [ ] Fix weak passwords

### Medium Priority Fixes
- [ ] Enable PowerShell logging
- [ ] Disable WDigest
- [ ] Configure NLA for RDP
- [ ] Remove sensitive files from shares
- [ ] Disable directory listing
- [ ] Remove phpinfo.php
- [ ] Configure fail2ban

### Bonus Points
- [ ] Install and configure Sysmon
- [ ] Set up centralized logging
- [ ] Create security monitoring dashboards
- [ ] Document all changes

---

## Troubleshooting

### Common Issues

**Deployment fails with template errors**
```bash
ludus templates list
ludus templates build -n <missing-template>
```

**Cannot connect to VMs**
```bash
# Check WireGuard
wg show

# Verify VM status
ludus range status
```

**Services don't work after fixing vulnerabilities**
- Create snapshots before making changes
- Test each change individually
- Check service logs for errors
- Refer to [REMEDIATION.md](docs/REMEDIATION.md) for safe fixes

### Useful Commands

```bash
# View deployment logs
ludus range logs

# SSH to Linux VM
ludus range ssh WEB01

# Reset to clean state
./scripts/deploy.sh restore pre-exercise
```

---

## File Structure

```
ccdc-practice-range/
├── ludus-config.yml              # Main Ludus configuration
├── README.md                     # This file
├── docs/
│   ├── VULNERABILITIES.md        # Complete vulnerability list
│   ├── DETECTION.md              # How to find vulnerabilities
│   └── REMEDIATION.md            # How to fix vulnerabilities
├── ansible/
│   └── roles/
│       ├── ccdc-windows-base/    # Windows vulnerabilities
│       ├── ccdc-file-services/   # File share vulnerabilities
│       ├── ccdc-web-server/      # Web app vulnerabilities
│       ├── ccdc-database-server/ # Database vulnerabilities
│       └── ccdc-workstation-config/ # Workstation vulnerabilities
└── scripts/
    └── deploy.sh                 # Deployment automation
```

---

## Resources

- [Ludus Documentation](https://docs.ludus.cloud)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [MITRE ATT&CK](https://attack.mitre.org)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

## Disclaimer

This vulnerable environment is provided for **educational purposes only**. The vulnerabilities are intentional and designed to teach security concepts.

**DO NOT**:
- Deploy in production environments
- Use techniques learned here maliciously
- Leave the environment running unattended

**ALWAYS**:
- Operate within your authorized scope
- Follow your institution's acceptable use policies
- Practice responsible disclosure

---

*CCDC Practice Range - Vulnerable Training Environment*
*Blue Team Industries*
