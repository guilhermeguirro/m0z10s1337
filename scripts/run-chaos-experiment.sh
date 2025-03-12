#!/bin/bash

# Script to run and monitor chaos experiments
# Usage: ./run-chaos-experiment.sh <experiment-file> <duration-in-minutes>

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <experiment-file> <duration-in-minutes>"
    echo "Example: $0 ../manifests/pod-failure.yaml 5"
    exit 1
fi

EXPERIMENT_FILE=$1
DURATION_MINUTES=$2
NAMESPACE=${3:-default}

# Check if the experiment file exists
if [ ! -f "$EXPERIMENT_FILE" ]; then
    echo "Error: Experiment file $EXPERIMENT_FILE not found"
    exit 1
fi

# Extract experiment name from the file
EXPERIMENT_NAME=$(grep "name:" "$EXPERIMENT_FILE" | head -n 1 | awk '{print $2}')
EXPERIMENT_TYPE=$(grep "kind:" "$EXPERIMENT_FILE" | awk '{print $2}')

echo "=== Starting Chaos Experiment ==="
echo "Type: $EXPERIMENT_TYPE"
echo "Name: $EXPERIMENT_NAME"
echo "Duration: $DURATION_MINUTES minutes"
echo "Target Namespace: $NAMESPACE"

# Apply the chaos experiment
kubectl apply -f "$EXPERIMENT_FILE"
echo "Experiment applied successfully"

# Set up monitoring
echo "Setting up monitoring..."
kubectl port-forward -n default svc/prometheus 9090:9090 &
PROMETHEUS_PID=$!
echo "Prometheus port forwarding started (PID: $PROMETHEUS_PID)"

# Wait for the specified duration
echo "Experiment running for $DURATION_MINUTES minutes..."
sleep $(($DURATION_MINUTES * 60))

# Check the status of the pods in the target namespace
echo "=== Pod Status After Experiment ==="
kubectl get pods -n "$NAMESPACE"

# Check for any errors in the logs
echo "=== Checking for errors in the logs ==="
kubectl logs -n chaos-testing -l app.kubernetes.io/component=controller-manager --tail=100 | grep -i error || echo "No errors found in chaos controller logs"

# Clean up the experiment
echo "=== Cleaning Up ==="
kubectl delete -f "$EXPERIMENT_FILE"
echo "Experiment deleted"

# Kill the port forwarding process
if [ -n "$PROMETHEUS_PID" ]; then
    kill $PROMETHEUS_PID
    echo "Prometheus port forwarding stopped"
fi

echo "=== Chaos Experiment Completed ===" 