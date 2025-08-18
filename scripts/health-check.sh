#!/bin/bash

# Comprehensive Health Check Script for n8n Deployment
# This script checks the health of all components and sends alerts if needed

set -euo pipefail

# Configuration
LOG_FILE="/var/log/n8n/health-check.log"
ALERT_EMAIL=""  # Set this to receive email alerts
SLACK_WEBHOOK=""  # Set this to receive Slack alerts

# Service endpoints
N8N_URL="http://localhost:5678"
GRAFANA_URL="http://localhost:3000"
PROMETHEUS_URL="http://localhost:9090"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Initialize variables
OVERALL_STATUS="healthy"
ISSUES=()

# Logging function
log() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    echo -e "$message" | tee -a "$LOG_FILE"
}

error() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo -e "${RED}$message${NC}" | tee -a "$LOG_FILE"
    OVERALL_STATUS="unhealthy"
    ISSUES+=("$1")
}

warning() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1"
    echo -e "${YELLOW}$message${NC}" | tee -a "$LOG_FILE"
}

success() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1"
    echo -e "${GREEN}$message${NC}" | tee -a "$LOG_FILE"
}

# Check service status
check_service() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        success "$service_name is running"
        return 0
    else
        error "$service_name is not running"
        return 1
    fi
}

# Check HTTP endpoint
check_http_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    
    if curl -f -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        success "$name is responding correctly"
        return 0
    else
        error "$name is not responding or returning unexpected status"
        return 1
    fi
}

# Check database connectivity
check_database() {
    if sudo -u postgres psql -d n8n -c "SELECT 1;" > /dev/null 2>&1; then
        success "PostgreSQL database is accessible"
        return 0
    else
        error "PostgreSQL database is not accessible"
        return 1
    fi
}

# Check Redis connectivity
check_redis() {
    if redis-cli ping > /dev/null 2>&1; then
        success "Redis is responding"
        return 0
    else
        error "Redis is not responding"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    local threshold=90
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ $usage -lt $threshold ]]; then
        success "Disk usage is acceptable ($usage%)"
        return 0
    else
        error "Disk usage is high ($usage% >= $threshold%)"
        return 1
    fi
}

# Check memory usage
check_memory() {
    local threshold=90
    local usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [[ $usage -lt $threshold ]]; then
        success "Memory usage is acceptable ($usage%)"
        return 0
    else
        warning "Memory usage is high ($usage% >= $threshold%)"
        return 1
    fi
}

# Check SSL certificates (if domain-based deployment)
check_ssl_certificates() {
    local domain="$1"
    if [[ -n "$domain" ]]; then
        local cert_file="/etc/letsencrypt/live/n8n.$domain/fullchain.pem"
        if [[ -f "$cert_file" ]]; then
            local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
            local expiry_epoch=$(date -d "$expiry_date" +%s)
            local current_epoch=$(date +%s)
            local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
            
            if [[ $days_until_expiry -gt 30 ]]; then
                success "SSL certificate is valid ($days_until_expiry days remaining)"
                return 0
            elif [[ $days_until_expiry -gt 7 ]]; then
                warning "SSL certificate expires soon ($days_until_expiry days remaining)"
                return 1
            else
                error "SSL certificate expires very soon ($days_until_expiry days remaining)"
                return 1
            fi
        else
            error "SSL certificate file not found"
            return 1
        fi
    fi
}

# Send alert
send_alert() {
    local subject="n8n Health Check Alert - $(hostname)"
    local body="Health check failed on $(hostname) at $(date)\n\nIssues found:\n"
    
    for issue in "${ISSUES[@]}"; do
        body="${body}- $issue\n"
    done
    
    # Email alert
    if [[ -n "$ALERT_EMAIL" ]]; then
        echo -e "$body" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    
    # Slack alert
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$subject\n$body\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
}

# Main health check routine
main() {
    log "Starting comprehensive health check..."
    
    # System services
    check_service "postgresql"
    check_service "redis-server"
    check_service "nginx"
    check_service "prometheus"
    check_service "grafana-server"
    
    # Database and cache
    check_database
    check_redis
    
    # HTTP endpoints
    check_http_endpoint "n8n" "$N8N_URL" "200|401"  # 401 is OK if basic auth is enabled
    check_http_endpoint "Grafana" "$GRAFANA_URL"
    check_http_endpoint "Prometheus" "$PROMETHEUS_URL"
    
    # System resources
    check_disk_space
    check_memory
    
    # SSL certificates (if applicable)
    # Uncomment and set domain if using domain-based deployment
    # check_ssl_certificates "yourdomain.com"
    
    # PM2 process check
    if sudo -u n8n pm2 list | grep -q "n8n.*online"; then
        success "n8n PM2 process is running"
    else
        error "n8n PM2 process is not running properly"
    fi
    
    # Final status
    if [[ "$OVERALL_STATUS" == "healthy" ]]; then
        log "Overall system status: HEALTHY ✅"
        exit 0
    else
        log "Overall system status: UNHEALTHY ❌"
        send_alert
        exit 1
    fi
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main "$@"
