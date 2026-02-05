# Vulnerability Remediation Guide

This document provides step-by-step instructions to fix each vulnerability in the CCDC Practice Range.

---

## Windows Systems Remediation

### V-WIN-001: Windows Firewall Disabled

**Fix:**
```powershell
# Enable Windows Firewall for all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Verify
Get-NetFirewallProfile | Select-Object Name, Enabled
```

**Recommended Configuration:**
```powershell
# Configure with secure defaults
Set-NetFirewallProfile -Profile Domain -DefaultInboundAction Block -DefaultOutboundAction Allow
Set-NetFirewallProfile -Profile Private -DefaultInboundAction Block -DefaultOutboundAction Allow
Set-NetFirewallProfile -Profile Public -DefaultInboundAction Block -DefaultOutboundAction Allow
```

---

### V-WIN-002: Windows Defender Disabled

**Fix:**
```powershell
# Re-enable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -DisableBlockAtFirstSeen $false
Set-MpPreference -DisableIOAVProtection $false
Set-MpPreference -DisableScriptScanning $false
Set-MpPreference -SubmitSamplesConsent 1

# Update definitions
Update-MpSignature

# Verify status
Get-MpComputerStatus
```

---

### V-WIN-003: Audit Policies Disabled

**Fix:**
```powershell
# Enable comprehensive audit policy
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Logoff" /success:enable
auditpol /set /subcategory:"Special Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Account Lockout" /success:enable /failure:enable
auditpol /set /subcategory:"Process Creation" /success:enable
auditpol /set /subcategory:"Process Termination" /success:enable
auditpol /set /subcategory:"Audit Policy Change" /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Computer Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Directory Service Changes" /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Authentication Service" /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable

# Verify
auditpol /get /category:*
```

---

### V-WIN-004: PowerShell Logging Disabled

**Fix:**
```powershell
# Enable Script Block Logging
$basePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"

# Create keys if they don't exist
New-Item -Path "$basePath\ScriptBlockLogging" -Force
New-Item -Path "$basePath\ModuleLogging" -Force
New-Item -Path "$basePath\Transcription" -Force

# Enable Script Block Logging
Set-ItemProperty -Path "$basePath\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1
Set-ItemProperty -Path "$basePath\ScriptBlockLogging" -Name "EnableScriptBlockInvocationLogging" -Value 1

# Enable Module Logging
Set-ItemProperty -Path "$basePath\ModuleLogging" -Name "EnableModuleLogging" -Value 1
New-Item -Path "$basePath\ModuleLogging\ModuleNames" -Force
Set-ItemProperty -Path "$basePath\ModuleLogging\ModuleNames" -Name "*" -Value "*"

# Enable Transcription
Set-ItemProperty -Path "$basePath\Transcription" -Name "EnableTranscripting" -Value 1
Set-ItemProperty -Path "$basePath\Transcription" -Name "OutputDirectory" -Value "C:\PSTranscripts"
```

---

### V-WIN-005: Guest Account Enabled

**Fix:**
```powershell
# Disable Guest account
Disable-LocalUser -Name "Guest"

# Verify
Get-LocalUser -Name "Guest" | Select-Object Name, Enabled
```

---

### V-WIN-006: Weak Password Policy

**Fix (Domain Controller):**
```powershell
# Set strong password policy
Set-ADDefaultDomainPasswordPolicy -Identity "blue.lab" `
    -MinPasswordLength 14 `
    -PasswordHistoryCount 24 `
    -MaxPasswordAge (New-TimeSpan -Days 90) `
    -MinPasswordAge (New-TimeSpan -Days 1) `
    -ComplexityEnabled $true `
    -ReversibleEncryptionEnabled $false

# Verify
Get-ADDefaultDomainPasswordPolicy
```

---

### V-WIN-007: No Account Lockout Policy

**Fix:**
```powershell
# Configure account lockout policy
Set-ADDefaultDomainPasswordPolicy -Identity "blue.lab" `
    -LockoutThreshold 5 `
    -LockoutDuration (New-TimeSpan -Minutes 30) `
    -LockoutObservationWindow (New-TimeSpan -Minutes 30)

