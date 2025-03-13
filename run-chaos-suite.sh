#!/bin/bash

# Run Chaos Engineering Suite
# This script applies various chaos experiments and monitors their effects

set -e

echo "===== Chaos Engineering Test Suite ====="
echo "Starting chaos experiments..."

# Ensure chaos-testing namespace exists
kubectl create namespace chaos-testing --dry-run=client -o yaml | kubectl apply -f -

# Apply the chaos experiments
echo "Applying network delay chaos..."
kubectl apply -f network-delay-chaos.yaml

echo "Applying pod failure chaos..."
kubectl apply -f pod-failure-chaos.yaml

echo "Applying CPU stress chaos..."
kubectl apply -f cpu-stress-chaos.yaml

echo "Applying memory stress chaos..."
kubectl apply -f memory-stress-chaos.yaml

echo "Applying I/O chaos..."
kubectl apply -f io-chaos.yaml

echo "All individual chaos experiments applied!"

# Wait for a moment to let the experiments start
sleep 5

# Monitor the pods during chaos
echo "Monitoring pods during chaos experiments..."
kubectl get pods -l app=resilient-app -w &
MONITOR_PID=$!

# Apply the workflow after individual experiments
echo "Applying chaos workflow..."
kubectl apply -f chaos-workflow.yaml

# Wait for the workflow to complete (4 minutes)
echo "Waiting for chaos workflow to complete (4 minutes)..."
sleep 240

# Kill the monitoring process
kill $MONITOR_PID

# Check the status of the chaos experiments
echo "Checking status of chaos experiments..."
kubectl get podchaos,networkchaos,stresschaos,iochaos -n chaos-testing

# Check the status of the workflow
echo "Checking status of chaos workflow..."
kubectl get workflow -n chaos-testing

echo "===== Chaos Engineering Test Suite Completed ====="

# Optional: Clean up
read -p "Do you want to clean up the chaos experiments? (y/n): " CLEANUP
if [[ "$CLEANUP" == "y" ]]; then
  echo "Cleaning up chaos experiments..."
  kubectl delete -f network-delay-chaos.yaml
  kubectl delete -f pod-failure-chaos.yaml
  kubectl delete -f cpu-stress-chaos.yaml
  kubectl delete -f memory-stress-chaos.yaml
  kubectl delete -f io-chaos.yaml
  kubectl delete -f chaos-workflow.yaml
  echo "Cleanup completed!"
fi 