# Vault Integration for Chaos Engineering Platform

This document explains how HashiCorp Vault is integrated with the Chaos Engineering platform for secure secrets management.

## Overview

The Chaos Engineering platform uses HashiCorp Vault to securely store and manage sensitive credentials, such as cloud provider API keys. This integration provides several benefits:

- **Secure Storage**: All secrets are encrypted at rest and in transit
- **Dynamic Credentials**: Support for generating short-lived, just-in-time credentials
- **Access Control**: Fine-grained policies to control who can access which secrets
- **Audit Trail**: Comprehensive logging of all secret access
- **Automatic Rotation**: Support for automatic credential rotation

## Architecture

The integration uses the Vault Agent Injector, which runs as a sidecar container in the Chaos Engineering pods. The Vault Agent authenticates with Vault using Kubernetes service account tokens and injects the required secrets into the pod.

```
┌─────────────────────────────────────────────┐
│                                             │
│  Chaos Engineering Pod                      │
│                                             │
│  ┌─────────────┐        ┌───────────────┐  │
│  │             │        │               │  │
│  │ Application │◄───────┤  Vault Agent  │  │
│  │  Container  │        │   Sidecar     │  │
│  │             │        │               │  │
│  └─────────────┘        └───────┬───────┘  │
│                                 │           │
└─────────────────────────────────┼───────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │                 │
                         │  Vault Server   │
                         │                 │
                         └─────────────────┘
```

## Setup

The Vault integration is set up using the `setup-vault.sh` script, which:

1. Deploys Vault using Helm
2. Initializes and unseals Vault
3. Configures Kubernetes authentication
4. Creates policies and roles for the Chaos Engineering platform
5. Migrates existing secrets to Vault

To set up Vault, run:

```bash
./setup-vault.sh
```

## Secret Types

The following types of secrets are stored in Vault:

### AWS Credentials

Path: `chaos-engineering/aws`

```json
{
  "access_key_id": "AKIAXXXXXXXXXXXXXXXX",
  "secret_access_key": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "region": "us-west-2"
}
```

### GCP Credentials

Path: `chaos-engineering/gcp`

```json
{
  "credentials": "{ ... GCP service account JSON ... }"
}
```

### Azure Credentials

Path: `chaos-engineering/azure`

```json
{
  "client_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "client_secret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "tenant_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "subscription_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

## How It Works

1. When a pod starts, the Vault Agent Injector injects a Vault Agent sidecar container
2. The Vault Agent authenticates with Vault using the pod's Kubernetes service account token
3. The Vault Agent retrieves the required secrets and writes them to a shared volume
4. The application container reads the secrets from the shared volume
5. The Vault Agent periodically renews the secrets if they are dynamic

## Configuration

The Vault integration is configured using annotations on the pod template:

```yaml
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "chaos-engineering"
  vault.hashicorp.com/agent-inject-secret-aws: "chaos-engineering/data/aws"
  vault.hashicorp.com/agent-inject-template-aws: |
    {{- with secret "chaos-engineering/data/aws" -}}
    export AWS_ACCESS_KEY_ID="{{ .Data.data.access_key_id }}"
    export AWS_SECRET_ACCESS_KEY="{{ .Data.data.secret_access_key }}"
    export AWS_REGION="{{ .Data.data.region }}"
    {{- end -}}
```

## Accessing the Vault UI

To access the Vault UI, set up port forwarding:

```bash
kubectl -n vault port-forward svc/vault 8200:8200
```

Then open a browser and navigate to `http://localhost:8200`.

## Troubleshooting

### Vault Agent Logs

To view the Vault Agent logs:

```bash
kubectl -n chaos-engineering logs <pod-name> vault-agent-init
```

### Vault Server Logs

To view the Vault server logs:

```bash
kubectl -n vault logs vault-0
```

### Common Issues

1. **Authentication Failure**: Check that the service account has the correct permissions
2. **Secret Not Found**: Verify that the secret path is correct and the policy allows access
3. **Template Error**: Check the template syntax in the pod annotations

## Security Considerations

1. **Root Token**: The root token is stored in `vault-keys.json`. In a production environment, this should be securely stored and then revoked.
2. **Unseal Keys**: The unseal keys are stored in `vault-keys.json`. In a production environment, these should be securely stored and distributed among trusted individuals.
3. **TLS**: For production, enable TLS for Vault communication.
4. **Audit Logging**: Enable audit logging to track all secret access.

## Best Practices

1. **Least Privilege**: Grant only the minimum required permissions to each role
2. **Secret Rotation**: Regularly rotate static secrets
3. **Dynamic Secrets**: Use dynamic secrets where possible
4. **Monitoring**: Monitor Vault for unusual access patterns
5. **Backup**: Regularly backup Vault data

## References

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [Vault Agent Injector](https://www.vaultproject.io/docs/platform/k8s/injector)
- [Kubernetes Authentication Method](https://www.vaultproject.io/docs/auth/kubernetes) 