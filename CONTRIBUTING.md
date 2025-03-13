# Contributing to Kubernetes Chaos Engineering Toolkit

Thank you for your interest in contributing to the Kubernetes Chaos Engineering Toolkit! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

If you discover a security vulnerability, please follow the instructions in our [Security Policy](SECURITY.md) rather than opening a public issue.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork to your local machine
3. Create a new branch for your changes
4. Make your changes
5. Push your changes to your fork
6. Submit a pull request

## Development Environment

### Prerequisites

- Kubernetes cluster (1.16+)
- kubectl configured to access your cluster
- Helm (for installing chaos tools)
- Docker (for building container images)
- ShellCheck (for linting shell scripts)

### Setting Up

```bash
# Clone the repository
git clone https://github.com/guilhermeguirro/chaos-engineering.git
cd chaos-engineering

# Install dependencies
make install
```

## Pull Request Process

1. Ensure your code follows the project's style guidelines
2. Update documentation as necessary
3. Add tests for new features
4. Ensure all tests pass
5. Make sure your code lints without errors
6. Update the README.md with details of changes if applicable
7. The PR should work for all supported Kubernetes versions
8. Include a descriptive commit message

## DevSecOps Guidelines

### Security Best Practices

- Never commit secrets or credentials
- Use non-root users in containers
- Minimize container image size
- Apply the principle of least privilege
- Scan code and dependencies for vulnerabilities

### Code Quality

- Write clear, commented code
- Include error handling
- Add appropriate logging
- Write unit and integration tests
- Follow shell scripting best practices

### Documentation

- Document all new features
- Update existing documentation as needed
- Include examples where appropriate
- Document security considerations

## Testing

Before submitting a PR, please run the following tests:

```bash
# Lint shell scripts
find ./scripts -type f -name "*.sh" -exec shellcheck {} \;

# Test chaos experiments
make run-pod-failure
make run-network-latency
make run-secret-rotation
```

## Releasing

Releases are managed by the project maintainers. If you believe a new release is needed, please open an issue.

## Questions?

If you have any questions or need help, please open an issue or contact the maintainers at guilherme.guirro@example.com. 