# Security Management Guide

Comprehensive security practices and credential management for system administrators.

## 🔐 Security Framework Overview

The Lab Environment Management System implements a **security-first** approach with zero hardcoded passwords and comprehensive credential management through the `lib/utl/sec` utility library.

### Core Security Principles

1. **Zero Hardcoded Credentials**: All passwords and secrets managed through secure utilities
2. **Automatic Permissions**: Sensitive files automatically set to 600 permissions
3. **Graceful Fallbacks**: System handles missing credentials without failures
4. **Environment Isolation**: Security contexts separated by environment (dev/test/prod)
5. **Audit Trail**: All security operations logged for compliance

## 🛡️ Credential Management

### Security Utilities (`lib/utl/sec`)
- **120+ lines** of secure credential handling code
- **Automatic permission management** for sensitive files
- **Zero hardcoded passwords** across the entire system
- **Fallback mechanisms** for missing credentials
- **Environment-aware** credential loading

### Credential Storage Patterns
```bash
# Secure credential files (automatically set to 600)
cfg/env/site1-prod/credentials
cfg/env/site1-dev/credentials
cfg/env/site1-test/credentials

# Node-specific credential overrides
cfg/env/site1-prod/node-specific/hostname.credentials
```

### Best Practices
1. **Never commit credentials** to version control
2. **Use environment-specific** credential files
3. **Implement proper file permissions** (automatic via lib/utl/sec)
4. **Regular credential rotation** procedures
5. **Audit credential access** through logging

## 🔑 SSH Key Management

### SSH Utilities (`lib/utl/ssh`)
```bash
# SSH key generation and distribution
# Handled through lib/utl/ssh with secure patterns

# Example usage in deployment scripts
cd src/set/pve
./pve d  # Generate SSH keys securely
```

### SSH Security Configuration
```bash
# SSH configuration for cluster nodes
SSH_USERS=("admin" "operator")
KEY_NAME="lab-cluster"

# Automatic key distribution across cluster
# - Secure key generation
# - Proper permission setting
# - Multi-node distribution
```

## 🌐 Network Security

### Network Isolation
```bash
# Environment-specific network ranges
# Development: 192.168.178.0/24 (dev subnet)
# Testing: 192.168.179.0/24 (test subnet)
# Production: 192.168.180.0/24 (prod subnet)

# QDevice network isolation
QDEVICE_IP="192.168.1.12"  # Dedicated QDevice network
```

### Firewall Configuration
- **Service-specific rules** for container services
- **Environment isolation** between dev/test/prod
- **Cluster communication** security
- **External access controls**

## 🔐 Access Control

### User Management
```bash
# User account management through lib/ops/usr
# - Standardized user creation
# - Role-based access control
# - Environment-specific permissions
# - Group membership management
```

### Service Account Security
- **Container service accounts** with minimal privileges
- **Backup service accounts** for PBS operations
- **Monitoring accounts** with read-only access
- **Administrative accounts** with audit trails

### Permission Framework
- **File system permissions** automatically managed
- **Service permissions** through systemd integration
- **Container permissions** through Proxmox VE RBAC
- **Network permissions** through firewall rules

## 📊 Security Monitoring

### Audit Logging
```bash
# Security events logged to
${LOG_DIR}/.log/err.log     # Error and security violations
${LOG_DIR}/.log/lo1.log     # Module-specific security events

# Security-related environment variables
ERROR_LOG="${LOG_DIR}/.log/err.log"
```

### Security Validation
```bash
# Regular security checks
./tst/validate_system       # Includes security validation
./tst/test_environment      # Environment security testing

# Security-specific validation
# - Credential file permissions
# - SSH key integrity
# - Service account validation
# - Network security checks
```

### Compliance Reporting
- **Credential access tracking** through logging
- **Permission change auditing** 
- **Security event correlation**
- **Regular compliance validation**

## 🚨 Incident Response

### Security Event Handling
```bash
# Automatic error handling for security events
# Through lib/core/err with security-specific processing

# Security incident logging
handle_error "security" "Unauthorized access attempt" "CRITICAL"
handle_error "credentials" "Invalid credential access" "WARNING"
```

### Emergency Procedures
1. **Credential Rotation**: Immediate credential change procedures
2. **Access Revocation**: Quick user/service account disabling
3. **Network Isolation**: Emergency network segmentation
4. **Audit Trail Preservation**: Secure log backup and analysis

## 🔧 Security Configuration Examples

### Environment Security Setup
```bash
# Production environment security
export SITE="site1"
export ENVIRONMENT="prod"
export SECURITY_LEVEL="high"

# Load security configuration
source lib/utl/sec
# Automatic credential loading with secure patterns
```

### Container Security
```bash
# Secure container deployment
# Through lib/utl/inf with security validation

define_containers "111:pbs:192.168.178.111"
# - Automatic security context
# - Proper network isolation
# - Service account assignment
```

### Backup Security
```bash
# Secure backup operations through PBS
# - Encrypted backup streams
# - Secure credential management
# - Access control validation
# - Audit trail maintenance
```

## 📋 Security Checklist

### Daily Operations
- [ ] Verify credential file permissions (600)
- [ ] Check security event logs
- [ ] Validate service account status
- [ ] Review network access logs

### Weekly Operations
- [ ] Security validation testing
- [ ] Credential rotation review
- [ ] Access control audit
- [ ] Backup security verification

### Monthly Operations
- [ ] Comprehensive security assessment
- [ ] Credential rotation execution
- [ ] Security policy review
- [ ] Compliance reporting

## 📖 Related Documentation

- **[Configuration Management](configuration.md)** - Secure configuration practices
- **[Infrastructure Guide](../iac/infrastructure.md)** - Secure deployment patterns
- **[Logging System](../dev/logging.md)** - Security event logging
