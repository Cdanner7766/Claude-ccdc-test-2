# Vulnerability Reference Guide

This document lists all intentionally introduced vulnerabilities in the CCDC Practice Range vulnerable environment.

---

## Summary by System

| System | Count | Severity Breakdown |
|--------|-------|-------------------|
| Domain Controller (DC01) | 20+ | Critical: 8, High: 7, Medium: 5+ |
| File Services (DC01) | 8 | Critical: 3, High: 3, Medium: 2 |
| Web Server (WEB01) | 15 | Critical: 4, High: 6, Medium: 5 |
| Database Server (DB01) | 13 | Critical: 5, High: 5, Medium: 3 |
| Workstation (WS01) | 14 | Critical: 3, High: 6, Medium: 5 |

---

## Windows Domain Controller (DC01)

### V-WIN-001: Windows Firewall Disabled
- **Severity**: Critical
- **Description**: Windows Firewall is disabled for all profiles (Domain, Private, Public)
- **Risk**: All network ports are exposed, allowing unrestricted network access
- **MITRE ATT&CK**: T1562.004 - Impair Defenses: Disable or Modify System Firewall

### V-WIN-002: Windows Defender Disabled
- **Severity**: Critical
- **Description**: Windows Defender real-time protection, behavior monitoring, and script scanning are disabled
- **Risk**: Malware can execute without detection
- **MITRE ATT&CK**: T1562.001 - Impair Defenses: Disable or Modify Tools

### V-WIN-003: Audit Policies Disabled
- **Severity**: High
- **Description**: All security audit policies are disabled (logon, account management, object access, etc.)
- **Risk**: No visibility into security events, attacker activity goes undetected
- **MITRE ATT&CK**: T1562.002 - Impair Defenses: Disable Windows Event Logging

### V-WIN-004: PowerShell Logging Disabled
- **Severity**: High
- **Description**: Script block logging, module logging, and command line logging are disabled
- **Risk**: PowerShell-based attacks are not recorded
- **MITRE ATT&CK**: T1562.003 - Impair Defenses: Impair Command History Logging

### V-WIN-005: Guest Account Enabled
- **Severity**: Medium
- **Description**: The built-in Guest account is enabled with password "guest123"
- **Risk**: Unauthorized access via well-known account
- **MITRE ATT&CK**: T1078.001 - Valid Accounts: Default Accounts

### V-WIN-006: Weak Password Policy
- **Severity**: Critical
- **Description**: Minimum password length is 4 characters, complexity disabled, no history
- **Risk**: Passwords are easily guessable or crackable
- **CIS Benchmark**: 1.1.1-1.1.7 Password Policy violations

### V-WIN-007: No Account Lockout Policy
- **Severity**: High
- **Description**: Account lockout threshold is set to 0 (no lockout)
- **Risk**: Brute force attacks can run indefinitely
- **CIS Benchmark**: 1.2.1-1.2.3 Account Lockout Policy violations

### V-WIN-008: LLMNR Enabled
- **Severity**: High
- **Description**: Link-Local Multicast Name Resolution remains enabled (default)
- **Risk**: LLMNR poisoning attacks (Responder)
- **MITRE ATT&CK**: T1557.001 - LLMNR/NBT-NS Poisoning

### V-WIN-009: NBT-NS Enabled
- **Severity**: High
- **Description**: NetBIOS Name Service remains enabled (default)
- **Risk**: NetBIOS poisoning attacks
- **MITRE ATT&CK**: T1557.001 - LLMNR/NBT-NS Poisoning

### V-WIN-010: SMB Signing Disabled
- **Severity**: High
- **Description**: SMB signing is not required on server or client
- **Risk**: SMB relay attacks possible
- **MITRE ATT&CK**: T1557.001 - Man-in-the-Middle: LLMNR/NBT-NS Poisoning

### V-WIN-011: Anonymous LDAP Binding Enabled
- **Severity**: Medium
- **Description**: Anonymous users can query Active Directory
- **Risk**: Domain enumeration without authentication
- **MITRE ATT&CK**: T1087.002 - Account Discovery: Domain Account

