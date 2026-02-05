# Vulnerability Detection Guide

This document provides methods to detect each vulnerability in the CCDC Practice Range.

---

## Windows Systems Detection

### V-WIN-001: Windows Firewall Disabled

**Command Line Check:**
```powershell
# Check firewall status for all profiles
Get-NetFirewallProfile | Select-Object Name, Enabled

# Expected vulnerable output:
# Name    Enabled
# ----    -------
# Domain  False
# Private False
# Public  False
```

**GUI Check:**
- Open Windows Defender Firewall with Advanced Security
- Check "Windows Defender Firewall Properties" for each profile

---

### V-WIN-002: Windows Defender Disabled

**Command Line Check:**
```powershell
# Check Defender status
Get-MpPreference | Select-Object DisableRealtimeMonitoring, DisableBehaviorMonitoring, DisableScriptScanning

# Vulnerable if any value is True
```

**GUI Check:**
- Open Windows Security > Virus & threat protection
- Check if Real-time protection is Off

---

### V-WIN-003: Audit Policies Disabled

**Command Line Check:**
```cmd
# View all audit policy settings
auditpol /get /category:*

# Look for "No Auditing" in results
auditpol /get /subcategory:"Logon"
auditpol /get /subcategory:"Process Creation"
```

**Expected Secure Output:**
```
Logon: Success and Failure
Process Creation: Success
```

---

### V-WIN-004: PowerShell Logging Disabled

**Registry Check:**
```powershell
# Check Script Block Logging
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -ErrorAction SilentlyContinue

# Check Module Logging
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -ErrorAction SilentlyContinue

# Vulnerable if value is 0 or key doesn't exist
```

---

### V-WIN-005: Guest Account Enabled

**Command Line Check:**
```powershell
# Check Guest account status
Get-LocalUser -Name Guest | Select-Object Name, Enabled

# Vulnerable if Enabled is True
```

---

### V-WIN-006: Weak Password Policy

**Command Line Check (Domain Controller):**
```powershell
# Get domain password policy
Get-ADDefaultDomainPasswordPolicy

# Check for:
# - MinPasswordLength less than 12
# - ComplexityEnabled is False
# - PasswordHistoryCount is 0
```

---

### V-WIN-007: No Account Lockout Policy

**Command Line Check:**
```powershell
# Get domain password policy
Get-ADDefaultDomainPasswordPolicy | Select-Object LockoutThreshold, LockoutDuration

# Vulnerable if LockoutThreshold is 0
```

---

### V-WIN-010: SMB Signing Disabled

**Command Line Check:**
```powershell
# Check SMB server signing
Get-SmbServerConfiguration | Select-Object RequireSecuritySignature

# Check SMB client signing
Get-SmbClientConfiguration | Select-Object RequireSecuritySignature

# Vulnerable if RequireSecuritySignature is False
```

**Registry Check:**
```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature"
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature"
```

---

### V-WIN-012: Print Spooler Running

**Command Line Check:**
```powershell
# Check Print Spooler service status
Get-Service -Name Spooler | Select-Object Status, StartType

# Vulnerable on domain controllers if Status is Running
```

---

### V-WIN-013: WDigest Enabled

**Registry Check:**
```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -ErrorAction SilentlyContinue

# Vulnerable if value is 1
```

---

### V-WIN-016: Null Session Access

**Registry Check:**
```powershell
# Check RestrictAnonymous
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous"
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymousSAM"

# Vulnerable if values are 0
```

**Network Test:**
```bash
# From Linux/Kali
rpcclient -U "" -N <target_ip> -c "enumdomusers"
# If enumeration works, null sessions are enabled
```

---

### V-WIN-017: Remote Registry Enabled

**Command Line Check:**
```powershell
Get-Service -Name RemoteRegistry | Select-Object Status, StartType

# Vulnerable if Status is Running
```

---

### V-WIN-EXTRA: Vulnerable Accounts

**Check for Suspicious Accounts:**
```powershell
# List all domain admins
Get-ADGroupMember -Identity "Domain Admins" | Select-Object Name, SamAccountName

# Check for service accounts with weak passwords
Get-ADUser -Filter {SamAccountName -like "svc_*"} -Properties Description

# Look for: svc_backup, helpdesk with suspicious descriptions
```

---

## File Services Detection

### V-FS-001: Everyone Full Control

**Command Line Check:**
```powershell
# Check share permissions
Get-SmbShareAccess -Name "SharedFiles"

# Look for "Everyone" with "Full" access
```

**NTFS Permission Check:**
```powershell
Get-Acl "C:\Shares\SharedFiles" | Format-List

# Look for "Everyone" with "FullControl"
```

---

### V-FS-003: Passwords in Files

**File Search:**
```powershell
# Search for password files
Get-ChildItem -Path "C:\Shares" -Recurse -Include "*password*", "*credential*", "*.txt" | Select-Object FullName

# Search file contents
Select-String -Path "C:\Shares\*\*" -Pattern "password" -Recurse
```

---

### V-FS-007: Hidden Shares

**List All Shares:**
```powershell
Get-SmbShare | Select-Object Name, Path, Description

# Look for shares ending with $ (hidden shares)
```

---

## Linux Web Server Detection

### V-WEB-001: Directory Listing

**Test via Browser:**
```
Navigate to http://<server>/
If you see "Index of /" with file listing, directory listing is enabled
```

**Apache Config Check:**
```bash
grep -r "Options.*Indexes" /etc/apache2/
# Vulnerable if "+Indexes" is found
```

