# Maintenance Guide

This guide covers ongoing maintenance tasks and procedures for your n8n deployment.

## Overview

Regular maintenance ensures:
- Optimal performance
- Security compliance
- System reliability
- Data integrity

## Daily Maintenance

### Automated Tasks
- **Backup verification**: Check backup completion
- **Log rotation**: Manage log file sizes
- **Health checks**: Monitor service status
- **Security updates**: Apply critical patches

### Manual Checks
```bash
# Check system resources
htop
df -h
free -h

# Verify service status
sudo systemctl status n8n postgresql redis-server nginx

# Check recent logs
sudo journalctl --since "1 hour ago" --priority=err
```

## Weekly Maintenance

### System Updates
```bash
# Update package lists
sudo apt update

# List available updates
apt list --upgradable

# Apply security updates
sudo apt upgrade -y

# Clean package cache
sudo apt autoremove -y
sudo apt autoclean
```

### Performance Review
```bash
# Check disk usage
sudo du -sh /var/log/* | sort -hr

# Analyze database performance
sudo -u postgres psql n8n -c "
SELECT schemaname,tablename,attname,n_distinct,correlation 
FROM pg_stats 
WHERE schemaname = 'public' 
ORDER BY n_distinct DESC;
"

# Review n8n workflow performance
sudo -u n8n pm2 monit
```

## Monthly Maintenance

### Database Maintenance
```bash
# Vacuum and analyze database
sudo -u postgres psql n8n -c "VACUUM ANALYZE;"

# Check database size
sudo -u postgres psql n8n -c "
SELECT pg_size_pretty(pg_database_size('n8n')) as database_size;
"

# Reindex if necessary
sudo -u postgres psql n8n -c "REINDEX DATABASE n8n;"
```

### SSL Certificate Management
```bash
# Check certificate expiration
sudo certbot certificates

# Test certificate renewal
sudo certbot renew --dry-run

# Force renewal if needed
sudo certbot renew --force-renewal
```

### Log Management
```bash
# Archive old logs
sudo find /var/log -name "*.log" -mtime +30 -exec gzip {} \;

# Clean up old archived logs
sudo find /var/log -name "*.gz" -mtime +90 -delete

# Check log rotation configuration
sudo logrotate -d /etc/logrotate.conf
```

## Quarterly Maintenance

### Security Audit
```bash
# Check for security updates
sudo apt list --upgradable | grep -i security

# Review user accounts
sudo cat /etc/passwd | grep -E "bash|sh"

# Check SSH configuration
sudo sshd -T | grep -E "PermitRootLogin|PasswordAuthentication"

# Review firewall rules
sudo ufw status verbose
```

### Performance Optimization
```bash
# Analyze slow queries
sudo -u postgres psql n8n -c "
SELECT query, mean_time, calls, total_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
"

# Check n8n performance metrics
curl -s http://localhost:5678/metrics | grep -E "n8n_|http_"

# Review system performance
sudo sar -u 1 10  # CPU usage
sudo sar -r 1 10  # Memory usage
sudo sar -d 1 10  # Disk I/O
```

## Service Management

### n8n Application
```bash
# Check n8n status
sudo -u n8n pm2 status

# Restart n8n
sudo -u n8n pm2 restart n8n

# View n8n logs
sudo -u n8n pm2 logs n8n

# Monitor n8n processes
sudo -u n8n pm2 monit

# Update n8n
sudo npm update -g n8n
sudo -u n8n pm2 restart n8n
```

### Database Management
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Connect to database
sudo -u postgres psql n8n

# Check active connections
sudo -u postgres psql n8n -c "
SELECT count(*) as active_connections 
FROM pg_stat_activity 
WHERE state = 'active';
"

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Redis Cache
```bash
# Check Redis status
sudo systemctl status redis-server

# Connect to Redis
redis-cli

# Check Redis memory usage
redis-cli info memory

# Clear Redis cache (if needed)
redis-cli flushall

# Restart Redis
sudo systemctl restart redis-server
```

### Web Server
```bash
# Check Nginx status
sudo systemctl status nginx

# Test Nginx configuration
sudo nginx -t

# Reload Nginx configuration
sudo systemctl reload nginx

# View Nginx access logs
sudo tail -f /var/log/nginx/access.log

# View Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

## Monitoring and Alerting

### Health Check Script
```bash
# Run health check
sudo /usr/local/bin/n8n-health-check.sh

# View health check logs
sudo tail -f /var/log/n8n/health-check.log
```

### Grafana Dashboard Review
- Check system metrics trends
- Review alert configurations
- Update dashboard queries
- Verify notification channels

### Prometheus Maintenance
```bash
# Check Prometheus status
sudo systemctl status prometheus

# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'

# Clean up old metrics (if needed)
sudo systemctl stop prometheus
sudo rm -rf /var/lib/prometheus/data/
sudo systemctl start prometheus
```

## Backup Verification

### Test Restore Procedures
```bash
# Test database restore
sudo -u postgres createdb n8n_test
sudo -u postgres psql n8n_test < /opt/backups/latest_db_backup.sql
sudo -u postgres dropdb n8n_test
```

### Backup Storage Management
```bash
# Check local backup space
du -sh /opt/backups/

# Clean old backups (keep last 30 days)
find /opt/backups/ -name "*.tar.gz" -mtime +30 -delete

# Verify S3 backups (if configured)
aws s3 ls s3://your-backup-bucket/n8n-backups/ --recursive
```

## Security Maintenance

### Update Security Configurations
```bash
# Update fail2ban rules
sudo fail2ban-client status
sudo fail2ban-client reload

# Check for intrusion attempts
sudo grep "Failed password" /var/log/auth.log | tail -10

# Update firewall rules if needed
sudo ufw status numbered
```

### Certificate Management
```bash
# Check SSL certificate status
openssl x509 -in /etc/letsencrypt/live/yourdomain.com/cert.pem -text -noout

# Update certificate if needed
sudo certbot renew
sudo systemctl reload nginx
```

## Troubleshooting Common Issues

### High CPU Usage
```bash
# Identify CPU-intensive processes
top -o %CPU

# Check n8n workflow performance
sudo -u n8n pm2 monit

# Analyze database queries
sudo -u postgres psql n8n -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

### Memory Issues
```bash
# Check memory usage
free -h
sudo ps aux --sort=-%mem | head -10

# Check for memory leaks
sudo valgrind --tool=memcheck --leak-check=full pm2 start ecosystem.config.js
```

### Disk Space Issues
```bash
# Find large files
sudo find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# Clean up logs
sudo journalctl --vacuum-time=7d

# Clean package cache
sudo apt clean
```

## Maintenance Schedule

### Daily (Automated)
- [ ] Backup verification
- [ ] Health checks
- [ ] Log rotation
- [ ] Security monitoring

### Weekly (Manual)
- [ ] System updates
- [ ] Performance review
- [ ] Log analysis
- [ ] Service status check

### Monthly (Scheduled)
- [ ] Database maintenance
- [ ] SSL certificate check
- [ ] Security audit
- [ ] Backup testing

### Quarterly (Planned)
- [ ] Performance optimization
- [ ] Security review
- [ ] Documentation updates
- [ ] Disaster recovery testing

For troubleshooting specific issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
