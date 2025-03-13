# Advanced Chaos Engineering Platform

This repository contains a comprehensive chaos engineering platform for testing the resilience of Kubernetes applications. The platform includes various chaos experiments, monitoring tools, and visualization dashboards.

## Architecture

The platform consists of the following components:

- **Resilient Application**: A sample application deployed with multiple replicas to test resilience
- **Chaos Testing Framework**: Using Chaos Mesh to inject failures and perturbations
- **Monitoring Stack**: Prometheus and Grafana for observing system behavior during chaos
- **Horizontal Pod Autoscaler**: For automatic scaling based on resource utilization
- **Custom Dashboards**: For visualizing the effects of chaos experiments

## Available Chaos Experiments

The following chaos experiments are available:

1. **Network Delay**: Introduces latency in network communication
2. **Pod Failure**: Randomly kills pods to test recovery
3. **CPU Stress**: Simulates high CPU load
4. **Memory Stress**: Simulates memory pressure
5. **I/O Chaos**: Introduces latency in disk operations
6. **Chaos Workflow**: Orchestrates multiple chaos experiments in sequence

## Running Chaos Experiments

### Quick Start

The easiest way to run the chaos experiments is to use the provided wrapper script:

```bash
./run-chaos.sh
```

This script will:
1. Set up a Python virtual environment if it doesn't exist
2. Install the required dependencies
3. Run the chaos suite with the provided arguments

### Direct Python Execution

Alternatively, you can run the Python script directly if you have the dependencies installed:

```bash
./run_chaos_suite.py
```

The script will:
1. Apply all individual chaos experiments
2. Monitor the pods during chaos
3. Apply the chaos workflow
4. Check the status of experiments after completion
5. Generate a report (if output directory is specified)

### Advanced Usage

The script supports several command-line options:

```bash
usage: run_chaos_suite.py [-h] [--duration DURATION] [--output-dir OUTPUT_DIR] [--verbose]
                         [--continue-on-error] [--no-cleanup] [--auto-cleanup]

Run chaos engineering experiments on Kubernetes

optional arguments:
  -h, --help            show this help message and exit
  --duration DURATION   Duration in seconds to wait for experiments to complete (default: 240)
  --output-dir OUTPUT_DIR
                        Directory to store logs and reports (default: None)
  --verbose             Enable verbose output (default: False)
  --continue-on-error   Continue execution even if a command fails (default: False)
  --no-cleanup          Do not clean up experiments after completion (default: False)
  --auto-cleanup        Automatically clean up without confirmation (default: False)
```

Example with options:

```bash
./run-chaos.sh --duration 300 --output-dir ./reports --verbose --auto-cleanup
```

### Dependencies

The Python script requires the following dependencies:
- Python 3.6+
- PyYAML
- Kubernetes Python client

These dependencies are automatically installed by the wrapper script in a virtual environment.

## Monitoring Chaos Experiments

The platform includes a custom Grafana dashboard for monitoring the effects of chaos experiments. To import the dashboard:

1. Access Grafana at http://localhost:3000
2. Navigate to Dashboards > Import
3. Upload the `chaos-dashboard.json` file
4. Select the Prometheus data source

The dashboard includes the following panels:
- CPU Usage During Chaos
- Memory Usage During Chaos
- Network Traffic During Chaos
- Pod Restarts During Chaos
- API Response Time During Chaos
- Pod Status During Chaos

## Chaos Experiment Configurations

### Network Delay Chaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-delay-demo
  namespace: chaos-testing
spec:
  selector:
    namespaces:
      - default
    labelSelectors:
      app: resilient-app
  mode: all
  action: delay
  duration: "30s"
  delay:
    latency: "200ms"
    correlation: "25"
    jitter: "50ms"
```

### Pod Failure Chaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-demo
  namespace: chaos-testing
spec:
  selector:
    namespaces:
      - default
    labelSelectors:
      app: resilient-app
  mode: one
  action: pod-failure
  duration: "60s"
```

### CPU Stress Chaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: cpu-stress-demo
  namespace: chaos-testing
spec:
  selector:
    namespaces:
      - default
    labelSelectors:
      app: resilient-app
  mode: all
  stressors:
    cpu:
      workers: 2
      load: 75
  duration: "3m"
```

## Best Practices

1. **Start Small**: Begin with simple chaos experiments and gradually increase complexity
2. **Monitor Everything**: Use the provided dashboards to observe system behavior
3. **Define Success Criteria**: Establish clear metrics for what constitutes successful resilience
4. **Automate Recovery**: Ensure that your system can automatically recover from failures
5. **Document Findings**: Record observations and learnings from each chaos experiment

## Extending the Platform

To add new chaos experiments:

1. Create a new YAML file with the desired chaos configuration
2. Add the experiment to the `run_chaos_suite.py` script's `experiment_files` list
3. Update the chaos workflow to include the new experiment
4. Add relevant metrics to the Grafana dashboard

## Troubleshooting

If you encounter issues with the chaos experiments:

1. Check the status of the chaos experiments: `kubectl get podchaos,networkchaos,stresschaos,iochaos -n chaos-testing`
2. Check the logs of the chaos controller: `kubectl logs -n chaos-testing -l app.kubernetes.io/component=controller-manager`
3. Verify that the metrics server is running: `kubectl get deployment -n kube-system metrics-server`
4. Ensure that Prometheus and Grafana are properly configured
5. Run the script with the `--verbose` flag for more detailed output 