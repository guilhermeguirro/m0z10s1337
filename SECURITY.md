# Security Policy

## Supported Versions

Use this section to tell people about which versions of your project are currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.0   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of our Kubernetes Chaos Engineering toolkit seriously. If you believe you've found a security vulnerability, please follow these steps:

1. **Do not disclose the vulnerability publicly**
2. **Email the details to security@yourdomain.com** including:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes (if available)

## Security Best Practices for Using This Toolkit

### Cluster Security
- Run chaos experiments in isolated, non-production environments first
- Use RBAC to limit the permissions of the chaos controller
- Enable audit logging in your Kubernetes cluster
- Use network policies to restrict pod-to-pod communication

### Secret Management
- Rotate secrets regularly (our toolkit includes automation for this)
- Use a secrets management solution like HashiCorp Vault or AWS KMS
- Never store secrets in plain text or commit them to version control
- Implement least privilege access for all secrets

### Container Security
- Use minimal base images for all containers
- Scan container images for vulnerabilities before deployment
- Run containers as non-root users
- Set resource limits for all containers

### Chaos Experiment Safety
- Always define a clear blast radius for experiments
- Set appropriate timeouts for all chaos experiments
- Implement automatic rollback mechanisms
- Monitor system health during experiments

## Security Features in This Toolkit

- **Secret Rotation**: Automated rotation of HashiCorp Vault and AWS KMS secrets
- **Controlled Blast Radius**: Experiments target only labeled resources
- **Automatic Cleanup**: All chaos resources are cleaned up after experiments
- **Monitoring Integration**: Prometheus metrics for experiment monitoring 