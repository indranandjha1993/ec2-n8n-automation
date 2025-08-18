# Contributing to n8n EC2 Deployment

We welcome contributions to make this n8n deployment solution even better! This guide will help you get started with contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Documentation](#documentation)
- [Testing](#testing)

## Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow. Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md) to help us maintain a welcoming community.

## Getting Started

### Ways to Contribute

- 🐛 **Bug Reports**: Report bugs and issues
- ✨ **Feature Requests**: Suggest new features or improvements
- 📝 **Documentation**: Improve documentation and guides
- 🔧 **Code**: Fix bugs, add features, improve performance
- 🧪 **Testing**: Add tests, test on different platforms
- 💡 **Ideas**: Share ideas for improvements

### Before You Start

1. **Check existing issues** to avoid duplicates
2. **Read the documentation** to understand the project
3. **Test the current version** to understand how it works
4. **Join discussions** in existing issues or start new ones

## Development Setup

### Prerequisites

- **Ansible** >= 2.12
- **Git** for version control
- **AWS CLI** (optional, for testing)
- **EC2 instance** or local VM for testing
- **Domain name** (optional, for SSL testing)

### Fork and Clone

```bash
# 1. Fork the repository on GitHub
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/n8n-ec2-deployment.git
cd n8n-ec2-deployment

# 3. Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/n8n-ec2-deployment.git

# 4. Create a new branch for your feature
git checkout -b feature/your-feature-name
```

### Development Environment

```bash
# 1. Copy example configuration
cp inventory/group_vars/all.yml.example inventory/group_vars/all.yml

# 2. Set up test environment (use a test EC2 instance)
# Edit inventory/hosts.yml with your test instance details

# 3. Test the deployment
./scripts/deploy.sh --type ip --host your-test-ip --email test@example.com
```

### Project Structure

```
n8n-ec2-deployment/
├── ansible.cfg                 # Ansible configuration
├── inventory/                  # Inventory and variables
│   ├── hosts.yml              # Host definitions
│   └── group_vars/            # Group variables
├── roles/                     # Ansible roles
│   ├── common/                # Common system setup
│   ├── postgresql/            # Database setup
│   ├── redis/                 # Cache setup
│   ├── n8n/                   # n8n application
│   ├── nginx/                 # Web server and proxy
│   ├── ssl/                   # SSL certificate management
│   └── monitoring/            # Monitoring stack
├── playbooks/                 # Ansible playbooks
│   └── deploy-n8n.yml         # Main deployment playbook
├── scripts/                   # Utility scripts
│   ├── deploy.sh              # Deployment script
│   ├── backup.sh              # Backup script
│   └── health-check.sh        # Health check script
├── docs/                      # Documentation
└── tests/                     # Test files
```

## Contributing Guidelines

### Code Style

#### Ansible Best Practices

1. **Use descriptive task names**:
   ```yaml
   - name: Install PostgreSQL packages
     apt:
       name:
         - postgresql-14
         - postgresql-contrib-14
   ```

2. **Use tags consistently**:
   ```yaml
   - name: Configure PostgreSQL
     template:
       src: postgresql.conf.j2
       dest: /etc/postgresql/14/main/postgresql.conf
     tags: [postgresql, config]
   ```

3. **Handle errors gracefully**:
   ```yaml
   - name: Start PostgreSQL service
     systemd:
       name: postgresql
       state: started
       enabled: yes
     register: postgres_start
     failed_when: postgres_start.failed and "already running" not in postgres_start.msg
   ```

4. **Use variables for configuration**:
   ```yaml
   - name: Create database user
     postgresql_user:
       name: "{{ postgresql.user }}"
       password: "{{ postgresql.password }}"
   ```

#### Shell Script Guidelines

1. **Use strict error handling**:
   ```bash
   #!/bin/bash
   set -euo pipefail
   ```

2. **Use meaningful variable names**:
   ```bash
   BACKUP_DIR="/opt/backups"
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   ```

3. **Add proper logging**:
   ```bash
   log() {
       echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
   }
   ```

#### Documentation Standards

1. **Use clear headings and structure**
2. **Include code examples**
3. **Add internal links to related documentation**
4. **Keep examples up to date**

### Commit Messages

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(monitoring): add Redis exporter for metrics collection

fix(ssl): resolve certificate renewal issue with nginx reload

docs(readme): update installation instructions for Ubuntu 22.04

refactor(roles): consolidate common tasks across roles
```

### Branch Naming

Use descriptive branch names:

- `feature/add-redis-monitoring`
- `fix/ssl-certificate-renewal`
- `docs/update-configuration-guide`
- `refactor/simplify-deployment-script`

## Pull Request Process

### Before Submitting

1. **Test your changes** thoroughly
2. **Update documentation** if needed
3. **Add or update tests** if applicable
4. **Check for conflicts** with main branch
5. **Follow code style guidelines**

### Submitting a Pull Request

1. **Push your branch** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a pull request** on GitHub with:
   - Clear title and description
   - Reference to related issues
   - Screenshots if UI changes
   - Testing instructions

3. **Pull request template**:
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Refactoring

   ## Testing
   - [ ] Tested on Ubuntu 22.04
   - [ ] Tested IP-based deployment
   - [ ] Tested domain-based deployment
   - [ ] All services start correctly

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   - [ ] Tests added/updated
   ```

### Review Process

1. **Automated checks** must pass
2. **Code review** by maintainers
3. **Testing** on different environments
4. **Documentation review** if applicable
5. **Approval** from at least one maintainer

## Issue Reporting

### Bug Reports

Use the bug report template:

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run deployment with '...'
2. Access service at '...'
3. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- Deployment type: [IP/Domain]
- Ansible version: [e.g., 2.12]

**Logs**
Relevant log excerpts or error messages.

**Additional context**
Any other context about the problem.
```

### Feature Requests

Use the feature request template:

```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features you've considered.

**Additional context**
Any other context or screenshots about the feature request.
```

## Documentation

### Documentation Guidelines

1. **Keep it up to date** with code changes
2. **Use clear, simple language**
3. **Include practical examples**
4. **Add internal cross-references**
5. **Test all code examples**

### Documentation Structure

```
docs/
├── ARCHITECTURE.md         # System architecture
├── CONFIGURATION.md        # Configuration guide
├── DEPLOYMENT_GUIDE.md     # Step-by-step deployment
├── SECURITY.md            # Security best practices
├── MONITORING.md          # Monitoring setup
├── MAINTENANCE.md         # Maintenance procedures
└── TROUBLESHOOTING.md     # Common issues and solutions
```

### Writing Documentation

1. **Start with an overview**
2. **Use a table of contents**
3. **Include prerequisites**
4. **Provide step-by-step instructions**
5. **Add troubleshooting sections**
6. **Link to related documentation**

## Testing

### Manual Testing

Test your changes on:

1. **Fresh Ubuntu 22.04 instance**
2. **Both deployment types** (IP and domain)
3. **Different instance sizes** (t3.medium, t3.large)
4. **Various configurations**

### Testing Checklist

- [ ] **Deployment completes** without errors
- [ ] **All services start** correctly
- [ ] **Web interfaces accessible**
- [ ] **SSL certificates** work (domain deployment)
- [ ] **Monitoring** shows correct data
- [ ] **Backups** can be created and restored
- [ ] **Health checks** pass
- [ ] **Security** configurations work

### Test Environment Setup

```bash
# 1. Create test EC2 instance
aws ec2 run-instances \
  --image-id ami-0c02fb55956c7d316 \
  --instance-type t3.medium \
  --key-name your-test-key \
  --security-group-ids sg-xxxxxxxxx

# 2. Test deployment
./scripts/deploy.sh --type ip --host test-instance-ip

# 3. Verify all services
curl http://test-instance-ip:5678
curl http://test-instance-ip:3000
curl http://test-instance-ip:9090

# 4. Clean up
aws ec2 terminate-instances --instance-ids i-xxxxxxxxx
```

## Release Process

### Version Numbering

We use [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped
- [ ] Release notes prepared
- [ ] Tagged release created

## Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Request Comments**: Code-specific discussions

### Resources

- [📖 Documentation](docs/) - Complete documentation
- [🚀 Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Getting started
- [⚙️ Configuration Guide](docs/CONFIGURATION.md) - Configuration options
- [🔧 Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues

## Recognition

Contributors will be recognized in:

- **README.md** contributors section
- **CHANGELOG.md** for significant contributions
- **GitHub releases** for major contributions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to make this n8n deployment solution better for everyone! 🎉