# Verify
Get-ADDefaultDomainPasswordPolicy | Select-Object LockoutThreshold, LockoutDuration, LockoutObservationWindow
```

---

### V-WIN-008: LLMNR Enabled

**Fix:**
```powershell
# Disable LLMNR via registry
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -Type DWord
```

**Via Group Policy:**
- Computer Configuration > Administrative Templates > Network > DNS Client
- Turn off multicast name resolution: Enabled

---

### V-WIN-009: NetBIOS over TCP/IP Enabled

**Fix:**
```powershell
# Disable NetBIOS on all adapters
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
foreach ($adapter in $adapters) {
    $adapter.SetTcpipNetbios(2)  # 2 = Disable
}

# Verify
Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } |
    Select-Object Description, TcpipNetbiosOptions
```

---

### V-WIN-010: SMB Signing Disabled

**Fix:**
```powershell
# Enable SMB Server signing
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force

# Enable SMB Client signing
Set-SmbClientConfiguration -RequireSecuritySignature $true -Force

# Via Registry
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -Value 1
```

---

### V-WIN-011: SMBv1 Enabled

**Fix:**
```powershell
# Disable SMBv1 Server
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

# Disable SMBv1 Client (Windows Feature)
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart

# Verify
Get-SmbServerConfiguration | Select-Object EnableSMB1Protocol
```

---

### V-WIN-012: Print Spooler Running on DC

**Fix:**
```powershell
# Stop and disable Print Spooler on domain controllers
Stop-Service -Name Spooler
Set-Service -Name Spooler -StartupType Disabled

# Verify
Get-Service -Name Spooler | Select-Object Status, StartType
```

---

### V-WIN-013: WDigest Enabled

**Fix:**
```powershell
# Disable WDigest credential caching
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -Value 0 -Type DWord

# Verify
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential"
```

---

### V-WIN-014: Kerberos Weak Encryption

**Fix (Domain Controller):**
```powershell
# Disable weak Kerberos encryption types via Group Policy
# Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > Security Options
# Network security: Configure encryption types allowed for Kerberos

# Registry method:
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters" `
    -Name "SupportedEncryptionTypes" -Value 2147483640 -Type DWord  # AES128, AES256 only
```

---

### V-WIN-015: LSA Protection Disabled

**Fix:**
```powershell
# Enable LSA Protection
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -Value 1 -Type DWord

# Restart required for this change to take effect
```

---

### V-WIN-016: Null Session Access

**Fix:**
```powershell
# Restrict anonymous access
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous" -Value 2 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymousSAM" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "EveryoneIncludesAnonymous" -Value 0 -Type DWord

# Clear named pipe access
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "NullSessionPipes" -Value @() -Type MultiString
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "NullSessionShares" -Value @() -Type MultiString
```

---

### V-WIN-017: Remote Registry Enabled

**Fix:**
```powershell
# Stop and disable Remote Registry service
Stop-Service -Name RemoteRegistry
Set-Service -Name RemoteRegistry -StartupType Disabled

# Verify
Get-Service -Name RemoteRegistry | Select-Object Status, StartType
```

---

### V-WIN-EXTRA: Vulnerable Accounts

**Fix:**
```powershell
# Change weak service account passwords
Set-ADAccountPassword -Identity "svc_backup" -NewPassword (Read-Host "New Password" -AsSecureString) -Reset
Set-ADAccountPassword -Identity "helpdesk" -NewPassword (Read-Host "New Password" -AsSecureString) -Reset

# Disable unnecessary accounts
Disable-ADAccount -Identity "helpdesk"

# Remove from Domain Admins if not needed
Remove-ADGroupMember -Identity "Domain Admins" -Members "helpdesk" -Confirm:$false

# Set strong passwords (minimum 16 characters with complexity)
```

---

## File Services Remediation

### V-FS-001: Everyone Full Control

**Fix:**
```powershell
# Remove Everyone from share permissions
Revoke-SmbShareAccess -Name "SharedFiles" -AccountName "Everyone" -Force

# Set proper share permissions
Grant-SmbShareAccess -Name "SharedFiles" -AccountName "BLUE\Domain Users" -AccessRight Read -Force
Grant-SmbShareAccess -Name "SharedFiles" -AccountName "BLUE\Domain Admins" -AccessRight Full -Force

# Set proper NTFS permissions
$acl = Get-Acl "C:\Shares\SharedFiles"
$acl.SetAccessRuleProtection($true, $false)  # Disable inheritance

