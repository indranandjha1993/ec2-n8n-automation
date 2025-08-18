#!/bin/bash

# n8n Deployment Script
# This script provides an easy way to deploy n8n with different configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
DEPLOYMENT_TYPE=""
DOMAIN_NAME=""
TARGET_HOST="localhost"
TARGET_USER="ubuntu"
SSH_KEY=""
ADMIN_EMAIL=""
SKIP_PROMPTS=false

# Functions
print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy n8n on a single EC2 instance with optional domain-based HTTPS or IP-based HTTP access.

OPTIONS:
    -t, --type TYPE         Deployment type: 'domain' or 'ip' (required)
    -d, --domain DOMAIN     Domain name for HTTPS deployment (required for domain type)
    -h, --host HOST         Target host IP or hostname (default: localhost)
    -u, --user USER         SSH user for remote deployment (default: ubuntu)
    -k, --key PATH          SSH private key path
    -e, --email EMAIL       Admin email address
    -y, --yes              Skip interactive prompts
    --help                 Show this help message

EXAMPLES:
    # Local IP-based deployment
    $0 --type ip --email admin@example.com

    # Remote domain-based deployment
    $0 --type domain --domain example.com --host 1.2.3.4 --user ubuntu --key ~/.ssh/my-key.pem

    # Interactive deployment (will prompt for missing values)
    $0

EOF
}

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            DEPLOYMENT_TYPE="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN_NAME="$2"
            shift 2
            ;;
        -h|--host)
            TARGET_HOST="$2"
            shift 2
            ;;
        -u|--user)
            TARGET_USER="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -e|--email)
            ADMIN_EMAIL="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_PROMPTS=true
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Interactive prompts if values not provided
if [[ "$SKIP_PROMPTS" == false ]]; then
    if [[ -z "$DEPLOYMENT_TYPE" ]]; then
        echo -e "${BLUE}Select deployment type:${NC}"
        echo "1) IP-based (HTTP access via IP:port)"
        echo "2) Domain-based (HTTPS access via subdomains)"
        read -p "Enter choice (1 or 2): " choice
        case $choice in
            1) DEPLOYMENT_TYPE="ip" ;;
            2) DEPLOYMENT_TYPE="domain" ;;
            *) error "Invalid choice"; exit 1 ;;
        esac
    fi

    if [[ "$DEPLOYMENT_TYPE" == "domain" && -z "$DOMAIN_NAME" ]]; then
        read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
    fi

    if [[ -z "$ADMIN_EMAIL" ]]; then
        read -p "Enter admin email address: " ADMIN_EMAIL
    fi

    if [[ -z "$TARGET_HOST" || "$TARGET_HOST" == "localhost" ]]; then
        read -p "Enter target host IP/hostname (or 'localhost' for local): " input_host
        TARGET_HOST="${input_host:-localhost}"
    fi

    if [[ "$TARGET_HOST" != "localhost" && -z "$TARGET_USER" ]]; then
        read -p "Enter SSH username (default: ubuntu): " input_user
        TARGET_USER="${input_user:-ubuntu}"
    fi

    if [[ "$TARGET_HOST" != "localhost" && -z "$SSH_KEY" ]]; then
        read -p "Enter SSH key path (optional): " SSH_KEY
    fi
fi

# Validation
if [[ -z "$DEPLOYMENT_TYPE" ]]; then
    error "Deployment type is required"
    exit 1
fi

if [[ "$DEPLOYMENT_TYPE" != "ip" && "$DEPLOYMENT_TYPE" != "domain" ]]; then
    error "Deployment type must be 'ip' or 'domain'"
    exit 1
fi

if [[ "$DEPLOYMENT_TYPE" == "domain" && -z "$DOMAIN_NAME" ]]; then
    error "Domain name is required for domain-based deployment"
    exit 1
fi

