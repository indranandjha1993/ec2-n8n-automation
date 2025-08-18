---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## 🐛 Bug Description

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run deployment with configuration '...'
2. Access service at '...'
3. Execute command '...'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

## 🖥️ Environment

**System Information:**
- OS: [e.g., Ubuntu 22.04]
- Instance Type: [e.g., t3.medium]
- Deployment Type: [IP-based/Domain-based]
- Domain Name: [if applicable]

**Software Versions:**
- Ansible Version: [e.g., 2.12.1]
- n8n Version: [e.g., 1.0.0]
- PostgreSQL Version: [e.g., 14]
- Redis Version: [e.g., 6.0]

**Configuration:**
```yaml
# Paste relevant configuration from inventory/group_vars/all.yml
deployment_type: "ip"
domain_name: ""
# ... other relevant config
```

## 📋 Logs and Error Messages

**Error Messages:**
```
Paste error messages here
```

**Relevant Logs:**
```bash
# n8n logs
sudo -u n8n pm2 logs n8n

# System logs
sudo journalctl -u postgresql -f
sudo journalctl -u nginx -f

# Health check logs
sudo /usr/local/bin/n8n-health-check.sh
```

**Ansible Output:**
```
Paste relevant Ansible output here
```

## 📸 Screenshots

If applicable, add screenshots to help explain your problem.

## 🔍 Additional Context

**What you were trying to accomplish:**
Describe what you were trying to do when the error occurred.

**Workarounds tried:**
List any workarounds or solutions you've already attempted.

**Additional context:**
Add any other context about the problem here.

## ✅ Checklist

- [ ] I have searched existing issues to avoid duplicates
- [ ] I have included all relevant information above
- [ ] I have tested with the latest version
- [ ] I have included logs and error messages
- [ ] I have provided steps to reproduce the issue

---

**Note:** Please remove any sensitive information (passwords, private keys, etc.) from logs and configuration before submitting.
