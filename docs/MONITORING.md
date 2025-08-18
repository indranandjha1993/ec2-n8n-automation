# Monitoring & Observability

This guide covers the monitoring and observability features included in the n8n deployment.

## Overview

The deployment includes a comprehensive monitoring stack:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and alerting
- **Node Exporter**: System metrics
- **n8n Metrics**: Application-specific metrics

## Access Monitoring Services

### IP-based Deployment
- **Grafana**: `http://your-server-ip:3000`
- **Prometheus**: `http://your-server-ip:9090`

### Domain-based Deployment
- **Grafana**: `https://grafana.yourdomain.com`
- **Prometheus**: `https://prometheus.yourdomain.com`

## Default Credentials

- **Grafana**: `admin` / `[generated-password]`
- **Prometheus**: No authentication required (protected by firewall)

## Available Dashboards

### System Overview Dashboard
- CPU usage and load average
- Memory utilization
- Disk space and I/O
- Network traffic

### n8n Application Dashboard
- Workflow execution metrics
- Response times
- Error rates
- Active connections

### Database Dashboard
- PostgreSQL performance metrics
- Connection counts
- Query performance
- Database size

## Setting Up Alerts

### Grafana Alerting
1. Navigate to Alerting → Alert Rules
2. Create new alert rule
3. Configure notification channels
4. Set up alert conditions

### Common Alert Rules
- High CPU usage (>80% for 5 minutes)
- Low disk space (<10% remaining)
- Service downtime
- High error rates

## Metrics Collection

### System Metrics
- Collected by Node Exporter
- Available at `:9100/metrics`
- Scraped by Prometheus every 15 seconds

### Application Metrics
- n8n exposes metrics at `/metrics` endpoint
- Custom metrics for workflow executions
- Performance and health indicators

## Troubleshooting

### Grafana Issues
```bash
# Check Grafana status
sudo systemctl status grafana-server

# View Grafana logs
sudo journalctl -u grafana-server -f

# Restart Grafana
sudo systemctl restart grafana-server
```

### Prometheus Issues
```bash
# Check Prometheus status
sudo systemctl status prometheus

# View Prometheus logs
sudo journalctl -u prometheus -f

# Restart Prometheus
sudo systemctl restart prometheus
```

## Performance Tuning

### Prometheus Configuration
- Adjust retention period in `prometheus.yml`
- Configure scrape intervals
- Set up recording rules for complex queries

### Grafana Optimization
- Configure data source connection pooling
- Set up dashboard caching
- Optimize query performance

## Backup Monitoring Data

### Prometheus Data
```bash
# Backup Prometheus data
sudo tar -czf prometheus-backup.tar.gz /var/lib/prometheus/

# Restore Prometheus data
sudo systemctl stop prometheus
sudo tar -xzf prometheus-backup.tar.gz -C /
sudo systemctl start prometheus
```

### Grafana Configuration
```bash
# Backup Grafana configuration
sudo tar -czf grafana-backup.tar.gz /etc/grafana/ /var/lib/grafana/

# Restore Grafana configuration
sudo systemctl stop grafana-server
sudo tar -xzf grafana-backup.tar.gz -C /
sudo systemctl start grafana-server
```

## Integration with External Systems

### Webhook Notifications
Configure Grafana to send alerts to:
- Slack channels
- Email addresses
- PagerDuty
- Custom webhooks

### Log Aggregation
Consider integrating with:
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Fluentd
- Loki

For more detailed configuration, see [CONFIGURATION.md](CONFIGURATION.md).
