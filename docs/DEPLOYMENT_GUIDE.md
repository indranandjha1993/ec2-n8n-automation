# n8n Deployment Guide

This guide provides step-by-step instructions for deploying n8n on a single EC2 instance with both IP-based and domain-based configurations.

## Prerequisites

### System Requirements
- Ubuntu 22.04 LTS EC2 instance
- Minimum 2 GB RAM, 2 vCPUs
- 20 GB storage (SSD recommended)
- SSH access to the instance

### Local Requirements
- Ansible >= 2.12 installed
- SSH key for EC2 access
- Domain name (optional, for HTTPS setup)

## Quick Start

### Option 1: Using the Deployment Script (Recommended)

```bash
# Make the script executable
chmod +x scripts/deploy.sh

# Interactive deployment
./scripts/deploy.sh

# Non-interactive IP-based deployment
./scripts/deploy.sh --type ip --email admin@example.com --host your-ec2-ip

# Non-interactive domain-based deployment
./scripts/deploy.sh --type domain --domain example.com --email admin@example.com --host your-ec2-ip --key ~/.ssh/your-key.pem
```

### Option 2: Manual Ansible Deployment

1. **Configure Variables**:
   ```bash
   cp inventory/group_vars/all.yml.example inventory/group_vars/all.yml
   # Edit all.yml with your configuration
   ```

2. **Run Deployment**:
   ```bash
   # IP-based deployment
   ansible-playbook -i inventory/hosts.yml playbooks/deploy-n8n.yml \
     -e deployment_type=ip \
     -e target_host=your-ec2-ip \
     -e admin_email=admin@example.com

   # Domain-based deployment
   ansible-playbook -i inventory/hosts.yml playbooks/deploy-n8n.yml \
     -e deployment_type=domain \
     -e domain_name=example.com \
     -e target_host=your-ec2-ip \
     -e admin_email=admin@example.com
   ```

## Deployment Types

### IP-Based Deployment (HTTP)

Services are accessible via different ports on your EC2 instance IP:

- **n8n**: `http://your-ip:5678`
- **Grafana**: `http://your-ip:3000`
- **Prometheus**: `http://your-ip:9090`
- **pgAdmin**: `http://your-ip:8080`

**Pros:**
- Quick setup, no domain required
- Good for development/testing
- No SSL certificate management

**Cons:**
- No encryption in transit
- Port-based access
- Not suitable for production

### Domain-Based Deployment (HTTPS)

Services are accessible via subdomains with SSL certificates:

- **n8n**: `https://n8n.yourdomain.com`
- **Grafana**: `https://grafana.yourdomain.com`
- **Prometheus**: `https://prometheus.yourdomain.com`
- **pgAdmin**: `https://pgadmin.yourdomain.com`

**Pros:**
- SSL/TLS encryption
- Professional subdomain access
- Automatic certificate renewal
- Production-ready

**Cons:**
- Requires domain name
- DNS configuration needed
- More complex setup

## DNS Configuration (Domain-Based Only)

Before running domain-based deployment, configure these DNS A records:

```
n8n.yourdomain.com      → your-ec2-ip
grafana.yourdomain.com  → your-ec2-ip
prometheus.yourdomain.com → your-ec2-ip
pgadmin.yourdomain.com  → your-ec2-ip
```

## Post-Deployment Steps

### 1. Access Your Services

The deployment will display access URLs and credentials. Save these securely!

### 2. Configure n8n

1. Access your n8n instance
2. Complete the initial setup wizard
3. Create your first workflow
4. Configure webhook endpoints

### 3. Set Up Monitoring

1. Access Grafana with provided credentials
2. Import additional dashboards if needed
3. Configure alerting rules
4. Set up notification channels

### 4. Configure Backups

The system includes automated backups, but you may want to:

1. Configure S3 backup storage:
   ```bash
   # Edit the backup script
   sudo nano /opt/backups/backup.sh
   # Set S3_BUCKET variable
   ```

2. Test backup restoration:
   ```bash
   sudo /usr/local/bin/backup.sh
   ```

### 5. Security Hardening

1. **Change Default Passwords**: Update all generated passwords
2. **Configure Firewall**: Review UFW rules
3. **Enable 2FA**: Configure two-factor authentication where supported
4. **Regular Updates**: Set up automatic security updates

## Maintenance

### Health Monitoring

The system includes automated health checks:

```bash
# Manual health check
sudo /usr/local/bin/health-check.sh

# View health check logs
sudo tail -f /var/log/n8n/health-check.log
```

### Service Management

```bash
# n8n service (via PM2)
sudo -u n8n pm2 status
sudo -u n8n pm2 restart n8n
sudo -u n8n pm2 logs n8n

# System services
sudo systemctl status postgresql redis-server nginx prometheus grafana-server
sudo systemctl restart <service-name>

# View logs
sudo journalctl -u <service-name> -f
```

### Backup Management

```bash
# Manual backup
sudo /usr/local/bin/backup.sh

# List backups
ls -la /opt/backups/

# Restore from backup (example)
sudo tar -xzf /opt/backups/n8n_backup_YYYYMMDD_HHMMSS.tar.gz -C /tmp/
```

### SSL Certificate Management (Domain-Based)

```bash
# Check certificate status
sudo certbot certificates

# Manual renewal
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

## Troubleshooting

### Common Issues

1. **n8n Not Starting**:
   ```bash
   sudo -u n8n pm2 logs n8n
   sudo systemctl status postgresql redis-server
   ```

2. **SSL Certificate Issues**:
   ```bash
   sudo certbot certificates
   sudo nginx -t
   sudo systemctl status nginx
   ```

3. **Database Connection Issues**:
   ```bash
   sudo -u postgres psql -d n8n -c "SELECT version();"
   sudo systemctl status postgresql
   ```

4. **High Resource Usage**:
   ```bash
   htop
   df -h
   sudo -u n8n pm2 monit
   ```

### Log Locations

- **n8n**: `/var/log/n8n/`
- **Nginx**: `/var/log/nginx/`
- **PostgreSQL**: `/var/log/postgresql/`
- **Redis**: `/var/log/redis/`
- **System**: `journalctl -f`

### Getting Help

1. Check the logs for error messages
2. Run the health check script
3. Review the deployment output
4. Check service status with systemctl

## Scaling Considerations

### Vertical Scaling
- Increase EC2 instance size
- Adjust PostgreSQL and Redis memory settings
- Update PM2 instance count

### Horizontal Scaling
For high-availability setups, consider:
- Multiple EC2 instances behind ALB
- RDS PostgreSQL with Multi-AZ
- ElastiCache Redis cluster
- EFS for shared storage

## Security Best Practices

1. **Regular Updates**: Keep all components updated
2. **Access Control**: Use strong passwords and 2FA
3. **Network Security**: Restrict access via security groups
4. **Monitoring**: Set up alerts for suspicious activity
5. **Backups**: Test backup and restore procedures regularly
6. **SSL/TLS**: Always use HTTPS in production
7. **Secrets Management**: Use AWS Systems Manager Parameter Store for production

## Cost Optimization

1. **Instance Sizing**: Right-size your EC2 instance
2. **Reserved Instances**: Use RIs for production workloads
3. **Spot Instances**: Consider for development environments
4. **Storage**: Use GP3 volumes for better cost/performance
5. **Monitoring**: Set up billing alerts