if [[ -z "$ADMIN_EMAIL" ]]; then
    error "Admin email is required"
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v ansible-playbook &> /dev/null; then
        error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    if [[ "$TARGET_HOST" != "localhost" ]]; then
        if [[ -n "$SSH_KEY" && ! -f "$SSH_KEY" ]]; then
            error "SSH key file not found: $SSH_KEY"
            exit 1
        fi
        
        # Test SSH connectivity
        ssh_cmd="ssh -o ConnectTimeout=10 -o BatchMode=yes"
        if [[ -n "$SSH_KEY" ]]; then
            ssh_cmd="$ssh_cmd -i $SSH_KEY"
        fi
        
        if ! $ssh_cmd "$TARGET_USER@$TARGET_HOST" "echo 'SSH connection successful'" &>/dev/null; then
            error "Cannot connect to $TARGET_HOST via SSH"
            exit 1
        fi
    fi
    
    success "Prerequisites check passed"
}

# Display deployment summary
display_summary() {
    echo
    echo -e "${BLUE}=== Deployment Summary ===${NC}"
    echo -e "Deployment Type: ${GREEN}$DEPLOYMENT_TYPE${NC}"
    echo -e "Target Host: ${GREEN}$TARGET_HOST${NC}"
    if [[ "$DEPLOYMENT_TYPE" == "domain" ]]; then
        echo -e "Domain: ${GREEN}$DOMAIN_NAME${NC}"
        echo -e "Services will be available at:"
        echo -e "  - n8n: ${GREEN}https://n8n.$DOMAIN_NAME${NC}"
        echo -e "  - Grafana: ${GREEN}https://grafana.$DOMAIN_NAME${NC}"
        echo -e "  - Prometheus: ${GREEN}https://prometheus.$DOMAIN_NAME${NC}"
        echo -e "  - pgAdmin: ${GREEN}https://pgadmin.$DOMAIN_NAME${NC}"
    else
        echo -e "Services will be available at:"
        echo -e "  - n8n: ${GREEN}http://$TARGET_HOST:5678${NC}"
        echo -e "  - Grafana: ${GREEN}http://$TARGET_HOST:3000${NC}"
        echo -e "  - Prometheus: ${GREEN}http://$TARGET_HOST:9090${NC}"
        echo -e "  - pgAdmin: ${GREEN}http://$TARGET_HOST:8080${NC}"
    fi
    echo -e "Admin Email: ${GREEN}$ADMIN_EMAIL${NC}"
    echo
}

# Run Ansible playbook
run_deployment() {
    log "Starting deployment..."
    
    # Build Ansible command
    ansible_cmd="ansible-playbook -i inventory/hosts.yml playbooks/deploy-n8n.yml"
    ansible_cmd="$ansible_cmd -e deployment_type=$DEPLOYMENT_TYPE"
    ansible_cmd="$ansible_cmd -e admin_email=$ADMIN_EMAIL"
    ansible_cmd="$ansible_cmd -e target_host=$TARGET_HOST"
    
    if [[ "$TARGET_HOST" != "localhost" ]]; then
        ansible_cmd="$ansible_cmd -e target_user=$TARGET_USER"
        if [[ -n "$SSH_KEY" ]]; then
            ansible_cmd="$ansible_cmd -e ssh_key_path=$SSH_KEY"
        fi
    fi
    
    if [[ "$DEPLOYMENT_TYPE" == "domain" ]]; then
        ansible_cmd="$ansible_cmd -e domain_name=$DOMAIN_NAME"
    fi
    
    # Execute deployment
    if eval "$ansible_cmd"; then
        log "Deployment completed successfully! 🎉"
        
        echo
        echo -e "${GREEN}=== Deployment Complete ===${NC}"
        if [[ "$DEPLOYMENT_TYPE" == "domain" ]]; then
            echo -e "Your n8n instance is available at: ${GREEN}https://n8n.$DOMAIN_NAME${NC}"
        else
            echo -e "Your n8n instance is available at: ${GREEN}http://$TARGET_HOST:5678${NC}"
        fi
        echo
        echo -e "${YELLOW}Important:${NC} Save the generated passwords shown in the deployment output!"
        echo
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Access your n8n instance and complete the setup"
        echo "2. Configure your workflows"
        echo "3. Set up monitoring alerts in Grafana"
        echo "4. Configure backup retention policies"
        
    else
        error "Deployment failed. Check the output above for details."
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}n8n Deployment Script${NC}"
    echo "======================"
    
    check_prerequisites
    display_summary
    
    if [[ "$SKIP_PROMPTS" == false ]]; then
        read -p "Proceed with deployment? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            info "Deployment cancelled by user"
            exit 0
        fi
    fi
    
    run_deployment
}

# Run main function
main
