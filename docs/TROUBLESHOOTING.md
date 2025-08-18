# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with your n8n deployment.

## 📋 Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [Service-Specific Issues](#service-specific-issues)
- [Performance Issues](#performance-issues)
- [SSL/Certificate Issues](#sslcertificate-issues)
- [Network Issues](#network-issues)
- [Log Analysis](#log-analysis)
- [Recovery Procedures](#recovery-procedures)

## Quick Diagnostics

### Health Check Script

Run the automated health check to get an overview of system status:

```bash
# Run comprehensive health check
sudo /usr/local/bin/n8n-health-check.sh

# View health check logs
sudo tail -f /var/log/n8n/health-check.log
```

### Service Status Check

```bash
# Check all services at once
sudo systemctl status postgresql redis-server nginx prometheus grafana-server

# Check individual services
sudo systemctl status postgresql
sudo systemctl status redis-server
sudo systemctl status nginx
sudo systemctl status prometheus
sudo systemctl status grafana-server

# Check n8n (managed by PM2)
sudo -u n8n pm2 status
sudo -u n8n pm2 logs n8n
```

### Resource Usage Check

```bash
# System resources
htop
free -h
df -h

# Process monitoring
sudo -u n8n pm2 monit

# Network connections
sudo netstat -tlnp
```

## Common Issues

### 🔴 n8n Won't Start

**Symptoms:**
- n8n service shows as stopped in PM2
- Cannot access n8n web interface
- PM2 shows restart loops

**Diagnosis:**
```bash
# Check PM2 status
sudo -u n8n pm2 status

# Check n8n logs
sudo -u n8n pm2 logs n8n

# Check system logs
sudo journalctl -u nginx -f
```

**Common Causes & Solutions:**

1. **Database Connection Issues:**
   ```bash
   # Test database connection
   sudo -u postgres psql -d n8n -c "SELECT 1;"
   
   # If connection fails, check PostgreSQL
   sudo systemctl status postgresql
   sudo systemctl restart postgresql
   ```

2. **Redis Connection Issues:**
   ```bash
   # Test Redis connection
   redis-cli ping
   
   # If connection fails, check Redis
   sudo systemctl status redis-server
   sudo systemctl restart redis-server
   ```

3. **Port Already in Use:**
   ```bash
   # Check what's using port 5678
   sudo lsof -i :5678
   
   # Kill conflicting process if needed
   sudo kill -9 <PID>
   ```

4. **Permission Issues:**
   ```bash
   # Fix n8n directory permissions
   sudo chown -R n8n:n8n /opt/n8n
   sudo chown -R n8n:n8n /var/log/n8n
   ```

5. **Configuration Issues:**
   ```bash
   # Validate n8n configuration
   sudo -u n8n n8n --help
   
   # Check configuration file
   sudo -u n8n cat /opt/n8n/.n8n/config.json
   ```

**Resolution Steps:**
```bash
# 1. Stop n8n
sudo -u n8n pm2 stop n8n

# 2. Fix the underlying issue (database, redis, permissions, etc.)

# 3. Restart n8n
sudo -u n8n pm2 start n8n

# 4. Check status
sudo -u n8n pm2 status
```

### 🔴 Cannot Access Web Interface

**Symptoms:**
- Browser shows "connection refused" or timeout
- Services appear to be running

**Diagnosis:**
```bash
# Check if n8n is listening on the correct port
sudo netstat -tlnp | grep 5678

# Check nginx status and configuration
sudo nginx -t
sudo systemctl status nginx

# Check firewall rules
sudo ufw status verbose
```

**Solutions:**

1. **Firewall Issues:**
   ```bash
   # Check current rules
   sudo ufw status verbose
   
   # Allow required ports
   sudo ufw allow 5678  # For IP-based deployment
   sudo ufw allow 80    # For HTTP
   sudo ufw allow 443   # For HTTPS
   ```

2. **Nginx Configuration Issues:**
   ```bash
   # Test nginx configuration
   sudo nginx -t
   
   # Reload nginx if configuration is valid
   sudo systemctl reload nginx
   
   # Restart nginx if needed
   sudo systemctl restart nginx
   ```

3. **Service Not Listening:**
   ```bash
   # Check if n8n is actually running
   sudo -u n8n pm2 status
   
   # Restart n8n if needed
   sudo -u n8n pm2 restart n8n
   ```

### 🔴 SSL Certificate Issues

**Symptoms:**
- Browser shows SSL warnings
- Certificate expired errors
- HTTPS not working

**Diagnosis:**
```bash
# Check certificate status
sudo certbot certificates

# Check certificate expiry
sudo openssl x509 -enddate -noout -in /etc/letsencrypt/live/n8n.yourdomain.com/fullchain.pem

# Test nginx SSL configuration
sudo nginx -t
```

**Solutions:**

1. **Certificate Not Found:**
   ```bash
   # Re-obtain certificates
   sudo certbot certonly --webroot --webroot-path=/var/www/certbot \
     --email admin@yourdomain.com --agree-tos --no-eff-email \
     -d n8n.yourdomain.com -d grafana.yourdomain.com \
     -d prometheus.yourdomain.com -d pgadmin.yourdomain.com
   ```

2. **Certificate Expired:**
   ```bash
   # Renew certificates
   sudo certbot renew --force-renewal
   
   # Restart nginx
   sudo systemctl restart nginx
   ```

3. **DNS Issues:**
   ```bash
   # Check DNS resolution
   nslookup n8n.yourdomain.com
   
   # Verify A records point to your server IP
   dig A n8n.yourdomain.com
   ```

### 🔴 Database Connection Errors

**Symptoms:**
- n8n shows database connection errors
- PostgreSQL connection refused

**Diagnosis:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test connection as postgres user
sudo -u postgres psql -c "SELECT version();"

# Test connection as n8n user
sudo -u postgres psql -d n8n -U n8n -h localhost
```

**Solutions:**

1. **PostgreSQL Not Running:**
   ```bash
   # Start PostgreSQL
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

2. **Authentication Issues:**
   ```bash
   # Check pg_hba.conf
   sudo cat /etc/postgresql/14/main/pg_hba.conf
   
   # Reset n8n user password
   sudo -u postgres psql -c "ALTER USER n8n PASSWORD 'new_password';"
   ```

3. **Connection Limit Reached:**
   ```bash
   # Check current connections
   sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
   
   # Check max connections
   sudo -u postgres psql -c "SHOW max_connections;"
   
   # Kill idle connections if needed
   sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle';"
   ```

## Service-Specific Issues

### PostgreSQL Issues

**Common Problems:**

1. **Database Won't Start:**
   ```bash
   # Check PostgreSQL logs
   sudo tail -f /var/log/postgresql/postgresql-14-main.log
   
   # Check disk space
   df -h /var/lib/postgresql/
   
   # Check configuration
   sudo -u postgres postgres --version
   ```

2. **Performance Issues:**
   ```bash
   # Check slow queries
   sudo -u postgres psql -d n8n -c "SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
   
   # Check database size
   sudo -u postgres psql -d n8n -c "SELECT pg_size_pretty(pg_database_size('n8n'));"
   
   # Vacuum database
   sudo -u postgres psql -d n8n -c "VACUUM ANALYZE;"
   ```

### Redis Issues

**Common Problems:**

1. **Redis Memory Issues:**
   ```bash
   # Check Redis memory usage
   redis-cli info memory
   
   # Check Redis configuration
   redis-cli config get maxmemory
   
   # Clear Redis cache if needed (WARNING: This will clear all data)
   redis-cli flushall
   ```

2. **Redis Connection Issues:**
   ```bash
   # Test Redis connection
   redis-cli ping
   
   # Check Redis logs
   sudo tail -f /var/log/redis/redis-server.log
   
   # Restart Redis
   sudo systemctl restart redis-server
   ```

### Nginx Issues

**Common Problems:**

1. **Configuration Errors:**
   ```bash
   # Test configuration
   sudo nginx -t
   
   # Check configuration files
   sudo nginx -T
   
   # Check error logs
   sudo tail -f /var/log/nginx/error.log
   ```

2. **SSL Configuration Issues:**
   ```bash
   # Test SSL configuration
   sudo nginx -t
   
   # Check SSL certificate paths
   sudo ls -la /etc/letsencrypt/live/yourdomain.com/
   
   # Test SSL connection
   openssl s_client -connect yourdomain.com:443
   ```

## Performance Issues

### High CPU Usage

**Diagnosis:**
```bash
# Check top processes
htop

# Check n8n processes
sudo -u n8n pm2 monit

# Check system load
uptime
```

**Solutions:**
```bash
# Scale n8n instances
sudo -u n8n pm2 scale n8n 2

# Optimize PostgreSQL
sudo -u postgres psql -d n8n -c "VACUUM ANALYZE;"

# Check for runaway workflows
sudo -u n8n pm2 logs n8n | grep -i error
```

### High Memory Usage

**Diagnosis:**
```bash
# Check memory usage
free -h

# Check process memory usage
ps aux --sort=-%mem | head

# Check n8n memory usage
sudo -u n8n pm2 show n8n
```

**Solutions:**
```bash
# Restart n8n to clear memory leaks
sudo -u n8n pm2 restart n8n

# Adjust PM2 memory limits
sudo -u n8n pm2 start ecosystem.config.js --max-memory-restart 1G

# Optimize Redis memory
redis-cli config set maxmemory 256mb
```

### Disk Space Issues

**Diagnosis:**
```bash
# Check disk usage
df -h

# Find large files
sudo find / -type f -size +100M -exec ls -lh {} \;

# Check log file sizes
sudo du -sh /var/log/*
```

**Solutions:**
```bash
# Clean up old logs
sudo logrotate -f /etc/logrotate.conf

# Clean up old backups
sudo find /opt/backups -name "*.tar.gz" -mtime +30 -delete

# Clean up package cache
sudo apt autoremove
sudo apt autoclean
```

## Log Analysis

### Important Log Locations

```bash
# n8n logs
sudo tail -f /var/log/n8n/n8n.log
sudo -u n8n pm2 logs n8n

# System logs
sudo journalctl -f
sudo journalctl -u postgresql -f
sudo journalctl -u redis-server -f
sudo journalctl -u nginx -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# Redis logs
sudo tail -f /var/log/redis/redis-server.log
```

### Log Analysis Commands

```bash
# Search for errors in n8n logs
sudo grep -i error /var/log/n8n/n8n.log

# Check for failed login attempts
sudo grep "Failed password" /var/log/auth.log

# Check nginx error patterns
sudo grep -E "(error|warn)" /var/log/nginx/error.log

# Check database connection errors
sudo grep -i "connection" /var/log/postgresql/postgresql-14-main.log
```

## Recovery Procedures

### Complete System Recovery

If the system is completely broken:

```bash
# 1. Stop all services
sudo systemctl stop nginx postgresql redis-server prometheus grafana-server
sudo -u n8n pm2 stop all

# 2. Check system resources
df -h
free -h

# 3. Restart services one by one
sudo systemctl start postgresql
sudo systemctl start redis-server
sudo -u n8n pm2 start n8n
sudo systemctl start nginx
sudo systemctl start prometheus
sudo systemctl start grafana-server

# 4. Verify each service
sudo systemctl status postgresql redis-server nginx prometheus grafana-server
sudo -u n8n pm2 status
```

### Database Recovery

If PostgreSQL is corrupted:

```bash
# 1. Stop n8n
sudo -u n8n pm2 stop n8n

# 2. Stop PostgreSQL
sudo systemctl stop postgresql

# 3. Restore from backup
sudo tar -xzf /opt/backups/latest_backup.tar.gz -C /tmp/
sudo -u postgres psql -d n8n < /tmp/postgresql_backup.sql

# 4. Start services
sudo systemctl start postgresql
sudo -u n8n pm2 start n8n
```

### Configuration Recovery

If configuration files are corrupted:

```bash
# 1. Restore from backup
sudo tar -xzf /opt/backups/latest_backup.tar.gz -C /tmp/
sudo tar -xzf /tmp/system_configs.tar.gz -C /

# 2. Fix permissions
sudo chown -R postgres:postgres /etc/postgresql/
sudo chown -R redis:redis /etc/redis/
sudo chown root:root /etc/nginx/

# 3. Restart services
sudo systemctl restart postgresql redis-server nginx
```

## Getting Help

### Before Asking for Help

1. **Run the health check script**:
   ```bash
   sudo /usr/local/bin/n8n-health-check.sh
   ```

2. **Collect relevant logs**:
   ```bash
   # Create a log bundle
   sudo mkdir -p /tmp/n8n-logs
   sudo cp /var/log/n8n/* /tmp/n8n-logs/
   sudo journalctl -u postgresql --since "1 hour ago" > /tmp/n8n-logs/postgresql.log
   sudo journalctl -u nginx --since "1 hour ago" > /tmp/n8n-logs/nginx.log
   sudo tar -czf /tmp/n8n-debug-logs.tar.gz /tmp/n8n-logs/
   ```

3. **Document the issue**:
   - What were you trying to do?
   - What happened instead?
   - What error messages did you see?
   - When did the issue start?

### Creating a Support Request

When creating an issue, include:

1. **System Information**:
   ```bash
   # System info
   uname -a
   lsb_release -a
   
   # Service versions
   ansible --version
   n8n --version
   sudo -u postgres psql --version
   redis-server --version
   nginx -v
   ```

2. **Configuration Details**:
   - Deployment type (IP or domain)
   - Any custom configuration changes
   - Recent changes made to the system

3. **Error Logs**:
   - Relevant log excerpts
   - Error messages
   - Stack traces

### Emergency Contacts

For critical production issues:

1. **Check the documentation**: [📚 Documentation Index](../README.md#-documentation)
2. **Search existing issues**: [GitHub Issues](https://github.com/your-repo/issues)
3. **Create a new issue**: [New Issue Template](../.github/ISSUE_TEMPLATE.md)

## Prevention

### Regular Maintenance

```bash
# Weekly maintenance script
#!/bin/bash

# Update system packages
sudo apt update && sudo apt upgrade -y

# Clean up logs
sudo logrotate -f /etc/logrotate.conf

# Vacuum database
sudo -u postgres psql -d n8n -c "VACUUM ANALYZE;"

# Check disk space
df -h

# Run health check
sudo /usr/local/bin/n8n-health-check.sh
```

### Monitoring Setup

Set up proper monitoring to catch issues early:

1. **Configure Grafana alerts** - See [📊 Monitoring Guide](MONITORING.md)
2. **Set up log monitoring** - Monitor error patterns
3. **Resource monitoring** - CPU, memory, disk usage alerts
4. **Service monitoring** - Uptime monitoring for all services

### Backup Verification

Regularly test your backups:

```bash
# Test backup restoration in a test environment
sudo /usr/local/bin/n8n-backup.sh
# Then restore in test environment to verify
```

## Related Documentation

- [🚀 Deployment Guide](DEPLOYMENT_GUIDE.md) - Initial deployment instructions
- [⚙️ Configuration Guide](CONFIGURATION.md) - Configuration options
- [🔒 Security Guide](SECURITY.md) - Security best practices
- [📊 Monitoring Guide](MONITORING.md) - Monitoring and alerting
- [🛠️ Maintenance Guide](MAINTENANCE.md) - Regular maintenance procedures
