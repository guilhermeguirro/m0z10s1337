# Kubernetes Chaos Engineering

A comprehensive toolkit for testing the resilience of Kubernetes applications through controlled chaos experiments.

## Overview

This project provides tools and scripts to perform chaos engineering experiments on Kubernetes clusters. By introducing controlled failures and observing how systems respond, we can build more resilient applications.

## Features

- **Pod Chaos**: Terminate, pause, or stress test pods
- **Network Chaos**: Introduce latency, packet loss, or network partitions
- **Resource Chaos**: Simulate CPU/memory pressure
- **I/O Chaos**: Simulate disk I/O pressure
- **State Chaos**: Corrupt or manipulate application state
- **Automated Resilience Testing**: Scripts to automate chaos experiments

## Prerequisites

- Kubernetes cluster (1.16+)
- kubectl configured to access your cluster
- Helm (optional, for installing chaos tools)
- Prometheus and Grafana for monitoring (optional)

## 🚀 Getting Started

### Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/chaos-engineering.git
   cd chaos-engineering
   ```

2. Install Chaos Mesh (a chaos engineering platform for Kubernetes):
   ```
   kubectl create ns chaos-testing
   helm repo add chaos-mesh https://charts.chaos-mesh.org
   helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing
   ```

### Running Experiments

#### Pod Failure Experiment

```bash
kubectl apply -f manifests/pod-failure.yaml
```

This will randomly kill pods in the specified namespace and observe how the system recovers.

#### Network Latency Experiment

```bash
kubectl apply -f manifests/network-latency.yaml
```

This will introduce network latency between services to test timeout handling and retry mechanisms.

## Project Structure

- `scripts/`: Automation scripts for chaos experiments
- `manifests/`: Kubernetes manifests for chaos experiments
- `docs/`: Documentation and experiment results

## Monitoring Chaos Experiments

For effective chaos engineering, it's essential to monitor your applications during experiments. We recommend:

1. Prometheus for metrics collection
2. Grafana for visualization
3. Alertmanager for alerting

## Best Practices

1. **Start Small**: Begin with simple experiments in non-production environments
2. **Define Steady State**: Clearly define what "normal" looks like before experiments
3. **Minimize Blast Radius**: Limit the scope of experiments
4. **Automate Experiments**: Use CI/CD to regularly run chaos experiments
5. **Learn and Improve**: Document findings and improve system resilience

## License

MIT 