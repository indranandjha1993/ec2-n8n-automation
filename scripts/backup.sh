#!/bin/bash

# n8n Backup Script
# This script creates backups of n8n data, PostgreSQL database, and configurations

set -euo pipefail

# Configuration
BACKUP_DIR="/opt/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="n8n_backup_${TIMESTAMP}"
RETENTION_DAYS=30
S3_BUCKET=""  # Set this if you want to upload to S3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Create backup directory
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"
cd "${BACKUP_DIR}/${BACKUP_NAME}"

log "Starting n8n backup process..."

# Backup PostgreSQL database
log "Backing up PostgreSQL database..."
if sudo -u postgres pg_dump n8n > postgresql_backup.sql; then
    log "PostgreSQL backup completed"
else
    error "PostgreSQL backup failed"
    exit 1
fi

# Backup n8n user data
log "Backing up n8n user data..."
if sudo tar -czf n8n_userdata.tar.gz -C /opt/n8n .n8n/; then
    log "n8n user data backup completed"
else
    error "n8n user data backup failed"
    exit 1
fi

# Backup n8n logs
log "Backing up n8n logs..."
if sudo tar -czf n8n_logs.tar.gz -C /var/log n8n/; then
    log "n8n logs backup completed"
else
    warning "n8n logs backup failed (non-critical)"
fi

# Backup configurations
log "Backing up system configurations..."
sudo tar -czf system_configs.tar.gz \
    /etc/nginx/sites-available/ \
    /etc/postgresql/*/main/ \
    /etc/redis/ \
    /etc/prometheus/ \
    /etc/grafana/ \
    2>/dev/null || warning "Some configuration files could not be backed up"

# Create backup manifest
cat > backup_manifest.txt << EOF
Backup Name: ${BACKUP_NAME}
Backup Date: $(date)
Hostname: $(hostname)
n8n Version: $(n8n --version 2>/dev/null || echo "Unknown")
PostgreSQL Version: $(sudo -u postgres psql --version | head -1)
Files Included:
- postgresql_backup.sql (PostgreSQL database dump)
- n8n_userdata.tar.gz (n8n user data and workflows)
- n8n_logs.tar.gz (n8n application logs)
- system_configs.tar.gz (System configuration files)
EOF

# Create compressed archive of entire backup
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}/"
rm -rf "${BACKUP_NAME}/"

log "Backup archive created: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

# Upload to S3 if configured
if [[ -n "${S3_BUCKET}" ]]; then
    log "Uploading backup to S3..."
    if aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "s3://${S3_BUCKET}/n8n-backups/"; then
        log "Backup uploaded to S3 successfully"
    else
        error "Failed to upload backup to S3"
    fi
fi

# Clean up old backups
log "Cleaning up old backups (older than ${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -name "n8n_backup_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete

# Clean up old S3 backups if configured
if [[ -n "${S3_BUCKET}" ]]; then
    aws s3 ls "s3://${S3_BUCKET}/n8n-backups/" | while read -r line; do
        createDate=$(echo "$line" | awk '{print $1" "$2}')
        createDate=$(date -d "$createDate" +%s)
        olderThan=$(date -d "${RETENTION_DAYS} days ago" +%s)
        if [[ $createDate -lt $olderThan ]]; then
            fileName=$(echo "$line" | awk '{print $4}')
            if [[ $fileName != "" ]]; then
                aws s3 rm "s3://${S3_BUCKET}/n8n-backups/$fileName"
                log "Deleted old S3 backup: $fileName"
            fi
        fi
    done
fi

log "Backup process completed successfully!"
log "Backup location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
