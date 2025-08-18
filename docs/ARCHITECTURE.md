# Architecture Documentation

## Overview

This n8n deployment architecture is designed for single EC2 instance deployment with flexibility to support both
development (IP-based HTTP) and production (domain-based HTTPS) environments.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        EC2 Instance                             │
│                                                                 │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐     │
│  │   Nginx     │    │     n8n      │    │   Monitoring    │     │
│  │   (Proxy)   │◄──►│  (Node.js)   │    │   (Prometheus)  │     │
│  │   Port 80   │    │   Port 5678  │    │   Port 9090     │     │
│  │   Port 443  │    │              │    │                 │     │
│  └─────────────┘    └──────────────┘    └─────────────────┘     │
│         │                   │                    │              │
│         │            ┌──────▼──────┐             │              │
│         │            │    PM2      │             │              │
│         │            │ (Process    │             │              │
│         │            │  Manager)   │             │              │
│         │            └─────────────┘             │              │
│         │                  │                     │              │
│  ┌──────▼──────┐    ┌──────▼──────┐    ┌─────────▼─────────┐    │
│  │   Grafana   │    │ PostgreSQL  │    │     Redis         │    │
│  │ Port 3000   │    │ Port 5432   │    │   Port 6379       │    │
│  └─────────────┘    └─────────────┘    └───────────────────┘    │
│         │                  │                      │             │
│  ┌──────▼──────┐           │                      │             │
│  │   pgAdmin   │           │                      │             │
│  │ Port 8080   │           │                      │             │
│  └─────────────┘           │                      │             │
│                            │                      │             │
│  ┌─────────────────────────▼──────────────────────▼────────┐    │
│  │                 Local Storage                           │    │
│  │  • PostgreSQL Data (/var/lib/postgresql/)               │    │
│  │  • Redis Data (/var/lib/redis/)                         │    │
│  │  • n8n Workflows (/opt/n8n/.n8n/)                       │    │
│  │  • Logs (/var/log/)                                     │    │
│  │  • Backups (/opt/backups/)                              │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### Web Layer (Nginx)

**Purpose**: Reverse proxy, SSL termination, load balancing
**Configuration**:

- IP-based: Port-based routing (80 → service ports)
- Domain-based: Subdomain routing with SSL (443 → services)

**Features**:

- SSL/TLS termination with Let's Encrypt
- Security headers
- Rate limiting
- Gzip compression
- Static file serving

### Application Layer (n8n)

**Purpose**: Workflow automation engine
**Runtime**: Node.js with PM2 process manager
**Database**: PostgreSQL for workflow storage
**Queue**: Redis for job processing

**Features**:

- Workflow designer and executor
- REST API and webhooks
- User management
- Metrics endpoint
- File storage

### Data Layer

#### PostgreSQL Database

- **Purpose**: Primary data store for workflows, executions, users
- **Configuration**: Local installation with security hardening
- **Backup**: Automated daily backups with retention
- **Security**: SCRAM-SHA-256 authentication, localhost binding

#### Redis Cache

- **Purpose**: Job queue, session storage, caching
- **Configuration**: Local installation with password protection
- **Persistence**: RDB snapshots for durability
- **Security**: Password authentication, localhost binding

### Monitoring Layer

#### Prometheus

- **Purpose**: Metrics collection and alerting
- **Targets**: System metrics, application metrics, custom metrics
- **Retention**: Configurable (default 15 days)
- **Alerting**: Rule-based alerting system

#### Grafana

- **Purpose**: Visualization and dashboards
- **Data Sources**: Prometheus, logs
- **Dashboards**: System overview, application metrics
- **Alerting**: Visual alerts and notifications

#### Node Exporter

- **Purpose**: System-level metrics collection
- **Metrics**: CPU, memory, disk, network statistics
- **Integration**: Automatic Prometheus discovery

### Management Layer

#### pgAdmin

- **Purpose**: PostgreSQL database administration
- **Access**: Web-based interface
- **Security**: Authentication required
- **Features**: Query editor, database management

#### PM2

- **Purpose**: Node.js process management
- **Features**: Auto-restart, clustering, monitoring
- **Logging**: Centralized log management
- **Monitoring**: Real-time process monitoring

## Security Architecture

### Network Security

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

