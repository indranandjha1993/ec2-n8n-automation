# Backup & Recovery

This guide covers backup strategies and recovery procedures for your n8n deployment.

## Overview

The deployment includes automated backup solutions for:

- **PostgreSQL Database**: Complete database dumps
- **n8n Configuration**: Workflows and settings
- **System Configuration**: Nginx, SSL certificates
- **Application Logs**: Historical log data

## Automated Backups

### Backup Schedule
- **Daily backups**: Run at 2:00 AM local time
- **Retention**: 7 daily, 4 weekly, 12 monthly backups
- **Location**: `/opt/backups/` (local) and optional S3 storage

### Backup Components

#### Database Backup
```bash
# Manual database backup
sudo -u postgres pg_dump n8n > n8n_backup_$(date +%Y%m%d_%H%M%S).sql

# Restore database
sudo -u postgres psql n8n < n8n_backup_20231201_020000.sql
```

#### n8n Data Backup
```bash
# Backup n8n user data
sudo tar -czf n8n_userdata_$(date +%Y%m%d_%H%M%S).tar.gz /home/n8n/.n8n/

# Restore n8n data
sudo tar -xzf n8n_userdata_20231201_020000.tar.gz -C /
```

#### System Configuration Backup
```bash
# Backup system configurations
sudo tar -czf system_config_$(date +%Y%m%d_%H%M%S).tar.gz \
  /etc/nginx/ \
  /etc/ssl/ \
  /etc/systemd/system/ \
  /etc/cron.d/
```

## Manual Backup Operations

### Run Manual Backup
```bash
# Execute backup script
sudo /usr/local/bin/n8n-backup.sh

# Check backup status
sudo tail -f /var/log/backup.log
```

### List Available Backups
```bash
# List local backups
ls -la /opt/backups/

# List S3 backups (if configured)
aws s3 ls s3://your-backup-bucket/n8n-backups/
```

## S3 Integration

### Configure S3 Backup
1. **Install AWS CLI**:
   ```bash
   sudo apt install awscli
   aws configure
   ```

2. **Update backup script**:
   ```bash
   sudo nano /usr/local/bin/n8n-backup.sh
   # Set S3_BUCKET variable
   S3_BUCKET="your-backup-bucket"
   ```

3. **Test S3 upload**:
   ```bash
   aws s3 cp /opt/backups/test.txt s3://your-backup-bucket/
   ```

### S3 Backup Structure
```
s3://your-backup-bucket/
├── n8n-backups/
│   ├── daily/
│   ├── weekly/
│   └── monthly/
└── logs/
```

## Recovery Procedures

### Complete System Recovery

#### 1. Prepare New Instance
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install postgresql redis-server nginx nodejs npm
```

#### 2. Restore Database
```bash
# Create database and user
sudo -u postgres createdb n8n
sudo -u postgres createuser n8n

# Restore from backup
sudo -u postgres psql n8n < /path/to/database_backup.sql
```

#### 3. Restore n8n Data
```bash
# Create n8n user
sudo useradd -m -s /bin/bash n8n

# Restore n8n configuration
sudo tar -xzf n8n_userdata_backup.tar.gz -C /

# Set proper permissions
sudo chown -R n8n:n8n /home/n8n/
```

#### 4. Restore System Configuration
```bash
# Restore configurations
sudo tar -xzf system_config_backup.tar.gz -C /

# Restart services
sudo systemctl restart nginx postgresql redis-server
```

### Partial Recovery

#### Database Only
```bash
# Stop n8n
sudo systemctl stop n8n

# Restore database
sudo -u postgres psql n8n < database_backup.sql

# Start n8n
sudo systemctl start n8n
```

#### Workflows Only
```bash
# Stop n8n
sudo systemctl stop n8n

# Restore workflows
sudo tar -xzf n8n_userdata_backup.tar.gz -C / --wildcards "*/workflows.json"

# Start n8n
sudo systemctl start n8n
```

## Backup Verification

### Test Backup Integrity
```bash
# Test database backup
sudo -u postgres pg_restore --list database_backup.sql

# Test archive integrity
tar -tzf n8n_userdata_backup.tar.gz > /dev/null && echo "Archive OK"
```

### Automated Verification
The backup script includes verification steps:
- Database dump validation
- Archive integrity checks
- File size validation
- Checksum verification

## Monitoring Backups

### Backup Logs
```bash
# View backup logs
sudo tail -f /var/log/backup.log

# Check backup cron job
sudo crontab -l | grep backup
```

### Backup Alerts
Configure monitoring for:
- Backup job failures
- Storage space issues
- S3 upload failures
- Backup age warnings

## Best Practices

### Security
- Encrypt backups before uploading to cloud storage
- Use IAM roles for S3 access (avoid hardcoded credentials)
- Regularly rotate backup encryption keys
- Limit access to backup files

### Performance
- Schedule backups during low-usage periods
- Use incremental backups for large datasets
- Compress backups to save storage space
- Monitor backup duration and optimize as needed

### Testing
- Regularly test restore procedures
- Maintain documented recovery runbooks
- Practice disaster recovery scenarios
- Validate backup completeness

## Troubleshooting

### Common Issues

#### Backup Script Fails
```bash
# Check script permissions
ls -la /usr/local/bin/n8n-backup.sh

# Check disk space
df -h /opt/backups/

# Check database connectivity
sudo -u postgres psql -c "SELECT version();"
```

#### S3 Upload Issues
```bash
# Test AWS credentials
aws sts get-caller-identity

# Check S3 bucket permissions
aws s3 ls s3://your-backup-bucket/

# Test network connectivity
curl -I https://s3.amazonaws.com
```

#### Recovery Issues
```bash
# Check file permissions
ls -la /home/n8n/.n8n/

# Verify database connection
sudo -u n8n psql -h localhost -d n8n -c "SELECT 1;"

# Check service status
sudo systemctl status n8n postgresql redis-server nginx
```

For more information, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