### V-WIN-012: Print Spooler Service Running
- **Severity**: Critical
- **Description**: Print Spooler service is running on the domain controller
- **Risk**: PrintNightmare vulnerability (CVE-2021-34527)
- **MITRE ATT&CK**: T1210 - Exploitation of Remote Services

### V-WIN-013: WDigest Authentication Enabled
- **Severity**: High
- **Description**: WDigest stores plaintext credentials in memory
- **Risk**: Credential dumping with Mimikatz
- **MITRE ATT&CK**: T1003.001 - OS Credential Dumping: LSASS Memory

### V-WIN-014: Reversible Encryption Enabled
- **Severity**: Medium
- **Description**: Passwords can be stored with reversible encryption
- **Risk**: Passwords can be decrypted from AD database
- **CIS Benchmark**: 1.1.2 violation

### V-WIN-015: LM Hash Storage Enabled
- **Severity**: High
- **Description**: LAN Manager hash storage is not prevented
- **Risk**: Weak LM hashes can be cracked easily
- **MITRE ATT&CK**: T1003.002 - OS Credential Dumping: Security Account Manager

### V-WIN-016: Null Session Access Enabled
- **Severity**: Medium
- **Description**: Anonymous enumeration of SAM accounts and shares is allowed
- **Risk**: Domain enumeration without credentials
- **MITRE ATT&CK**: T1087 - Account Discovery

### V-WIN-017: Remote Registry Service Enabled
- **Severity**: Medium
- **Description**: Remote Registry service is running and accessible
- **Risk**: Remote registry manipulation
- **MITRE ATT&CK**: T1112 - Modify Registry

### V-WIN-018: AutoPlay Enabled
- **Severity**: Medium
- **Description**: AutoPlay and AutoRun are enabled for all drive types
- **Risk**: Malware execution from removable media
- **MITRE ATT&CK**: T1091 - Replication Through Removable Media

### V-WIN-019: LSASS Not Protected
- **Severity**: High
- **Description**: LSASS is not running as Protected Process Light (PPL)
- **Risk**: LSASS credential dumping
- **MITRE ATT&CK**: T1003.001 - OS Credential Dumping: LSASS Memory

### V-WIN-020: Excessive Credential Caching
- **Severity**: Medium
- **Description**: 50 cached logons are stored (default is 10)
- **Risk**: Cached credentials can be stolen and cracked offline
- **MITRE ATT&CK**: T1003.005 - OS Credential Dumping: Cached Domain Credentials

### V-WIN-EXTRA: Vulnerable Service Accounts
- **Severity**: Critical
- **Description**: Service account "svc_backup" has password "admin" and is a Domain Admin
- **Risk**: Trivial privilege escalation
- **MITRE ATT&CK**: T1078.002 - Valid Accounts: Domain Accounts

---

## File Services (DC01)

### V-FS-001: Everyone Full Control on Shares
- **Severity**: Critical
- **Description**: SMB shares grant Everyone full control
- **Risk**: Any user can read, modify, or delete all files
- **CIS Benchmark**: Share permission violations

### V-FS-002: Sensitive Files in Public Locations
- **Severity**: High
- **Description**: Employee salary data and network diagrams in Public folder
- **Risk**: Data exposure to all employees
- **MITRE ATT&CK**: T1083 - File and Directory Discovery

### V-FS-003: Passwords Stored in Plaintext Files
- **Severity**: Critical
- **Description**: passwords.txt contains domain admin and service credentials
- **Risk**: Complete domain compromise if discovered
- **MITRE ATT&CK**: T1552.001 - Unsecured Credentials: Credentials in Files

### V-FS-004: Open Administrative Shares
- **Severity**: High
- **Description**: Administrative shares (C$, ADMIN$) are accessible
- **Risk**: Lateral movement via admin shares
- **MITRE ATT&CK**: T1021.002 - Remote Services: SMB/Windows Admin Shares

### V-FS-005: No File Screening
- **Severity**: Medium
- **Description**: File screening rules are not enforced
- **Risk**: Executables and scripts can be stored in shares
- **Impact**: Malware staging area