1. **Network Level**:
    - UFW firewall with minimal open ports
    - Fail2ban for intrusion prevention
    - Security groups (AWS level)

2. **Transport Level**:
    - SSL/TLS encryption (domain-based)
    - Strong cipher suites
    - HSTS headers

3. **Application Level**:
    - Basic authentication for n8n
    - Database authentication (SCRAM-SHA-256)
    - Redis password protection
    - Service isolation (localhost binding)

4. **System Level**:
    - Regular security updates
    - Log monitoring
    - File permissions
    - User isolation

## Data Flow

### Workflow Execution Flow

```
User Request → Nginx → n8n → PostgreSQL (workflow data)
                  ↓
              Redis Queue → Worker Process → External APIs
                  ↓
              Execution Results → PostgreSQL (execution data)
```

### Monitoring Data Flow

```
System Metrics → Node Exporter → Prometheus → Grafana
Application Metrics → n8n → Prometheus → Grafana
Logs → File System → Log Aggregation → Grafana
```

### Backup Data Flow

```
PostgreSQL → pg_dump → Local Storage → Optional S3 Upload
n8n Data → tar.gz → Local Storage → Optional S3 Upload
Configs → tar.gz → Local Storage → Optional S3 Upload
```

## Deployment Patterns

### IP-Based Deployment

```
Client → http://ip:port → Nginx → Service
```

- Simple port-based routing
- No SSL encryption
- Suitable for development/testing

### Domain-Based Deployment

```
Client → https://subdomain.domain.com → Nginx (SSL) → Service
```

- Subdomain-based routing
- SSL/TLS encryption
- Production-ready

## Scalability Considerations

### Vertical Scaling

- **CPU**: Increase instance size for more processing power
- **Memory**: Scale for larger datasets and concurrent users
- **Storage**: Add EBS volumes for data growth
- **Network**: Enhanced networking for higher throughput

### Horizontal Scaling Path

For future scaling beyond single instance:

1. **Application Tier**:
    - Multiple n8n instances behind ALB
    - Shared storage via EFS
    - Session affinity or stateless design

2. **Database Tier**:
    - RDS PostgreSQL with Multi-AZ
    - Read replicas for scaling reads
    - Connection pooling

3. **Cache Tier**:
    - ElastiCache Redis cluster
    - Redis Cluster mode for scaling
    - Separate cache from queue

4. **Storage Tier**:
    - EFS for shared workflows
    - S3 for backups and static assets
    - CloudWatch for centralized logging

## High Availability Design

### Current Single-Point-of-Failures

- Single EC2 instance
- Local PostgreSQL database
- Local Redis instance
- Single AZ deployment

### HA Improvements (Future)

- Multi-AZ deployment
- RDS with automatic failover
- ElastiCache with cluster mode
- Application Load Balancer
- Auto Scaling Groups

## Disaster Recovery

### Backup Strategy

- **RTO**: Recovery Time Objective < 4 hours
- **RPO**: Recovery Point Objective < 24 hours
- **Backup Frequency**: Daily automated backups
- **Retention**: 30 days local, longer in S3

### Recovery Procedures

1. **Data Recovery**: Restore from PostgreSQL backup
2. **Application Recovery**: Redeploy from Ansible playbook
3. **Configuration Recovery**: Restore from config backup
4. **SSL Recovery**: Re-issue certificates if needed

## Performance Characteristics

### Expected Performance

- **Concurrent Users**: 10-50 (single instance)
- **Workflow Executions**: 100-1000 per hour
- **Response Time**: < 2 seconds for UI
- **Throughput**: Depends on workflow complexity

### Performance Monitoring

- **Metrics**: CPU, memory, disk I/O, network
- **Application**: Execution times, queue depth
- **Database**: Connection count, query performance
- **Alerts**: Threshold-based alerting

## Cost Analysis

### Resource Costs (Monthly estimates)

- **EC2 Instance**: $20-100 (t3.medium to t3.large)
- **EBS Storage**: $2-10 (20-100 GB)
- **Data Transfer**: $1-5 (minimal for single instance)
- **Domain/SSL**: $10-15 (domain registration)

### Cost Optimization

- **Right-sizing**: Monitor and adjust instance size
- **Reserved Instances**: 1-year commitment for 30% savings
- **Spot Instances**: Development environments
- **Storage Optimization**: GP3 volumes, lifecycle policies
