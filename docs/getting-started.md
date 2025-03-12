# Getting Started with Chaos Engineering Platform

This guide will help you set up and start using the Chaos Engineering platform to improve the resilience of your systems.

## Prerequisites

Before you begin, ensure you have the following:

- Kubernetes cluster (v1.18+)
- `kubectl` CLI tool installed and configured
- `helm` v3+ installed
- Access to cloud provider accounts (if using cloud provider agents)
- Prometheus and Grafana for monitoring (recommended)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/chaos-engineering.git
cd chaos-engineering
```

### 2. Deploy the Control Plane

The control plane is the central component that manages chaos experiments and coordinates with agents.

```bash
./deploy.sh
```

This script will:
- Create the necessary namespace
- Deploy the control plane components
- Set up RBAC permissions
- Create persistent storage for experiment data

### 3. Set Up Vault for Secrets Management (Optional but Recommended)

For secure management of cloud provider credentials and other secrets:

```bash
./setup-vault.sh
```

This will:
- Deploy HashiCorp Vault
- Configure authentication
- Set up secret engines
- Migrate existing secrets to Vault

### 4. Configure Cloud Provider Access

If you plan to run experiments against cloud provider resources:

```bash
# For AWS
./configure-cloud-access.sh --provider aws --region us-west-2

# For GCP
./configure-cloud-access.sh --provider gcp --project my-project-id

# For Azure
./configure-cloud-access.sh --provider azure --subscription sub-id
```

### 5. Verify Installation

Check that all components are running:

```bash
kubectl get all -n chaos-engineering
```

You should see the control plane deployment, services, and agents running.

## Running Your First Experiment

### 1. Pod Failure Experiment

Let's start with a simple experiment that terminates a pod to test your application's resilience:

```bash
kubectl apply -f examples/pod-failure-experiment.yaml
```

This will create an experiment that targets pods with the label `app: payment-service` in the `production` namespace.

### 2. Monitor the Experiment

You can monitor the experiment through:

1. **Kubernetes logs**:
   ```bash
   kubectl logs -f deployment/chaos-control-plane -n chaos-engineering
   ```

2. **Grafana dashboard** (if configured):
   ```bash
   kubectl port-forward svc/grafana 3000:3000 -n monitoring
   ```
   Then open http://localhost:3000 and navigate to the Chaos Experiments dashboard.

3. **API**:
   ```bash
   kubectl port-forward svc/chaos-control-plane 8080:80 -n chaos-engineering
   curl http://localhost:8080/api/experiments
   ```

### 3. View Results

After the experiment completes, you can view the results:

```bash
kubectl get chaosresults -n chaos-engineering
```

Or through the API:

```bash
curl http://localhost:8080/api/results
```

## Creating Custom Experiments

### 1. Define the Experiment

Create a YAML file with your experiment definition:

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: custom-experiment
  namespace: chaos-engineering
spec:
  target:
    namespace: your-app-namespace
    selector:
      app: your-app
  action:
    type: podFailure  # or networkLatency, cpuStress, etc.
    duration: 5m
    count: 1
  schedule:
    cron: "0 1 * * 2"  # Every Tuesday at 1 AM
  monitoring:
    prometheus:
      endpoint: http://prometheus.monitoring:9090
```

### 2. Apply the Experiment

```bash
kubectl apply -f your-experiment.yaml
```

## Common Workflows

### Scheduling Regular Experiments

For continuous resilience testing, schedule experiments to run regularly:

```yaml
spec:
  schedule:
    cron: "0 1 * * 2"  # Every Tuesday at 1 AM
```

### Testing Microservice Resilience

To test how your microservices handle dependency failures:

1. Create experiments that target each dependency
2. Monitor the impact on your service
3. Implement resilience patterns (circuit breakers, retries, etc.)
4. Re-run experiments to verify improvements

### Game Days

Organize "Game Days" where teams deliberately run chaos experiments in a controlled environment:

1. Define the scope and goals
2. Prepare monitoring and alerting
3. Run progressively more complex experiments
4. Document findings and improvements

## Troubleshooting

### Common Issues

1. **Experiment not starting**:
   - Check control plane logs
   - Verify RBAC permissions
   - Ensure target pods exist

2. **Agent connection issues**:
   - Check network policies
   - Verify agent is running
   - Check agent logs

3. **Cloud provider experiments failing**:
   - Verify credentials in Vault
   - Check cloud provider permissions
   - Ensure agent has access to Vault

### Getting Help

- Check the [documentation](https://github.com/yourusername/chaos-engineering/docs)
- Open an issue on GitHub
- Join the community chat

## Next Steps

- Explore different [experiment types](experiment-types.md)
- Set up [monitoring and alerting](monitoring.md)
- Learn about the [API](api-reference.md)
- Implement [automated remediation](remediation.md)

By following this guide, you should have a functioning Chaos Engineering platform and be able to run basic experiments to test your system's resilience. 