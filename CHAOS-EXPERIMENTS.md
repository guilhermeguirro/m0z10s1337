# Chaos Experiments

This directory contains the YAML files for various chaos experiments that can be run against the resilient-app deployment.

## Available Experiments

1. **Network Delay Chaos**: Introduces latency in network communication
2. **Pod Failure Chaos**: Randomly kills pods to test recovery
3. **CPU Stress Chaos**: Simulates high CPU load
4. **Memory Stress Chaos**: Simulates memory pressure
5. **I/O Chaos**: Introduces latency in disk operations
6. **Chaos Workflow**: Orchestrates multiple chaos experiments in sequence

## Running Experiments

You can run the experiments using the provided wrapper script:

```bash
./run-chaos.sh
```

This script will:
1. Set up a Python virtual environment if it doesn't exist
2. Install the required dependencies
3. Run the chaos suite with the provided arguments

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

## Monitoring Experiments

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
- Pod Status During Chaos
- HPA Scaling During Chaos

## Experiment Details

### Network Delay Chaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-delay-chaos
  namespace: chaos-testing
spec:
  action: delay
  mode: one
  selector:
    namespaces:
      - default
    labelSelectors:
      app: resilient-app
  delay:
    latency: "200ms"
    correlation: "25"
    jitter: "50ms"
  duration: "60s"
```

### Pod Failure Chaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-failure-chaos
  namespace: chaos-testing
spec:
  action: pod-failure
  mode: one
  selector:
    namespaces:
      - default
    labelSelectors:
      app: resilient-app
  duration: "45s"
```

### CPU Stress Chaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: cpu-stress-chaos
  namespace: chaos-testing
spec:
  mode: one
  selector:
    namespaces:
      - default
    labelSelectors:
      app: resilient-app
  stressors:
    cpu:
      workers: 2
      load: 90
  duration: "90s"
```

### Memory Stress Chaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: memory-stress-chaos
  namespace: chaos-testing
spec:
  mode: one
  selector:
    namespaces:
      - default
    labelSelectors:
      app: resilient-app
  stressors:
    memory:
      workers: 2
      size: "512MB"
  duration: "75s"
```

### I/O Chaos

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: io-chaos
  namespace: chaos-testing
spec:
  action: latency
  mode: one
  selector:
    namespaces:
      - default
    labelSelectors:
      app: resilient-app
  volumePath: /
  path: "*"
  delay: "100ms"
  percent: 50
  duration: "60s"
```

## Best Practices

1. **Start Small**: Begin with simple chaos experiments and gradually increase complexity
2. **Monitor Everything**: Use the provided dashboards to observe system behavior
3. **Define Success Criteria**: Establish clear metrics for what constitutes successful resilience
4. **Automate Recovery**: Ensure that your system can automatically recover from failures
5. **Document Findings**: Record observations and learnings from each chaos experiment 