# Remove Everyone
$acl.Access | Where-Object { $_.IdentityReference -eq "Everyone" } | ForEach-Object {
    $acl.RemoveAccessRule($_)
}

# Add proper permissions
$domainUsersRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BLUE\Domain Users", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$domainAdminsRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BLUE\Domain Admins", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")

$acl.AddAccessRule($domainUsersRule)
$acl.AddAccessRule($domainAdminsRule)
Set-Acl "C:\Shares\SharedFiles" $acl
```

---

### V-FS-002: Sensitive Data Exposed

**Fix:**
```powershell
# Remove all IT_ folders from shares with confidential data
Remove-Item -Path "C:\Shares\SharedFiles\IT_*" -Recurse -Force

# Or restrict access to IT folders
$acl = Get-Acl "C:\Shares\SharedFiles\IT_Docs"
$acl.SetAccessRuleProtection($true, $false)
$itRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BLUE\IT Staff", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($itRule)
Set-Acl "C:\Shares\SharedFiles\IT_Docs" $acl
```

---

### V-FS-003: Passwords in Files

**Fix:**
```powershell
# Delete all password files
Get-ChildItem -Path "C:\Shares" -Recurse -Include "*password*", "*credential*", "*.txt" |
    Where-Object { $_.Name -match "password|credential|secret" } |
    Remove-Item -Force

# Search and verify
Select-String -Path "C:\Shares\*\*" -Pattern "password" -Recurse
```

---

### V-FS-007: Hidden Shares

**Fix:**
```powershell
# List and remove hidden admin shares (except default system shares)
Get-SmbShare | Where-Object { $_.Name -like "*$" -and $_.Name -notin @("C$", "ADMIN$", "IPC$") } |
    Remove-SmbShare -Force

# Prevent automatic recreation of admin shares (if needed)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" `
    -Name "AutoShareServer" -Value 0 -Type DWord
```

---

## Linux Web Server Remediation

### V-WEB-001: Directory Listing

**Fix:**
```bash
# Disable directory listing in Apache
sudo sed -i 's/Options Indexes/Options -Indexes/g' /etc/apache2/apache2.conf
sudo sed -i 's/Options Indexes/Options -Indexes/g' /etc/apache2/sites-available/*.conf

# Or add to .htaccess
echo "Options -Indexes" | sudo tee /var/www/html/.htaccess

# Restart Apache
sudo systemctl restart apache2
```

---

### V-WEB-002: Server Version Exposed

**Fix:**
```bash
# Hide Apache version
sudo bash -c 'cat >> /etc/apache2/conf-enabled/security.conf << EOF
ServerTokens Prod
ServerSignature Off
EOF'

# Hide PHP version
sudo sed -i 's/expose_php = On/expose_php = Off/' /etc/php/*/apache2/php.ini

# Restart Apache
sudo systemctl restart apache2
```

---

### V-WEB-003: Weak SSH Configuration

**Fix:**
```bash
# Create secure SSH configuration
sudo bash -c 'cat > /etc/ssh/sshd_config << EOF
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers adminuser
LoginGraceTime 60
Banner /etc/issue.net
Subsystem sftp /usr/lib/openssh/sftp-server
EOF'

# Restart SSH
sudo systemctl restart ssh
```

---

### V-WEB-004: Weak User Passwords

**Fix:**
```bash
# Force password change
sudo passwd -e adminuser

# Set strong password policy
sudo apt install libpam-pwquality
sudo bash -c 'cat > /etc/security/pwquality.conf << EOF
minlen = 14
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
minclass = 3
maxrepeat = 3
EOF'
```

---

### V-WEB-005: World-Writable Directories

**Fix:**
```bash
# Remove world-writable from web directories
sudo chmod -R o-w /var/www/html/