### V-FS-006: Weak NTFS Permissions
- **Severity**: High
- **Description**: NTFS permissions give Everyone full control
- **Risk**: File system access control bypassed
- **CIS Benchmark**: NTFS permission violations

### V-FS-007: Hidden Share with Sensitive Data
- **Severity**: Critical
- **Description**: AdminData$ hidden share contains master credentials
- **Risk**: AWS keys, Azure credentials, encryption keys exposed
- **MITRE ATT&CK**: T1552.001 - Unsecured Credentials: Credentials in Files

### V-FS-008: World-Writable Upload Directory
- **Severity**: High
- **Description**: Uploads folder allows anonymous write access
- **Risk**: Malware drop location, web shell staging
- **MITRE ATT&CK**: T1105 - Ingress Tool Transfer

---

## Web Server (WEB01)

### V-WEB-001: Directory Listing Enabled
- **Severity**: Medium
- **Description**: Apache directory indexing is enabled
- **Risk**: Information disclosure, file enumeration
- **OWASP**: A01:2021 - Broken Access Control

### V-WEB-002: Server Version Exposed
- **Severity**: Low
- **Description**: ServerSignature On, ServerTokens Full
- **Risk**: Version information aids targeted attacks
- **OWASP**: A05:2021 - Security Misconfiguration

### V-WEB-003: Weak SSH Configuration
- **Severity**: Critical
- **Description**: Root login permitted, empty passwords allowed, weak ciphers
- **Risk**: SSH brute force, credential stuffing
- **CIS Benchmark**: SSH configuration violations

### V-WEB-004: No Fail2ban Protection
- **Severity**: High
- **Description**: Fail2ban is not installed
- **Risk**: Unlimited brute force attempts
- **Impact**: Credential attacks unmitigated

### V-WEB-005: World-Readable Sensitive Files
- **Severity**: High
- **Description**: SSL private key has mode 0644
- **Risk**: SSL/TLS compromise
- **OWASP**: A02:2021 - Cryptographic Failures

### V-WEB-006: SQL Injection Vulnerability
- **Severity**: Critical
- **Description**: search.php does not sanitize user input
- **Risk**: Database compromise, data exfiltration
- **OWASP**: A03:2021 - Injection

### V-WEB-007: Credentials in Config Files
- **Severity**: Critical
- **Description**: config.php contains database and admin credentials
- **Risk**: Credential disclosure via web
- **OWASP**: A05:2021 - Security Misconfiguration

### V-WEB-008: Unnecessary Services Running
- **Severity**: Medium
- **Description**: Telnet and FTP with anonymous access are enabled
- **Risk**: Clear-text protocols, anonymous access
- **CIS Benchmark**: Service hardening violations

### V-WEB-009: Weak File Permissions
- **Severity**: High
- **Description**: Web root is mode 0777 (world-writable)
- **Risk**: Web shell upload, file modification
- **OWASP**: A01:2021 - Broken Access Control

### V-WEB-010: phpinfo() Exposed
- **Severity**: Medium
- **Description**: phpinfo.php reveals server configuration
- **Risk**: Information disclosure for targeted attacks
- **OWASP**: A05:2021 - Security Misconfiguration

### V-WEB-011: Backup Files Accessible
- **Severity**: High
- **Description**: backup.sql and config.php.bak in web root
- **Risk**: Credential and data exposure
- **OWASP**: A05:2021 - Security Misconfiguration

### V-WEB-012: .git Directory Exposed
- **Severity**: Medium
- **Description**: .git directory accessible via web
- **Risk**: Source code disclosure, credential exposure
- **OWASP**: A01:2021 - Broken Access Control

### V-WEB-013: Firewall Disabled
- **Severity**: High
- **Description**: UFW firewall is disabled
- **Risk**: All ports exposed
- **CIS Benchmark**: Firewall configuration violations

### V-WEB-014: Weak SSL/TLS Configuration
- **Severity**: High
- **Description**: SSLv3 and weak ciphers allowed, 1024-bit key
- **Risk**: POODLE, BEAST, weak encryption
- **OWASP**: A02:2021 - Cryptographic Failures

