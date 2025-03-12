# Contributing to the Chaos Engineering Platform

Thank you for your interest in contributing to the Chaos Engineering Platform! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Contribution Workflow](#contribution-workflow)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Issue Reporting](#issue-reporting)
- [Feature Requests](#feature-requests)
- [Community](#community)

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. By participating, you are expected to uphold this code. Please report unacceptable behavior to [conduct@example.com](mailto:conduct@example.com).

## Getting Started

Before you begin:

1. Ensure you have read the [README.md](README.md) to understand the project's purpose and architecture
2. Check the [documentation](docs/) to familiarize yourself with the platform's components
3. Look through the [open issues](https://github.com/example/chaos-engineering/issues) to see if there's something you'd like to work on

## Development Environment

### Prerequisites

- Go 1.18 or higher
- Docker and Docker Compose
- Kubernetes cluster (local like Minikube or Kind, or remote)
- Helm 3.x
- kubectl

### Setting Up Your Environment

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/chaos-engineering.git
   cd chaos-engineering
   ```
3. Add the original repository as an upstream remote:
   ```bash
   git remote add upstream https://github.com/example/chaos-engineering.git
   ```
4. Install development dependencies:
   ```bash
   make dev-setup
   ```
5. Start the development environment:
   ```bash
   make dev-start
   ```

## Contribution Workflow

1. Create a new branch for your contribution:
   ```bash
   git checkout -b feature-branch
   ```
2. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "Description of the changes"
   ```
3. Push your changes to your fork:
   ```bash
   git push origin feature-branch
   ```
4. Create a pull request from your fork to the original repository.

## Pull Request Guidelines

- Ensure your changes are well-documented and follow the coding standards
- Include tests for your changes
- Use clear and concise commit messages

## Coding Standards

- Follow the Go coding style guidelines
- Use meaningful variable names and comments
- Keep functions and methods small and focused

## Testing Guidelines

- Write tests for your changes
- Ensure all tests pass before merging
- Use a testing framework like testify

## Documentation

- Update the README.md and any relevant documentation
- Use Markdown for documentation

## Issue Reporting

- Use the GitHub issue tracker to report bugs and feature requests
- Provide clear and concise descriptions of the issue
- Include steps to reproduce the issue

## Feature Requests

- Use the GitHub issue tracker to request new features
- Provide a clear and concise description of the feature
- Include any relevant context or use cases

## Community

- Join the project's community on GitHub
- Participate in discussions and provide feedback
- Help others with issues and questions 