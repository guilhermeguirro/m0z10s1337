.PHONY: install run-pod-failure run-network-latency clean help

# Install Chaos Mesh
install:
	kubectl create ns chaos-testing || true
	helm repo add chaos-mesh https://charts.chaos-mesh.org
	helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing

# Run pod failure experiment
run-pod-failure:
	./scripts/run-chaos-experiment.sh manifests/pod-failure.yaml 5

# Run network latency experiment
run-network-latency:
	./scripts/run-chaos-experiment.sh manifests/network-latency.yaml 5

# Clean up all chaos experiments
clean:
	kubectl delete podchaos --all -n chaos-testing || true
	kubectl delete networkchaos --all -n chaos-testing || true

# Help command
help:
	@echo "Available commands:"
	@echo "  make install            - Install Chaos Mesh"
	@echo "  make run-pod-failure    - Run pod failure experiment"
	@echo "  make run-network-latency - Run network latency experiment"
	@echo "  make clean              - Clean up all chaos experiments"