### V-WEB-015: Command Injection Vulnerability
- **Severity**: Critical
- **Description**: ping.php passes user input directly to system()
- **Risk**: Remote command execution
- **OWASP**: A03:2021 - Injection

---

## Database Server (DB01)

### V-DB-001: MySQL Root Remote Access
- **Severity**: Critical
- **Description**: Root user can connect from any host with password "root"
- **Risk**: Complete database compromise
- **CIS Benchmark**: MySQL root access violation

### V-DB-002: Anonymous MySQL User
- **Severity**: High
- **Description**: Anonymous user can connect and query databases
- **Risk**: Unauthorized data access
- **CIS Benchmark**: Anonymous user violation

### V-DB-003: Test Database Present
- **Severity**: Low
- **Description**: Test database exists with open permissions
- **Risk**: Potential for unauthorized testing/data
- **CIS Benchmark**: Test database violation

### V-DB-004: Insecure MySQL Configuration
- **Severity**: High
- **Description**: Symbolic links enabled, local_infile on, no SSL
- **Risk**: File system access, unencrypted connections
- **CIS Benchmark**: Multiple configuration violations

### V-DB-005: No Firewall Restrictions
- **Severity**: High
- **Description**: UFW firewall is disabled
- **Risk**: MySQL accessible from any network
- **CIS Benchmark**: Network access control violation

### V-DB-006: Query Logs World-Readable
- **Severity**: Medium
- **Description**: General query log accessible by any user
- **Risk**: SQL queries may contain sensitive data
- **Impact**: Information disclosure

### V-DB-007: Backup Files World-Readable
- **Severity**: Critical
- **Description**: Database backups in /var/backups/mysql are mode 0644
- **Risk**: Credential and data exposure
- **CIS Benchmark**: File permission violations

### V-DB-008: Weak Database User Passwords
- **Severity**: Critical
- **Description**: Application users have passwords matching usernames
- **Risk**: Easy credential guessing
- **MITRE ATT&CK**: T1078 - Valid Accounts

### V-DB-009: Excessive User Privileges
- **Severity**: High
- **Description**: Application users have ALL privileges on all databases
- **Risk**: Principle of least privilege violated
- **CIS Benchmark**: Privilege management violation

### V-DB-010: Weak SSH Configuration
- **Severity**: Critical
- **Description**: Root login permitted, empty passwords allowed
- **Risk**: SSH compromise
- **CIS Benchmark**: SSH configuration violations

### V-DB-011: Credentials in Accessible Files
- **Severity**: Critical
- **Description**: .my.cnf world-readable, credentials in /tmp
- **Risk**: Easy credential harvesting
- **MITRE ATT&CK**: T1552.001 - Unsecured Credentials: Credentials in Files

### V-DB-012: Sensitive Data Unencrypted
- **Severity**: High
- **Description**: secrets.credentials table contains plaintext passwords and API keys
- **Risk**: Data breach impact multiplied
- **OWASP**: A02:2021 - Cryptographic Failures

### V-DB-013: No Brute Force Protection
- **Severity**: Medium
- **Description**: No fail2ban or similar protection
- **Risk**: Unlimited authentication attempts
- **Impact**: Credential attacks unmitigated

---

## Workstation (WS01)

### V-WS-001: Windows Firewall Disabled
- **Severity**: Critical
- **Description**: Windows Firewall disabled for all profiles
- **Risk**: All ports exposed
- **CIS Benchmark**: Firewall configuration violations

### V-WS-002: Windows Defender Disabled
- **Severity**: Critical
- **Description**: All Defender protections disabled
- **Risk**: Malware runs undetected
- **MITRE ATT&CK**: T1562.001 - Impair Defenses: Disable or Modify Tools

### V-WS-003: Audit Policies Disabled
- **Severity**: High
- **Description**: Security auditing disabled
- **Risk**: No forensic evidence collected
- **CIS Benchmark**: Audit policy violations

### V-WS-004: UAC Disabled
- **Severity**: Critical
- **Description**: User Account Control is disabled
- **Risk**: Privilege escalation without user consent
- **CIS Benchmark**: UAC configuration violations

