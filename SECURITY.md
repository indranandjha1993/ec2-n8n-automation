# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          |
|---------|--------------------|
| 1.1.x   | :white_check_mark: |
| 1.0.x   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security vulnerability in this project, please follow
these steps:

### 🚨 **DO NOT** create a public GitHub issue for security vulnerabilities

### ✅ **DO** report privately using one of these methods:

1. **GitHub Security Advisories** (Preferred)
    - Go to the repository's Security tab
    - Click "Report a vulnerability"
    - Fill out the private vulnerability report

2. **Email** (Alternative)
    - Send details to: indranandjha1993@gmail.com
    - Include "SECURITY" in the subject line
    - Provide detailed information about the vulnerability

### 📋 **What to Include in Your Report**

- **Description**: Clear description of the vulnerability
- **Impact**: Potential impact and attack scenarios
- **Reproduction**: Step-by-step instructions to reproduce
- **Environment**: Affected versions, configurations, or environments
- **Proof of Concept**: Code, screenshots, or logs (if applicable)
- **Suggested Fix**: If you have ideas for remediation

### 🔄 **Our Response Process**

1. **Acknowledgment**: We'll acknowledge receipt within 48 hours
2. **Investigation**: We'll investigate and assess the vulnerability
3. **Communication**: We'll keep you updated on our progress
4. **Resolution**: We'll develop and test a fix
5. **Disclosure**: We'll coordinate responsible disclosure with you
6. **Credit**: We'll credit you in the security advisory (if desired)

### ⏱️ **Response Timeline**

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution Target**: Within 30 days for critical issues

### 🛡️ **Security Best Practices**

For comprehensive security guidelines, see our [Security Guidelines](docs/SECURITY_GUIDELINES.md).

#### Quick Security Checklist:

- [ ] Never commit secrets, passwords, or API keys
- [ ] Use Ansible Vault for sensitive configuration data
- [ ] Implement proper input validation
- [ ] Use secure file permissions (avoid 777/666)
- [ ] Keep systems and dependencies updated
- [ ] Use HTTPS/TLS for all communications
- [ ] Implement proper logging and monitoring

### 🔍 **Automated Security Scanning**

This repository includes automated security scanning:

- **GitLeaks**: Scans for secrets and credentials
- **Trivy**: Vulnerability scanning for dependencies
- **Ansible-lint**: Security-focused linting for Ansible code
- **Custom checks**: Additional security pattern detection

### 📚 **Security Resources**

- [Security Guidelines](docs/SECURITY_GUIDELINES.md)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Ansible Security Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#best-practices-for-variables-and-vaults)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

### 🏆 **Security Hall of Fame**

We appreciate security researchers who help improve our project's security:

<!-- Future security contributors will be listed here -->

### 📞 **Contact Information**

- **Security Team**: indranandjha1993@gmail.com
- **Maintainer**: [@indranandjha1993](https://github.com/indranandjha1993)

### 🔄 **Policy Updates**

This security policy is reviewed and updated regularly. Last updated: 2025-08-18

---

**Thank you for helping keep our project and community safe!** 🛡️
