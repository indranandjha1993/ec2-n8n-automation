# Security Guide

This guide covers security best practices and configurations for your n8n deployment.

## 📋 Table of Contents

- [Security Overview](#security-overview)
- [Network Security](#network-security)
- [Application Security](#application-security)
- [Database Security](#database-security)
- [SSL/TLS Configuration](#ssltls-configuration)
- [Access Control](#access-control)
- [Monitoring & Logging](#monitoring--logging)
- [Security Maintenance](#security-maintenance)
- [Incident Response](#incident-response)

## Security Overview

### Security Architecture

```
Internet
    │
    ▼
┌─────────────┐
│     UFW     │  ← Firewall (ports 22, 80, 443, service ports)
│  Firewall   │
└─────────────┘
    │
    ▼
┌─────────────┐
│  Fail2ban   │  ← Intrusion Prevention
│             │
└─────────────┘
    │
    ▼
┌─────────────┐
│    Nginx    │  ← SSL termination, security headers
│   (Proxy)   │
└─────────────┘
    │
    ▼
┌─────────────┐
│ Application │  ← Services bound to localhost
│  Services   │
└─────────────┘
```

### Security Layers

1. **Network Level**: UFW firewall, fail2ban, security groups
2. **Transport Level**: SSL/TLS encryption, strong ciphers
3. **Application Level**: Authentication, authorization, input validation
4. **System Level**: User isolation, file permissions, regular updates

## Network Security

### Firewall Configuration (UFW)

The deployment automatically configures UFW with minimal required ports:

```bash
# View current firewall status
sudo ufw status verbose

# Default configuration includes:
# - SSH (port 22) - restricted to your IP
# - HTTP (port 80) - for Let's Encrypt challenges
# - HTTPS (port 443) - for secure access
# - Service ports (5678, 3000, 9090, 8080) - for IP-based deployment
```

**Customizing Firewall Rules:**

```bash
# Allow specific IP for SSH
sudo ufw delete allow 22
sudo ufw allow from YOUR_IP to any port 22

# Allow specific network for service access
sudo ufw allow from 10.0.0.0/8 to any port 5678

# Block specific IP
sudo ufw deny from MALICIOUS_IP
```

**Configuration in Ansible:**

Edit `inventory/group_vars/all.yml`:

```yaml
security:
  ufw_enabled: true
  ssh_port: 22
  allowed_ssh_users:
    - ubuntu
    - your-admin-user
```

### Intrusion Prevention (Fail2ban)

Fail2ban monitors logs and bans IPs with suspicious activity:

```bash
# Check fail2ban status
sudo fail2ban-client status

# View banned IPs
sudo fail2ban-client status sshd
sudo fail2ban-client status nginx-http-auth

# Unban an IP
sudo fail2ban-client set sshd unbanip 1.2.3.4

# View fail2ban logs
sudo tail -f /var/log/fail2ban.log
```

**Configuration:**

```yaml
security:
  fail2ban_enabled: true
  max_login_attempts: 5
  ban_time: 3600  # 1 hour
```

**Custom Fail2ban Rules:**

Edit `/etc/fail2ban/jail.local`:

```ini
[n8n-auth]
enabled = true
port = 5678
filter = n8n-auth
logpath = /var/log/n8n/n8n.log
maxretry = 5
bantime = 3600
```

### AWS Security Groups

For additional network security, configure AWS Security Groups:

```bash
# Example security group rules
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 22 \
  --source-group YOUR_IP/32

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

## Application Security

### n8n Security Configuration

**Basic Authentication:**

```yaml
n8n:
  basic_auth:
    enabled: true
    user: "admin"
    password: ""  # Auto-generated secure password
```

**Advanced Security Settings:**

```json
{
  "security": {
    "basicAuth": {
      "active": true,
      "user": "admin",
      "password": "secure-password"
    },
    "jwtAuth": {
      "active": true,
      "jwtHeader": "authorization",
      "jwtHeaderValuePrefix": "Bearer"
    }
  },
  "endpoints": {
    "payloadSizeMax": 16,
    "rest": "rest",
    "webhook": "webhook"
  }
}
```

**Webhook Security:**

```bash
# Configure webhook authentication
# In n8n workflow, use authentication headers
# Example: Authorization: Bearer your-secret-token
```

### Input Validation & Sanitization

**Best Practices:**

1. **Validate all inputs** in n8n workflows
2. **Sanitize data** before database operations
3. **Use parameterized queries** for database interactions
4. **Validate webhook payloads** before processing

**Example Workflow Security:**

```javascript
// In n8n Function node
const input = $input.all();

// Validate input
if (!input || !Array.isArray(input)) {
  throw new Error('Invalid input format');
}

// Sanitize data
const sanitizedData = input.map(item => ({
  id: parseInt(item.json.id) || 0,
  name: String(item.json.name || '').substring(0, 100),
  email: String(item.json.email || '').toLowerCase()
}));

return sanitizedData;
```

## Database Security

### PostgreSQL Security

**Authentication Configuration:**

The deployment uses SCRAM-SHA-256 authentication:

```bash
# Check authentication method
sudo -u postgres psql -c "SHOW password_encryption;"

# View connection settings
sudo cat /etc/postgresql/14/main/pg_hba.conf
```

**Configuration:**

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             n8n                                     scram-sha-256
host    all             n8n             127.0.0.1/32            scram-sha-256
host    all             all             all                     reject
```

**Security Best Practices:**

1. **Strong Passwords:**
   ```bash
   # Generate secure password
   openssl rand -base64 32
   
   # Update n8n user password
   sudo -u postgres psql -c "ALTER USER n8n PASSWORD 'new-secure-password';"
   ```

2. **Connection Limits:**
   ```sql
   -- Limit connections per user
   ALTER USER n8n CONNECTION LIMIT 50;
   ```

3. **Database Permissions:**
   ```sql
   -- Grant minimal required permissions
   GRANT CONNECT ON DATABASE n8n TO n8n;
   GRANT USAGE ON SCHEMA public TO n8n;
   GRANT CREATE ON SCHEMA public TO n8n;
   ```

### Redis Security

**Authentication:**

```bash
# Test Redis authentication
redis-cli -a your-redis-password ping

# Check Redis configuration
redis-cli config get requirepass
```

**Security Configuration:**

```
# /etc/redis/redis.conf
bind 127.0.0.1
protected-mode yes
requirepass your-secure-password
```

**Best Practices:**

1. **Strong Password:** Use a long, random password
2. **Disable Dangerous Commands:**
   ```
   rename-command FLUSHDB ""
   rename-command FLUSHALL ""
   rename-command DEBUG ""
   ```

## SSL/TLS Configuration

### Let's Encrypt Certificates

**Automatic Certificate Management:**

```bash
# Check certificate status
sudo certbot certificates

# Manual renewal (automatic via cron)
sudo certbot renew

# Test renewal process
sudo certbot renew --dry-run
```

**Certificate Configuration:**

```yaml
ssl:
  enabled: true  # For domain-based deployment
  email: "admin@yourdomain.com"
  staging: false  # Set to true for testing
```

### Nginx SSL Configuration

**Strong SSL Configuration:**

```nginx
# SSL protocols and ciphers
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;

# SSL session settings
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

# OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;
```

**Security Headers:**

```nginx
# Security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### SSL Testing

```bash
# Test SSL configuration
openssl s_client -connect yourdomain.com:443

# Check SSL rating
curl -s "https://api.ssllabs.com/api/v3/analyze?host=yourdomain.com"

# Test with online tools:
# - SSL Labs: https://www.ssllabs.com/ssltest/
# - Mozilla Observatory: https://observatory.mozilla.org/
```

## Access Control

### User Management

**System Users:**

```bash
# n8n service user (no login shell)
sudo usermod -s /bin/false n8n

# Admin users with sudo access
sudo adduser admin-user
sudo usermod -aG sudo admin-user

# SSH key-based authentication only
sudo passwd -l admin-user  # Lock password
```

**SSH Security:**

```bash
# Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart sshd
```

### Application Access Control

**n8n User Management:**

1. **Enable User Management** in n8n settings
2. **Create Individual Users** instead of shared accounts
3. **Use Role-Based Access** for different user types
4. **Regular Access Reviews** to remove unused accounts

**API Security:**

```bash
# Generate API keys for programmatic access
# Use environment variables for API keys
export N8N_API_KEY="your-secure-api-key"

# Rotate API keys regularly
```

### Network Access Control

**VPN Access (Recommended for Production):**

```bash
# Install OpenVPN or WireGuard
sudo apt install openvpn

# Configure VPN access for admin users
# Restrict direct internet access to admin interfaces
```

**Bastion Host Setup:**

```bash
# Use a bastion host for SSH access
# Configure jump host in SSH config
Host n8n-server
    HostName 10.0.1.100
    User ubuntu
    ProxyJump bastion-host
```

## Monitoring & Logging

### Security Monitoring

**Log Monitoring:**

```bash
# Monitor authentication logs
sudo tail -f /var/log/auth.log

# Monitor nginx access logs
sudo tail -f /var/log/nginx/access.log

# Monitor fail2ban logs
sudo tail -f /var/log/fail2ban.log

# Monitor n8n logs for security events
sudo tail -f /var/log/n8n/n8n.log | grep -i "auth\|error\|fail"
```

**Automated Monitoring:**

```bash
# Set up log monitoring alerts
# Example: Alert on multiple failed login attempts
grep "Failed password" /var/log/auth.log | tail -10
```

### Security Metrics

**Grafana Security Dashboard:**

Monitor these metrics:
- Failed login attempts
- Unusual network traffic
- High resource usage
- Certificate expiry dates
- Service availability

**Prometheus Alerts:**

```yaml
# Example security alerts
groups:
  - name: security
    rules:
      - alert: HighFailedLogins
        expr: increase(failed_logins_total[5m]) > 10
        for: 0m
        labels:
          severity: warning
        annotations:
          summary: "High number of failed login attempts"
```

## Security Maintenance

### Regular Security Tasks

**Weekly Tasks:**

```bash
#!/bin/bash
# Weekly security maintenance script

# Update system packages
sudo apt update && sudo apt upgrade -y

# Check for security updates
sudo unattended-upgrades --dry-run

# Review fail2ban logs
sudo fail2ban-client status

# Check SSL certificate expiry
sudo certbot certificates

# Review user accounts
sudo cat /etc/passwd | grep -E "bash|sh"

# Check for unusual processes
ps aux | grep -v "\[" | sort -k3 -nr | head -10
```

**Monthly Tasks:**

```bash
#!/bin/bash
# Monthly security maintenance script

# Rotate logs
sudo logrotate -f /etc/logrotate.conf

# Review firewall rules
sudo ufw status verbose

# Check for rootkits
sudo rkhunter --check

# Review system logs for anomalies
sudo journalctl --since "30 days ago" | grep -i "error\|fail\|warn"

# Update security configurations
# Review and update passwords
# Review user access permissions
```

### Security Updates

**Automated Updates:**

```bash
# Configure automatic security updates
sudo apt install unattended-upgrades

# Configure update settings
sudo dpkg-reconfigure unattended-upgrades
```

**Manual Updates:**

```bash
# Check for updates
sudo apt update
sudo apt list --upgradable

# Install security updates only
sudo apt upgrade -s | grep -i security

# Update specific packages
sudo apt install package-name
```

### Backup Security

**Secure Backups:**

```bash
# Encrypt backups
gpg --symmetric --cipher-algo AES256 backup.tar.gz

# Secure backup storage
aws s3 cp backup.tar.gz.gpg s3://secure-bucket/ --sse AES256

# Test backup integrity
gpg --decrypt backup.tar.gz.gpg | tar -tzf -
```

## Incident Response

### Security Incident Checklist

**Immediate Response:**

1. **Isolate the system** if compromise is suspected
2. **Document everything** - screenshots, logs, commands
3. **Preserve evidence** - don't modify logs or files
4. **Notify stakeholders** according to incident response plan

**Investigation Steps:**

```bash
# Check for unauthorized access
sudo last | head -20
sudo lastlog

# Check for unusual processes
ps aux | grep -v "\["

# Check network connections
sudo netstat -tulpn

# Check system integrity
sudo aide --check

# Review logs for timeline
sudo journalctl --since "1 day ago" | grep -E "auth|sudo|su"
```

### Recovery Procedures

**System Recovery:**

```bash
# 1. Stop all services
sudo systemctl stop nginx postgresql redis-server

# 2. Restore from clean backup
sudo tar -xzf /opt/backups/clean_backup.tar.gz -C /

# 3. Change all passwords
sudo -u postgres psql -c "ALTER USER n8n PASSWORD 'new-password';"

# 4. Update system
sudo apt update && sudo apt upgrade -y

# 5. Restart services
sudo systemctl start postgresql redis-server nginx
```

**Post-Incident Actions:**

1. **Root cause analysis** - determine how breach occurred
2. **Security improvements** - implement additional controls
3. **Documentation update** - update procedures and policies
4. **Team training** - share lessons learned

## Security Checklist

### Deployment Security Checklist

- [ ] **Firewall configured** with minimal required ports
- [ ] **Fail2ban enabled** and configured
- [ ] **SSL certificates** installed and auto-renewal configured
- [ ] **Strong passwords** generated for all services
- [ ] **Database authentication** configured (SCRAM-SHA-256)
- [ ] **Redis authentication** enabled
- [ ] **SSH hardened** (key-based auth, no root login)
- [ ] **Security headers** configured in Nginx
- [ ] **Log monitoring** set up
- [ ] **Backup encryption** configured
- [ ] **Security updates** automated
- [ ] **Access controls** implemented
- [ ] **Monitoring alerts** configured

### Ongoing Security Checklist

- [ ] **Weekly security updates** applied
- [ ] **Monthly access review** completed
- [ ] **Quarterly password rotation** performed
- [ ] **SSL certificates** monitored for expiry
- [ ] **Log analysis** performed regularly
- [ ] **Backup testing** completed monthly
- [ ] **Security training** up to date
- [ ] **Incident response plan** tested

## Related Documentation

- [⚙️ Configuration Guide](CONFIGURATION.md) - Security configuration options
- [📊 Monitoring Guide](MONITORING.md) - Security monitoring setup
- [🛠️ Maintenance Guide](MAINTENANCE.md) - Security maintenance procedures
- [🔧 Troubleshooting Guide](TROUBLESHOOTING.md) - Security issue resolution