# Set proper ownership
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
sudo chmod -R 644 /var/www/html/*.php

# Find and fix world-writable files
find /var/www -type f -perm -002 -exec chmod o-w {} \;
find /var/www -type d -perm -002 -exec chmod o-w {} \;
```

---

### V-WEB-006: SQL Injection

**Fix:**
Replace vulnerable PHP code with parameterized queries:
```php
<?php
// SECURE: Using Prepared Statements
$pdo = new PDO('mysql:host=localhost;dbname=employees', 'webapp', 'SecureP@ssw0rd!');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$search = $_GET['search'] ?? '';
$stmt = $pdo->prepare("SELECT * FROM employees WHERE first_name LIKE :search OR last_name LIKE :search");
$stmt->execute(['search' => "%{$search}%"]);
$results = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Never output raw SQL queries
// Remove debug parameter handling
?>
```

---

### V-WEB-007: Credentials in Config Files

**Fix:**
```bash
# Move config outside web root
sudo mv /var/www/html/config.php /var/www/config.php

# Update include path
# In PHP files: require_once '/var/www/config.php';

# Set restrictive permissions
sudo chmod 640 /var/www/config.php
sudo chown www-data:www-data /var/www/config.php

# Use environment variables instead
# In /etc/apache2/envvars:
# export DB_USER="webapp"
# export DB_PASS="SecurePassword"
```

---

### V-WEB-010: phpinfo() Exposed

**Fix:**
```bash
# Delete phpinfo file
sudo rm -f /var/www/html/phpinfo.php

# Disable phpinfo function in php.ini
sudo sed -i 's/disable_functions = /disable_functions = phpinfo,/' /etc/php/*/apache2/php.ini

