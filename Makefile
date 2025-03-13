.PHONY: install run-pod-failure run-network-latency run-cpu-stress run-memory-stress run-secret-rotation clean help security-scan apply-network-policies run-chaos-suite

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

# Run CPU stress experiment
run-cpu-stress:
	./scripts/run-chaos-experiment.sh manifests/cpu-stress.yaml 5

# Run memory stress experiment
run-memory-stress:
	./scripts/run-chaos-experiment.sh manifests/memory-stress.yaml 5

# Run secret rotation experiment
run-secret-rotation:
	./scripts/rotate-secrets.sh default

# Run complete chaos suite
run-chaos-suite:
	./run-chaos.sh --verbose

# Clean up all chaos experiments
clean:
	kubectl delete podchaos --all -n chaos-testing || true
	kubectl delete networkchaos --all -n chaos-testing || true
	kubectl delete stresschaos --all -n chaos-testing || true
	kubectl delete iochaos --all -n chaos-testing || true
	kubectl delete workflow --all -n chaos-testing || true

# Security scan
security-scan:
	@echo "Running security scans..."
	@echo "Scanning shell scripts..."
	find ./scripts -type f -name "*.sh" -exec shellcheck {} \;
	@echo "Scanning Kubernetes manifests..."
	kubectl auth can-i --list
	@echo "Scanning for exposed secrets..."
	find . -type f -not -path "./.git/*" -exec grep -l "BEGIN.*PRIVATE KEY" {} \;
	@echo "Checking container security..."
	docker scout cves ghcr.io/guilhermeguirro/chaos-engineering:latest || true

# Apply network policies
apply-network-policies:
	kubectl apply -f manifests/network-policies.yaml

# Help command
help:
	@echo "Available targets:"
	@echo "  install              - Install Chaos Mesh and dependencies"
	@echo "  run-pod-failure     - Run pod failure experiment"
	@echo "  run-network-latency - Run network latency experiment"
	@echo "  run-cpu-stress      - Run CPU stress experiment"
	@echo "  run-memory-stress   - Run memory stress experiment"
	@echo "  run-secret-rotation - Run secret rotation experiment"
	@echo "  run-chaos-suite     - Run complete chaos experiment suite"
	@echo "  security-scan       - Run security scans"
	@echo "  apply-network-policies - Apply network policies"
	@echo "  clean               - Clean up all chaos experiments"
	@echo "Available commands:"
	@echo "  make install            - Install Chaos Mesh"
	@echo "  make run-pod-failure    - Run pod failure experiment"
	@echo "  make run-network-latency - Run network latency experiment"
	@echo "  make run-cpu-stress     - Run CPU stress experiment"
	@echo "  make run-memory-stress  - Run memory stress experiment"
	@echo "  make run-secret-rotation - Run secret rotation experiment"
	@echo "  make run-chaos-suite    - Run complete chaos experiment suite"
	@echo "  make clean              - Clean up all chaos experiments"
