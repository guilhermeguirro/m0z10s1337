# Chaos Engineering Experiment Types

This document describes the various types of chaos experiments supported by the Chaos Engineering platform. Each experiment type is designed to test different aspects of your system's resilience.

## Overview

The platform supports experiments across three main layers:

1. **Infrastructure Layer**: Tests resilience against infrastructure failures
2. **Network Layer**: Tests resilience against network issues
3. **Application Layer**: Tests resilience against application-level failures

## Infrastructure Layer Experiments

### Pod Failure

Terminates pods to simulate container crashes, node failures, or evictions.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: pod-failure-test
spec:
  target:
    namespace: production
    selector:
      app: payment-service
  action:
    type: podFailure
    mode: one  # one, fixed, random, all
    count: 1   # number of pods to terminate (for fixed mode)
    duration: 5m
    interval: 10s  # time between pod terminations
    gracePeriod: 0  # grace period for pod termination
```

**Parameters:**
- `mode`: How to select pods (one, fixed, random, all)
- `count`: Number of pods to terminate (for fixed mode)
- `duration`: How long the experiment runs
- `interval`: Time between pod terminations
- `gracePeriod`: Grace period for pod termination

**Use Cases:**
- Test service resilience to pod failures
- Verify auto-healing mechanisms
- Test load balancing and failover

### Node Failure

Simulates node failures by cordoning, draining, or shutting down nodes.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: node-failure-test
spec:
  target:
    nodeSelector:
      kubernetes.io/role: worker
  action:
    type: nodeFailure
    mode: one  # one, fixed, random
    count: 1
    duration: 10m
    drainTimeout: 30s
```

**Parameters:**
- `mode`: How to select nodes
- `count`: Number of nodes to affect
- `duration`: How long the experiment runs
- `drainTimeout`: Timeout for draining pods

**Use Cases:**
- Test application resilience to node failures
- Verify node auto-scaling
- Test pod rescheduling

### Resource Exhaustion

Consumes CPU, memory, disk, or other resources to simulate resource exhaustion.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: cpu-stress-test
spec:
  target:
    namespace: production
    selector:
      app: api-gateway
  action:
    type: resourceExhaustion
    resource: cpu  # cpu, memory, disk, io
    value: 80      # percentage
    duration: 15m
```

**Parameters:**
- `resource`: Resource to exhaust (cpu, memory, disk, io)
- `value`: Percentage or absolute value
- `duration`: How long the experiment runs

**Use Cases:**
- Test application behavior under resource pressure
- Verify resource limits and requests
- Test auto-scaling based on resource usage

### Cloud Provider Experiments

#### Instance Termination

Terminates cloud provider instances to simulate instance failures.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: ec2-termination-test
spec:
  target:
    provider: aws
    selector:
      tags:
        role: api-server
  action:
    type: instanceTermination
    count: 1
    duration: 30m
```

**Parameters:**
- `provider`: Cloud provider (aws, gcp, azure)
- `count`: Number of instances to terminate
- `duration`: How long the experiment runs

**Use Cases:**
- Test resilience to instance failures
- Verify auto-scaling groups
- Test instance recovery

#### Zone Outage

Simulates an availability zone outage by terminating or isolating resources in a zone.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: zone-outage-test
spec:
  target:
    provider: aws
    zone: us-west-2a
  action:
    type: zoneOutage
    duration: 20m
```

**Parameters:**
- `provider`: Cloud provider
- `zone`: Availability zone
- `duration`: How long the experiment runs

**Use Cases:**
- Test multi-zone resilience
- Verify zone failover mechanisms
- Test disaster recovery procedures

## Network Layer Experiments

### Network Latency

Injects latency into network connections.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: api-latency-test
spec:
  target:
    namespace: production
    selector:
      app: api-gateway
  action:
    type: networkLatency
    latency: 500ms
    jitter: 50ms
    duration: 10m
    percentage: 50  # percentage of traffic affected
```

**Parameters:**
- `latency`: Amount of latency to inject
- `jitter`: Variation in latency
- `duration`: How long the experiment runs
- `percentage`: Percentage of traffic affected

**Use Cases:**
- Test application behavior with slow network
- Verify timeout configurations
- Test user experience degradation

### Packet Loss

Drops a percentage of network packets.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: packet-loss-test
spec:
  target:
    namespace: production
    selector:
      app: streaming-service
  action:
    type: packetLoss
    percentage: 10
    duration: 5m
```

**Parameters:**
- `percentage`: Percentage of packets to drop
- `duration`: How long the experiment runs

**Use Cases:**
- Test application resilience to unreliable networks
- Verify retry mechanisms
- Test streaming applications

### DNS Failure

Simulates DNS resolution failures.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: dns-failure-test
spec:
  target:
    namespace: production
    selector:
      app: web-frontend
  action:
    type: dnsFailure
    domains: ["api.example.com", "db.example.com"]
    duration: 5m
```

**Parameters:**
- `domains`: List of domains to affect
- `duration`: How long the experiment runs

**Use Cases:**
- Test application behavior with DNS failures
- Verify DNS caching
- Test service discovery resilience

### Connection Interruption

Interrupts network connections.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: connection-interruption-test
spec:
  target:
    namespace: production
    selector:
      app: payment-service
  action:
    type: connectionInterruption
    ports: [80, 443]
    duration: 5m
    interval: 30s