---

### V-WEB-002: Server Version Exposed

**HTTP Header Check:**
```bash
curl -I http://<server>/ | grep Server

# Vulnerable if full version is shown:
# Server: Apache/2.4.52 (Ubuntu)
```

---

### V-WEB-003: Weak SSH Configuration

**Config Check:**
```bash
grep -E "^(PermitRootLogin|PasswordAuthentication|PermitEmptyPasswords)" /etc/ssh/sshd_config

# Vulnerable if:
# PermitRootLogin yes
# PasswordAuthentication yes
# PermitEmptyPasswords yes
```

---

### V-WEB-006: SQL Injection

**Manual Test:**
```
Navigate to: http://<server>/search.php?search=' OR '1'='1
If all records are returned, SQL injection is present

Add debug parameter: ?search=test&debug=1
If query is displayed, debug mode is enabled
```

---

### V-WEB-007: Credentials in Config Files

**File Check:**
```bash
# Check for readable config files
cat /var/www/html/config.php

# Look for define() statements with credentials
```

**Web Access Test:**
```
Navigate to: http://<server>/config.php
If PHP source code is displayed, PHP is not processing files correctly
```

---

### V-WEB-010: phpinfo() Exposed

**Test:**
```
Navigate to: http://<server>/phpinfo.php
If PHP configuration is displayed, phpinfo is exposed
```

---

### V-WEB-011: Backup Files

**Test:**
```bash
curl http://<server>/backup.sql
curl http://<server>/config.php.bak

# If content is returned, backup files are accessible
```

---

### V-WEB-012: .git Directory

**Test:**
```bash
curl http://<server>/.git/config

# If git config is returned, .git directory is exposed
```

---

### V-WEB-013: Firewall Status

**Check:**
```bash
sudo ufw status

# Vulnerable if "Status: inactive"
```

---

### V-WEB-015: Command Injection

**Test:**
```
Navigate to: http://<server>/ping.php?host=127.0.0.1;id

# If "uid=" output appears, command injection is present
```

---

## Database Server Detection

### V-DB-001: MySQL Root Remote Access

**Test:**
```bash
# From remote machine
mysql -h <db_server> -u root -proot -e "SELECT 'Connected';"

# If connection succeeds, root remote access is enabled
```

---

### V-DB-002: Anonymous User

**Check:**
```bash
mysql -u root -p -e "SELECT User, Host FROM mysql.user WHERE User='';"

# If rows are returned, anonymous users exist
```

---

### V-DB-003: Test Database

**Check:**
```bash
mysql -u root -p -e "SHOW DATABASES;" | grep test

# If "test" appears, test database exists
```

---

### V-DB-005: Firewall Status

**Check:**
```bash
sudo ufw status

# Vulnerable if "Status: inactive"
```

---

### V-DB-008: Weak Passwords

**Test Common Passwords:**
```bash
# Try username as password
mysql -h <db_server> -u webapp -pwebapp -e "SELECT 1;"
mysql -h <db_server> -u hrapp -phrapp -e "SELECT 1;"
mysql -h <db_server> -u admin -padmin -e "SELECT 1;"
```

---

### V-DB-011: Credentials in Files

**Check:**
```bash
# Check .my.cnf permissions and content
ls -la /root/.my.cnf
cat /root/.my.cnf

# Check /tmp for credential files
ls -la /tmp/*credential* /tmp/*mysql*
```

---

### V-DB-012: Sensitive Data

**Query:**
```sql
USE secrets;
SHOW TABLES;
SELECT * FROM credentials LIMIT 5;
SELECT * FROM api_keys LIMIT 5;
```

---

## Workstation Detection

### V-WS-004: UAC Disabled

**Registry Check:**
```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA"

# Vulnerable if EnableLUA is 0
```

---

### V-WS-005: SMBv1 Enabled

**Check:**
```powershell
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Select-Object State

# Vulnerable if State is "Enabled"
```

---

### V-WS-006: Weak Local Accounts

**Check:**
```powershell
Get-LocalUser | Select-Object Name, Enabled, Description

# Look for suspicious accounts like "backdoor", "support"

# Check local administrators
Get-LocalGroupMember -Group "Administrators"
```

---

### V-WS-008: Weak RDP Settings

**Registry Check:**
```powershell
# Check NLA requirement
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication"

# Vulnerable if UserAuthentication is 0
```

---

### V-WS-014: Sensitive Files

**Check:**
```powershell
Get-ChildItem -Path "C:\Users\Public\Desktop" -Filter "*.txt"

# Look for password files, IT info, etc.
type "C:\Users\Public\Desktop\passwords.txt"
```

---

## Automated Scanning Tools

### Windows
```powershell
# Use PingCastle for AD assessment
.\PingCastle.exe --healthcheck

# Use Bloodhound for attack path analysis
.\SharpHound.exe -c All

# Use Windows Sysinternals AccessChk
accesschk.exe -uwcqv "Everyone" *
```

### Linux
```bash
# Use Lynis for system auditing
sudo lynis audit system

# Use Nikto for web scanning
nikto -h http://<target>

# Use SQLMap for SQL injection
sqlmap -u "http://<target>/search.php?search=test" --dbs
```

### Network
```bash
# Use Nmap for service detection
nmap -sV -sC -O <target>

# Use CrackMapExec for SMB enumeration
crackmapexec smb <target> -u '' -p ''

# Use enum4linux for null session testing
enum4linux -a <target>
```