# Restart Apache
sudo systemctl restart apache2
```

---

### V-WEB-011: Backup Files

**Fix:**
```bash
# Remove backup files
sudo rm -f /var/www/html/*.bak
sudo rm -f /var/www/html/*.sql
sudo rm -f /var/www/html/*.old
sudo rm -f /var/www/html/*~

# Block backup files in Apache
sudo bash -c 'cat >> /etc/apache2/conf-enabled/security.conf << EOF
<FilesMatch "\.(bak|sql|old|orig|~)$">
    Require all denied
</FilesMatch>
EOF'

sudo systemctl restart apache2
```

---

### V-WEB-012: .git Directory

**Fix:**
```bash
# Remove .git directory
sudo rm -rf /var/www/html/.git

# Block access in Apache
sudo bash -c 'cat >> /etc/apache2/conf-enabled/security.conf << EOF
<DirectoryMatch "/\.git">
    Require all denied
</DirectoryMatch>
EOF'

sudo systemctl restart apache2
```

---

### V-WEB-013: Firewall Disabled

**Fix:**
```bash
# Enable UFW
sudo ufw enable

# Allow necessary services
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Deny everything else by default
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Verify
sudo ufw status verbose
```

---

### V-WEB-014: No fail2ban

**Fix:**
```bash
# Install and configure fail2ban
sudo apt install fail2ban -y

# Create jail configuration
sudo bash -c 'cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[apache-auth]
enabled = true
port = http,https
logpath = /var/log/apache2/error.log
maxretry = 5
EOF'

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

### V-WEB-015: Command Injection

**Fix:**
Replace vulnerable PHP code with secure validation:
```php
<?php
// SECURE: Command Injection Prevention
$host = $_GET['host'] ?? '';

// Whitelist validation - only allow IP addresses
if (!filter_var($host, FILTER_VALIDATE_IP)) {
    die("Invalid IP address");
}

// Use escapeshellarg() for safety
$output = shell_exec("ping -c 4 " . escapeshellarg($host));

// Better: Use built-in functions instead of shell commands
// Or implement functionality without shell execution
?>
```

---

## Database Server Remediation

### V-DB-001: MySQL Root Remote Access

**Fix:**
```sql
-- Remove remote root access
DROP USER IF EXISTS 'root'@'%';

-- Change root password to strong password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'V3ryStr0ng&C0mpl3xP@ssw0rd!';

-- Verify
SELECT User, Host FROM mysql.user WHERE User='root';
```

---

### V-DB-002: Anonymous User

**Fix:**
```sql
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;

-- Verify
SELECT User, Host FROM mysql.user WHERE User='';
```

---

### V-DB-003: Test Database

**Fix:**
```sql
-- Drop test database
DROP DATABASE IF EXISTS test;

-- Remove privileges
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;

-- Verify
SHOW DATABASES LIKE 'test';
```

---

### V-DB-004: Insecure MySQL Configuration

**Fix:**
```bash
# Create secure MySQL configuration
sudo bash -c 'cat > /etc/mysql/mariadb.conf.d/99-secure.cnf << EOF
[mysqld]
# Bind to localhost only
bind-address=127.0.0.1

# Disable symbolic links
symbolic-links=0

# Disable local file loading
local_infile=0

# Disable general query log in production
general_log=0

# Require SSL for connections
# ssl=1
# ssl-ca=/etc/mysql/ssl/ca-cert.pem
# ssl-cert=/etc/mysql/ssl/server-cert.pem
# ssl-key=/etc/mysql/ssl/server-key.pem

# Set secure file permissions
secure_file_priv=/var/lib/mysql-files
EOF'

sudo systemctl restart mysql
```

---

### V-DB-005: Firewall Disabled

**Fix:**
```bash
# Enable UFW
sudo ufw enable

# Only allow MySQL from specific hosts
sudo ufw allow from 10.X.10.20 to any port 3306  # Web server only
sudo ufw allow ssh

sudo ufw default deny incoming
sudo ufw status
```

---

### V-DB-006: Logs World-Readable

**Fix:**
```bash
# Set proper permissions on MySQL logs
sudo chmod 750 /var/log/mysql
sudo chmod 640 /var/log/mysql/*
sudo chown -R mysql:adm /var/log/mysql
```

---

### V-DB-007: World-Readable Backups

**Fix:**
```bash
# Set proper backup permissions
sudo chmod 700 /var/backups/mysql
sudo chmod 600 /var/backups/mysql/*
sudo chown -R root:root /var/backups/mysql

# Update backup script with secure practices
sudo bash -c 'cat > /usr/local/bin/mysql-backup.sh << EOF
#!/bin/bash
# Secure MySQL Backup Script

BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d)

# Use credentials from secure file
mysqldump --defaults-file=/root/.my.cnf --all-databases > "$BACKUP_DIR/all_databases_$DATE.sql"

# Set secure permissions
chmod 600 "$BACKUP_DIR/all_databases_$DATE.sql"
EOF'
```

---

### V-DB-008: Weak Passwords

**Fix:**
```sql
-- Change application user passwords
ALTER USER 'webapp'@'%' IDENTIFIED BY 'W3b@pp$3cur3P@ss!';
ALTER USER 'hrapp'@'%' IDENTIFIED BY 'HR@pp$3cur3P@ss!';
ALTER USER 'backup'@'%' IDENTIFIED BY 'B@ckup$3cur3P@ss!';
ALTER USER 'admin'@'%' IDENTIFIED BY '@dm1n$3cur3P@ss!';

FLUSH PRIVILEGES;
```

---

### V-DB-009: Excessive Privileges

**Fix:**
```sql
-- Revoke ALL and grant minimum necessary privileges
REVOKE ALL PRIVILEGES ON *.* FROM 'webapp'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON inventory.* TO 'webapp'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON employees.* TO 'webapp'@'%';

REVOKE ALL PRIVILEGES ON *.* FROM 'hrapp'@'%';
GRANT SELECT, INSERT, UPDATE ON employees.* TO 'hrapp'@'%';

REVOKE ALL PRIVILEGES ON *.* FROM 'backup'@'%';
GRANT SELECT, LOCK TABLES ON *.* TO 'backup'@'%';

FLUSH PRIVILEGES;
```

---

### V-DB-010: Weak SSH Configuration

**Fix:**
Same as V-WEB-003 (see Linux Web Server section).

---

### V-DB-011: Credentials in Files

**Fix:**
```bash
# Secure .my.cnf
sudo chmod 600 /root/.my.cnf
sudo chown root:root /root/.my.cnf

# Remove credential files from /tmp
sudo rm -f /tmp/mysql_credentials.txt
sudo rm -f /tmp/*credential*

# Use MySQL config editor instead
mysql_config_editor set --login-path=local --host=localhost --user=root --password
```

---

### V-DB-012: Sensitive Data

**Fix:**
```sql
-- Drop or encrypt sensitive tables
DROP TABLE IF EXISTS secrets.credentials;
DROP TABLE IF EXISTS secrets.api_keys;

-- Or implement encryption at rest
-- Use MySQL Enterprise encryption or application-level encryption
```

---

## Workstation Remediation

### V-WS-001: Windows Firewall Disabled

**Fix:** Same as V-WIN-001

---

### V-WS-002: Windows Defender Disabled

**Fix:** Same as V-WIN-002

---

### V-WS-003: Audit Policies Disabled

**Fix:** Same as V-WIN-003

---

### V-WS-004: UAC Disabled

**Fix:**
```powershell
# Enable UAC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 1

# Restart required
```

---

### V-WS-005: SMBv1 Enabled

**Fix:** Same as V-WIN-011

---

### V-WS-006: Weak Local Accounts

**Fix:**
```powershell
# Remove suspicious accounts
Remove-LocalUser -Name "backdoor" -Confirm:$false
Remove-LocalUser -Name "support" -Confirm:$false

# Or disable and audit
Disable-LocalUser -Name "backdoor"
Get-LocalGroupMember -Group "Administrators"
```

---

### V-WS-007: AutoRun Enabled

**Fix:**
```powershell
# Disable AutoRun
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord

# Disable AutoPlay
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Value 1 -Type DWord
```

---

### V-WS-008: Weak RDP Settings

**Fix:**
```powershell
# Enable NLA for RDP
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1

# Set proper encryption level
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MinEncryptionLevel" -Value 3

# Require Network Level Authentication via Group Policy
# Computer Configuration > Administrative Templates > Windows Components > Remote Desktop Services > Remote Desktop Session Host > Security
# Require user authentication for remote connections by using Network Level Authentication: Enabled
```

---

### V-WS-010: PowerShell Logging Disabled

**Fix:** Same as V-WIN-004

---

### V-WS-012: Unnecessary Services

**Fix:**
```powershell
# Disable Remote Registry
Stop-Service RemoteRegistry
Set-Service RemoteRegistry -StartupType Disabled

# Disable Telnet Client
Disable-WindowsOptionalFeature -Online -FeatureName TelnetClient -NoRestart

# Disable other unnecessary services
$servicesToDisable = @(
    "RemoteRegistry",
    "TapiSrv",
    "Fax"
)

foreach ($service in $servicesToDisable) {
    Stop-Service -Name $service -ErrorAction SilentlyContinue
    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
}
```

---

### V-WS-013: Weak Screen Lock

**Fix:**
```powershell
# Enable screen saver with password
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaverIsSecure" -Value "1"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -Value "600"

# Set inactivity timeout
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "InactivityTimeoutSecs" -Value 600
```

---

### V-WS-014: Sensitive Files

**Fix:**
```powershell
# Remove sensitive files from desktop
Remove-Item "C:\Users\Public\Desktop\passwords.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Users\Public\Desktop\IT_Info.txt" -Force -ErrorAction SilentlyContinue

# Search for and remove other sensitive files
Get-ChildItem -Path "C:\Users" -Recurse -Include "*password*", "*credential*" | Remove-Item -Force
```

---

## Post-Remediation Checklist

After implementing fixes, verify:

1. **Windows Systems:**
   - [ ] Firewalls enabled on all profiles
   - [ ] Windows Defender active with current definitions
   - [ ] Audit policies configured
   - [ ] PowerShell logging enabled
   - [ ] Strong password policy (14+ characters)
   - [ ] Account lockout enabled (5 attempts)
   - [ ] SMB signing required
   - [ ] SMBv1 disabled
   - [ ] Weak accounts removed/secured

2. **Linux Systems:**
   - [ ] UFW enabled with minimal rules
   - [ ] SSH hardened (no root, key-only auth)
   - [ ] fail2ban installed and running
   - [ ] No world-writable files
   - [ ] No exposed backup/config files

3. **Web Application:**
   - [ ] Directory listing disabled
   - [ ] Server version hidden
   - [ ] SQL injection fixed
   - [ ] Command injection fixed
   - [ ] No sensitive files in webroot

4. **Database:**
   - [ ] No remote root access
   - [ ] No anonymous users
   - [ ] Strong passwords
   - [ ] Minimal privileges
   - [ ] Encrypted sensitive data

---

## Emergency Response Procedures

If you discover active exploitation:

1. **Isolate the system** from the network
2. **Document** everything observed
3. **Preserve logs** before they rotate
4. **Change all passwords** for affected systems
5. **Review** authentication logs
6. **Scan** for persistence mechanisms
7. **Report** to team lead

---

*Generated for CCDC Practice Range - Blue Team Industries*