```

**Parameters:**
- `ports`: List of ports to affect
- `duration`: How long the experiment runs
- `interval`: Time between interruptions

**Use Cases:**
- Test connection pooling
- Verify reconnection logic
- Test circuit breakers

## Application Layer Experiments

### API Errors

Injects errors into API responses.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: api-error-test
spec:
  target:
    namespace: production
    selector:
      app: api-gateway
  action:
    type: apiErrors
    errorRate: 20
    errorCodes: [500, 503]
    duration: 5m
    endpoints: ["/api/users", "/api/orders"]
```

**Parameters:**
- `errorRate`: Percentage of requests to affect
- `errorCodes`: HTTP error codes to return
- `duration`: How long the experiment runs
- `endpoints`: List of endpoints to affect

**Use Cases:**
- Test error handling
- Verify fallback mechanisms
- Test user experience with errors

### Dependency Failures

Simulates failures in service dependencies.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: dependency-failure-test
spec:
  target:
    namespace: production
    selector:
      app: order-service
  action:
    type: dependencyFailure
    dependencies: ["payment-service", "inventory-service"]
    failureMode: timeout  # timeout, error, unavailable
    duration: 10m
```

**Parameters:**
- `dependencies`: List of dependencies to affect
- `failureMode`: Type of failure (timeout, error, unavailable)
- `duration`: How long the experiment runs

**Use Cases:**
- Test service resilience to dependency failures
- Verify circuit breakers
- Test graceful degradation

### Database Query Delays

Injects delays into database queries.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: db-delay-test
spec:
  target:
    namespace: production
    selector:
      app: user-service
  action:
    type: dbQueryDelay
    delay: 1s
    percentage: 30
    duration: 15m
    queryTypes: ["SELECT", "INSERT"]
```

**Parameters:**
- `delay`: Amount of delay to inject
- `percentage`: Percentage of queries to affect
- `duration`: How long the experiment runs
- `queryTypes`: Types of queries to affect

**Use Cases:**
- Test application behavior with slow database
- Verify connection pool settings
- Test query timeout handling

### Cache Invalidation

Forces cache invalidation or bypasses caches.

```yaml
apiVersion: chaos.example.com/v1
kind: ChaosExperiment
metadata:
  name: cache-invalidation-test
spec:
  target:
    namespace: production
    selector:
      app: product-service
  action:
    type: cacheInvalidation
    cacheNames: ["product-cache", "price-cache"]
    invalidationRate: 100
    duration: 10m
```

**Parameters:**
- `cacheNames`: List of caches to affect
- `invalidationRate`: Percentage of cache to invalidate
- `duration`: How long the experiment runs

**Use Cases:**
- Test application behavior with cache misses
- Verify cache warming mechanisms
- Test performance without caching

## Experiment Scheduling

All experiments can be scheduled using the following options:

### One-time Schedule

```yaml
spec:
  schedule:
    timeWindow:
      start: "2023-06-01T01:00:00Z"
      end: "2023-06-01T02:00:00Z"
```

### Recurring Schedule

```yaml
spec:
  schedule:
    cron: "0 1 * * 2"  # Every Tuesday at 1 AM
    timeZone: "UTC"
```

### Day-of-Week Schedule

```yaml
spec:
  schedule:
    daysOfWeek:
      - Monday
      - Wednesday
    timeOfDay: "01:00"
    timeZone: "America/New_York"
```

## Monitoring and Validation

All experiments can include monitoring and validation criteria:

```yaml
spec:
  monitoring:
    prometheus:
      endpoint: "http://prometheus.monitoring:9090"
      queries:
        - name: errorRate
          query: 'sum(rate(http_requests_total{status=~"5..",service="payment-service"}[1m])) / sum(rate(http_requests_total{service="payment-service"}[1m])) * 100'
          threshold: 5.0
          operator: lt
    alerts:
      - name: HighErrorRate
        threshold: 5
        duration: 1m
  statusChecks:
    - type: http
      endpoint: "https://api.example.com/health"
      expectedStatus: 200
      interval: 10s
      timeout: 5s
      failureThreshold: 3
```

## Cleanup and Results

Experiments can specify cleanup actions and result handling:

```yaml
spec:
  cleanup:
    enabled: true
    deleteNamespace: false
    restoreState: true
  results:
    storeInCluster: true
    exportMetrics: true
    notifyOnCompletion: true
    notifyOnFailure: true
    recipients:
      - type: slack
        channel: "#chaos-experiments"
      - type: email
        address: "team@example.com"
```

## Creating Custom Experiment Types

The platform supports creating custom experiment types through the API. See the [API Reference](api-reference.md) for details on how to define and register custom experiment types.

## Best Practices

1. **Start Small**: Begin with simple experiments and gradually increase complexity
2. **Define Hypotheses**: Clearly define what you expect to happen
3. **Set Blast Radius**: Limit the scope of experiments to minimize impact
4. **Monitor Closely**: Set up comprehensive monitoring for all experiments
5. **Automate Remediation**: Implement automated rollback for failed experiments
6. **Document Results**: Keep a record of all experiments and their outcomes

By understanding the different experiment types available, you can design a comprehensive chaos engineering program that tests all aspects of your system's resilience. 