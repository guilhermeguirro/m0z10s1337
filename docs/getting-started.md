# Getting Started with Chaos Engineering

This guide will help you get started with chaos engineering experiments in your Kubernetes cluster.

## Prerequisites

Before you begin, make sure you have:

1. A running Kubernetes cluster (v1.16+)
2. kubectl configured to access your cluster
3. Helm installed (for deploying Chaos Mesh)

## Troubleshooting Common Issues

When working with chaos engineering tools, you may encounter some challenges. Here are solutions to common issues:

### 1. Kubernetes Connection Issues

If you see errors like:
```
The connection to the server was refused - did you specify the right host or port?
```

**Solution:**
- Ensure your Kubernetes cluster is running: `minikube status`
- If it's not running, start it: `minikube start`
- Verify your kubectl configuration: `kubectl config view`
- Make sure you're using the correct context: `kubectl config use-context <context-name>`

### 2. Chaos Mesh API Compatibility

If you encounter errors like:
```
Error from server (BadRequest): error when creating "manifests/pod-failure.yaml": PodChaos in version "v1alpha1" cannot be handled as a PodChaos: strict decoding error: unknown field "spec.paused", unknown field "spec.scheduler"
```

**Solution:**
- Different versions of Chaos Mesh support different API fields
- Remove unsupported fields from your manifests (like `scheduler` and `paused` in newer versions)
- Check the Chaos Mesh documentation for your specific version

### 3. Network Chaos Requirements

If you see errors related to network chaos experiments:
```
error while flushing ip sets: Kernel error received: set type not supported
```

**Solution:**
- Network chaos experiments require specific kernel modules and capabilities
- These may not be available in all Kubernetes environments (especially Minikube or Docker Desktop)
- Consider using a different type of chaos experiment or a more fully-featured Kubernetes environment
- For production testing, use a cloud provider's Kubernetes service which typically has better support

### 4. Target Application Not Found

If your chaos experiments don't seem to affect anything:

**Solution:**
- Verify that your selector matches your application: `kubectl get pods -l app=your-app-label`
- Ensure your application is deployed in the correct namespace
- Check that your application has the expected labels

### 5. Monitoring Issues

If you can't access Prometheus or other monitoring tools:

**Solution:**
- Verify that the port forwarding is working: `kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<remote-port>`
- Check if the service exists: `kubectl get svc -n <namespace>`
- Ensure there are no firewall rules blocking the connection

## Best Practices for Testing

Based on our experience, here are some best practices for testing your chaos engineering toolkit:

1. **Start with a Test Environment**: Always test in a non-production environment first
2. **Use a Dedicated Test Application**: Create a simple application specifically for testing chaos experiments
3. **Verify Experiment Effects**: Monitor your application during experiments to confirm they're having the expected impact
4. **Start Simple**: Begin with pod failure experiments before moving to more complex network or state chaos
5. **Document Results**: Keep track of what works and what doesn't in your specific environment

## LinkedIn Post (Updated)

🔥 Just released: Kubernetes Chaos Engineering Toolkit 🔥

I'm excited to share a project I've been working on: a comprehensive toolkit for testing the resilience of Kubernetes applications through controlled chaos experiments.

🧰 What's included:
• Pod failure experiments
• Network latency simulation
• Resource pressure testing
• Automated experiment scripts
• Simple Makefile interface
• Troubleshooting guide for common issues

Why chaos engineering? Because in distributed systems, failures are inevitable. The question isn't if they'll happen, but when—and how your application will respond.

This toolkit helps you proactively test your Kubernetes applications against common failure scenarios, building confidence in your system's resilience before real outages occur.

Check out my detailed article on Medium to learn more about the toolkit and how to get started with chaos engineering: [Medium Article Link]

GitHub repo: [GitHub Repo Link]

#Kubernetes #ChaosEngineering #DevOps #SRE #Resilience #CloudNative

---

Your project is now ready for sharing! The pod failure experiment works successfully, and while the network latency experiment has some limitations in Minikube, this is a common issue that you've now documented in your troubleshooting section.

Would you like me to help with anything else before you publish your project?
