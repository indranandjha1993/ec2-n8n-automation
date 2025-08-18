# Configuration Guide

This guide provides detailed information about configuring your n8n deployment.

## 📋 Table of Contents

- [Configuration Files](#configuration-files)
- [Basic Configuration](#basic-configuration)
- [Advanced Configuration](#advanced-configuration)
- [Environment-Specific Settings](#environment-specific-settings)
- [Security Configuration](#security-configuration)
- [Performance Tuning](#performance-tuning)
- [Examples](#examples)

## Configuration Files

### Main Configuration File

The primary configuration is stored in `inventory/group_vars/all.yml`. This file contains all the variables that control your deployment.

```bash
# Copy the example configuration
cp inventory/group_vars/all.yml.example inventory/group_vars/all.yml

# Edit the configuration
nano inventory/group_vars/all.yml
```

### Inventory Configuration

The inventory file `inventory/hosts.yml` defines your target hosts:

```yaml
---
all:
  children:
    n8n_servers:
      hosts:
        n8n-server:
          ansible_host: "your-ec2-ip"
          ansible_user: "ubuntu"
          ansible_ssh_private_key_file: "~/.ssh/your-key.pem"
```

## Basic Configuration

### Deployment Settings

```yaml
# Global configuration
project_name: n8n-deployment
deployment_type: "ip"  # Options: "ip" or "domain"
domain_name: ""        # Required for domain-based deployment
admin_email: "admin@example.com"
```

**Options:**
- `deployment_type`: 
  - `"ip"`: Services accessible via IP:port (development)
  - `"domain"`: Services accessible via subdomains with SSL (production)
- `domain_name`: Your domain name (e.g., "example.com")
- `admin_email`: Used for SSL certificates and notifications

### Application Configuration

```yaml
n8n:
  version: latest              # n8n version to install
  port: 5678                  # Port n8n runs on
  user: n8n                   # System user for n8n
  group: n8n                  # System group for n8n
  home_dir: /opt/n8n          # n8n home directory
  log_level: info             # Logging level: debug, info, warn, error
  timezone: UTC               # Application timezone
  webhook_timeout: 120        # Webhook timeout in seconds
  max_execution_timeout: 3600 # Max workflow execution time
  basic_auth:
    enabled: true             # Enable basic authentication
    user: "admin"             # Username (change this!)
    password: ""              # Auto-generated if empty
```

### Database Configuration

```yaml
postgresql:
  version: 14                 # PostgreSQL version
  port: 5432                 # Database port
  database: n8n              # Database name
  user: n8n                  # Database user
  password: ""               # Auto-generated if empty
  max_connections: 100       # Maximum connections
  shared_buffers: 256MB      # Shared buffer size
  effective_cache_size: 1GB  # Effective cache size
```

### Cache Configuration

```yaml
redis:
  port: 6379                 # Redis port
  password: ""               # Auto-generated if empty
  maxmemory: 256mb           # Maximum memory usage
  maxmemory_policy: allkeys-lru  # Eviction policy
```

## Advanced Configuration

### Nginx Configuration

```yaml
nginx:
  worker_processes: auto     # Number of worker processes
  worker_connections: 1024   # Connections per worker
  client_max_body_size: 50M  # Maximum request body size
  ssl_protocols: "TLSv1.2 TLSv1.3"  # SSL protocols
  ssl_ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256:..."  # SSL ciphers
```

### Monitoring Configuration

```yaml
monitoring:
  prometheus:
    port: 9090               # Prometheus port
    retention: 15d           # Data retention period
    scrape_interval: 15s     # Metrics collection interval
  grafana:
    port: 3000              # Grafana port
    admin_user: admin       # Admin username
    admin_password: ""      # Auto-generated if empty
  node_exporter:
    port: 9100              # Node Exporter port
```

### Security Configuration

```yaml
security:
  ufw_enabled: true          # Enable UFW firewall
  fail2ban_enabled: true     # Enable fail2ban
  ssh_port: 22              # SSH port
  allowed_ssh_users:        # Allowed SSH users
    - ubuntu
    - ec2-user
    - admin
  max_login_attempts: 5     # Max failed login attempts
  ban_time: 3600           # Ban duration in seconds
```

### SSL Configuration

```yaml
ssl:
  enabled: false            # Automatically set based on deployment_type
  email: "admin@example.com"  # Email for Let's Encrypt
  staging: false            # Use staging environment for testing
```

### Backup Configuration

```yaml
backup:
  enabled: true             # Enable automated backups
  schedule: "0 2 * * *"     # Cron schedule (daily at 2 AM)
  retention_days: 30        # Local backup retention
  s3_bucket: ""            # Optional S3 bucket for backups
  local_path: /opt/backups  # Local backup directory
```

## Environment-Specific Settings

### Development Environment

For development/testing environments:

```yaml
deployment_type: "ip"
n8n:
  log_level: debug
postgresql:
  max_connections: 50
  shared_buffers: 128MB
redis:
  maxmemory: 128mb
monitoring:
  prometheus:
    retention: 7d
backup:
  retention_days: 7
```

### Production Environment

For production environments:

```yaml
deployment_type: "domain"
domain_name: "yourdomain.com"
n8n:
  log_level: info
  basic_auth:
    enabled: true
postgresql:
  max_connections: 200
  shared_buffers: 512MB
  effective_cache_size: 2GB
redis:
  maxmemory: 512mb
monitoring:
  prometheus:
    retention: 30d
backup:
  enabled: true
  retention_days: 90
  s3_bucket: "your-backup-bucket"
security:
  ufw_enabled: true
  fail2ban_enabled: true
ssl:
  staging: false
```

## Security Configuration

### Password Management

All passwords are auto-generated if not specified:

```yaml
# These will be auto-generated with secure random passwords
postgresql:
  password: ""  # Leave empty for auto-generation
redis:
  password: ""  # Leave empty for auto-generation
n8n:
  basic_auth:
    password: ""  # Leave empty for auto-generation
monitoring:
  grafana:
    admin_password: ""  # Leave empty for auto-generation
```

### Firewall Rules

Customize firewall rules:

```yaml
security:
  ufw_enabled: true
  # Additional custom rules can be added in roles/common/tasks/main.yml
```

### SSL Certificate Configuration

For domain-based deployments:

```yaml
ssl:
  enabled: true  # Automatically set for domain deployments
  email: "admin@yourdomain.com"  # Required for Let's Encrypt
  staging: false  # Set to true for testing certificates
```

## Performance Tuning

### Database Performance

```yaml
postgresql:
  max_connections: 200        # Adjust based on expected load
  shared_buffers: 512MB       # 25% of available RAM
  effective_cache_size: 2GB   # 75% of available RAM
  work_mem: 4MB              # Memory for sorting operations
  maintenance_work_mem: 64MB  # Memory for maintenance operations
```

### Redis Performance

```yaml
redis:
  maxmemory: 512mb           # Adjust based on available RAM
  maxmemory_policy: allkeys-lru  # Eviction policy
  # Options: allkeys-lru, allkeys-lfu, volatile-lru, volatile-lfu
```

### n8n Performance

```yaml
n8n:
  max_execution_timeout: 3600  # Increase for long-running workflows
  webhook_timeout: 120         # Adjust based on webhook requirements
```

### Nginx Performance

```yaml
nginx:
  worker_processes: auto       # Usually matches CPU cores
  worker_connections: 1024     # Connections per worker
  client_max_body_size: 50M    # Adjust for file uploads
```

## Examples

### Example 1: Simple IP-based Development Setup

```yaml
---
project_name: n8n-dev
deployment_type: "ip"
admin_email: "dev@company.com"

n8n:
  version: latest
  log_level: debug
  basic_auth:
    enabled: false  # Disable for development

postgresql:
  max_connections: 50
  shared_buffers: 128MB

redis:
  maxmemory: 128mb

monitoring:
  prometheus:
    retention: 7d

backup:
  enabled: false  # Disable for development

security:
  ufw_enabled: false  # Disable for development
  fail2ban_enabled: false
```

### Example 2: Production Domain-based Setup

```yaml
---
project_name: n8n-production
deployment_type: "domain"
domain_name: "workflows.company.com"
admin_email: "admin@company.com"

n8n:
  version: latest
  log_level: info
  basic_auth:
    enabled: true
    user: "admin"

postgresql:
  max_connections: 200
  shared_buffers: 512MB
  effective_cache_size: 2GB

redis:
  maxmemory: 512mb
  maxmemory_policy: allkeys-lru

monitoring:
  prometheus:
    retention: 30d
  grafana:
    admin_user: admin

backup:
  enabled: true
  retention_days: 90
  s3_bucket: "company-n8n-backups"

security:
  ufw_enabled: true
  fail2ban_enabled: true
  max_login_attempts: 3
  ban_time: 7200

ssl:
  staging: false
```

### Example 3: High-Performance Setup

```yaml
---
project_name: n8n-enterprise
deployment_type: "domain"
domain_name: "automation.company.com"
admin_email: "devops@company.com"

n8n:
  version: latest
  log_level: info
  max_execution_timeout: 7200  # 2 hours for complex workflows

postgresql:
  max_connections: 500
  shared_buffers: 1GB
  effective_cache_size: 4GB
  work_mem: 8MB
  maintenance_work_mem: 128MB

redis:
  maxmemory: 1gb
  maxmemory_policy: allkeys-lfu

nginx:
  worker_processes: 4
  worker_connections: 2048
  client_max_body_size: 100M

monitoring:
  prometheus:
    retention: 90d
    scrape_interval: 10s

backup:
  enabled: true
  retention_days: 180
  s3_bucket: "enterprise-n8n-backups"
```

## Configuration Validation

### Testing Configuration

Before deployment, validate your configuration:

```bash
# Test Ansible syntax
ansible-playbook --syntax-check -i inventory/hosts.yml playbooks/deploy-n8n.yml

# Test connectivity
ansible all -i inventory/hosts.yml -m ping

# Dry run deployment
ansible-playbook --check -i inventory/hosts.yml playbooks/deploy-n8n.yml
```

### Common Configuration Errors

1. **Missing domain_name for domain deployment**:
   ```yaml
   deployment_type: "domain"
   domain_name: ""  # ❌ This will cause an error
   ```

2. **Invalid email format**:
   ```yaml
   admin_email: "invalid-email"  # ❌ Must be valid email
   ```

3. **Insufficient resources**:
   ```yaml
   postgresql:
     shared_buffers: 2GB  # ❌ Don't exceed available RAM
   ```

## Configuration Best Practices

1. **Use version control**: Store your configuration in Git
2. **Environment separation**: Use different configs for dev/prod
3. **Secure passwords**: Let the system generate secure passwords
4. **Resource sizing**: Size resources based on expected load
5. **Backup configuration**: Always enable backups for production
6. **Monitor resources**: Set up appropriate monitoring thresholds
7. **SSL in production**: Always use domain-based deployment for production
8. **Regular updates**: Keep software versions updated

## Related Documentation

- [🚀 Deployment Guide](DEPLOYMENT_GUIDE.md) - Step-by-step deployment instructions
- [🔒 Security Guide](SECURITY.md) - Security best practices
- [📊 Monitoring Guide](MONITORING.md) - Monitoring and alerting setup
- [🛠️ Maintenance Guide](MAINTENANCE.md) - Ongoing maintenance procedures