### V-WS-005: SMBv1 Enabled
- **Severity**: High
- **Description**: SMBv1 protocol is enabled
- **Risk**: EternalBlue and similar attacks
- **MITRE ATT&CK**: T1210 - Exploitation of Remote Services

### V-WS-006: Weak Local Admin Accounts
- **Severity**: Critical
- **Description**: "backdoor" and "support" accounts with simple passwords
- **Risk**: Local privilege escalation
- **MITRE ATT&CK**: T1078.003 - Valid Accounts: Local Accounts

### V-WS-007: AutoRun Enabled
- **Severity**: Medium
- **Description**: AutoRun and AutoPlay enabled
- **Risk**: Malware execution from removable media
- **MITRE ATT&CK**: T1091 - Replication Through Removable Media

### V-WS-008: Weak RDP Configuration
- **Severity**: High
- **Description**: NLA disabled, weak encryption
- **Risk**: RDP man-in-the-middle attacks
- **CIS Benchmark**: RDP configuration violations

### V-WS-010: PowerShell Logging Disabled
- **Severity**: High
- **Description**: Script block and module logging disabled
- **Risk**: PowerShell attacks undetected
- **MITRE ATT&CK**: T1562.003 - Impair Command History Logging

### V-WS-011: No Sysmon Installed
- **Severity**: Medium
- **Description**: Sysmon endpoint monitoring is not installed
- **Risk**: Limited endpoint visibility
- **Impact**: Threat hunting handicapped

### V-WS-012: Unnecessary Services Running
- **Severity**: Medium
- **Description**: Remote Registry, Telnet client enabled
- **Risk**: Increased attack surface
- **CIS Benchmark**: Service hardening violations

### V-WS-013: Weak Screen Lock Settings
- **Severity**: Low
- **Description**: No screen lock timeout, no password requirement
- **Risk**: Physical access attacks
- **CIS Benchmark**: Screen lock violations

### V-WS-014: Sensitive Files on Desktop
- **Severity**: High
- **Description**: Password files on Public Desktop
- **Risk**: Credential exposure to any user
- **MITRE ATT&CK**: T1552.001 - Unsecured Credentials: Credentials in Files

---

## Vulnerability by MITRE ATT&CK Tactic

### Initial Access
- V-WEB-003: Weak SSH Configuration
- V-DB-010: Weak SSH Configuration
- V-WIN-005: Guest Account Enabled

### Execution
- V-WEB-015: Command Injection
- V-WS-007: AutoRun Enabled
- V-WIN-018: AutoPlay Enabled

### Persistence
- Suspicious Scheduled Tasks on DC01 and WS01
- V-WS-006: Backdoor Admin Accounts

### Privilege Escalation
- V-WS-004: UAC Disabled
- V-WIN-EXTRA: Vulnerable Service Accounts
- V-DB-009: Excessive Database Privileges

### Defense Evasion
- V-WIN-001/V-WS-001: Firewall Disabled
- V-WIN-002/V-WS-002: Defender Disabled
- V-WIN-003/V-WS-003: Audit Policies Disabled
- V-WIN-004/V-WS-010: PowerShell Logging Disabled

### Credential Access
- V-WIN-013: WDigest Enabled
- V-WIN-015: LM Hash Storage
- V-WIN-019: LSASS Not Protected
- V-FS-003: Passwords in Files
- V-DB-011: Credentials in Files

### Discovery
- V-WIN-011: Anonymous LDAP
- V-WIN-016: Null Session Access
- V-WEB-001: Directory Listing
- V-WEB-010: phpinfo() Exposed

### Lateral Movement
- V-WIN-010: SMB Signing Disabled
- V-WIN-008/009: LLMNR/NBT-NS Enabled
- V-FS-004: Administrative Shares
- V-WS-005: SMBv1 Enabled

### Collection
- V-FS-002: Sensitive Files Exposed
- V-DB-012: Unencrypted Sensitive Data

### Exfiltration
- V-WEB-006: SQL Injection
- V-DB-001: Remote Database Access
