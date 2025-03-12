# Chaos Engineering API Reference

This document provides a comprehensive reference for the Chaos Engineering platform's API. The API allows you to programmatically create, manage, and monitor chaos experiments.

## API Overview

The Chaos Engineering platform exposes a RESTful API that allows you to:

- Create and manage experiments
- Schedule experiments
- Monitor experiment progress
- Retrieve experiment results
- Manage experiment templates
- Configure platform settings

## Base URL

All API endpoints are relative to the base URL:

```
https://<control-plane-address>/api/v1
```

## Authentication

The API uses token-based authentication. Include the token in the `Authorization` header:

```
Authorization: Bearer <your-token>
```

To obtain a token, use the authentication endpoint:

```
POST /auth/token
```

Request body:
```json
{
  "username": "your-username",
  "password": "your-password"
}
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2023-06-01T12:00:00Z"
}
```

## API Endpoints

### Experiments

#### List Experiments

```
GET /experiments
```

Query parameters:
- `status` (optional): Filter by status (running, completed, failed, scheduled)
- `namespace` (optional): Filter by Kubernetes namespace
- `limit` (optional): Maximum number of results (default: 20)
- `offset` (optional): Pagination offset (default: 0)

Response:
```json
{
  "total": 42,
  "experiments": [
    {
      "id": "exp-123456",
      "name": "pod-failure-test",
      "status": "completed",
      "created_at": "2023-05-01T10:00:00Z",
      "started_at": "2023-05-01T10:05:00Z",
      "ended_at": "2023-05-01T10:10:00Z",
      "target": {
        "namespace": "production",
        "selector": {
          "app": "payment-service"
        }
      },
      "action": {
        "type": "podFailure",
        "mode": "one",
        "duration": "5m"
      }
    },
    // More experiments...
  ]
}
```

#### Get Experiment

```
GET /experiments/{id}
```

Response:
```json
{
  "id": "exp-123456",
  "name": "pod-failure-test",
  "status": "completed",
  "created_at": "2023-05-01T10:00:00Z",
  "started_at": "2023-05-01T10:05:00Z",
  "ended_at": "2023-05-01T10:10:00Z",
  "target": {
    "namespace": "production",
    "selector": {
      "app": "payment-service"
    }
  },
  "action": {
    "type": "podFailure",
    "mode": "one",
    "count": 1,
    "duration": "5m",
    "interval": "10s",
    "gracePeriod": 0
  },
  "results": {
    "affected_resources": [
      {
        "kind": "Pod",
        "name": "payment-service-5d4f8b9c76-2xvqz",
        "namespace": "production"
      }
    ],
    "metrics": [
      {
        "name": "availability",
        "value": 99.5,
        "unit": "percent"
      },
      {
        "name": "error_rate",
        "value": 2.3,
        "unit": "percent"
      }
    ],
    "events": [
      {
        "timestamp": "2023-05-01T10:05:00Z",
        "message": "Experiment started"
      },
      {
        "timestamp": "2023-05-01T10:05:10Z",
        "message": "Pod payment-service-5d4f8b9c76-2xvqz terminated"
      },
      {
        "timestamp": "2023-05-01T10:05:25Z",
        "message": "New pod payment-service-5d4f8b9c76-3ywrt created"
      },
      {
        "timestamp": "2023-05-01T10:10:00Z",
        "message": "Experiment completed"
      }
    ]
  }
}
```

#### Create Experiment

```
POST /experiments
```

Request body:
```json
{
  "name": "pod-failure-test",
  "target": {
    "namespace": "production",
    "selector": {
      "app": "payment-service"
    }
  },
  "action": {
    "type": "podFailure",
    "mode": "one",
    "count": 1,
    "duration": "5m",
    "interval": "10s",
    "gracePeriod": 0
  },
  "schedule": {
    "timeWindow": {
      "start": "2023-06-01T01:00:00Z",
      "end": "2023-06-01T02:00:00Z"
    }
  },
  "monitoring": {
    "prometheus": {
      "endpoint": "http://prometheus.monitoring:9090",
      "queries": [
        {
          "name": "errorRate",
          "query": "sum(rate(http_requests_total{status=~\"5..\",service=\"payment-service\"}[1m])) / sum(rate(http_requests_total{service=\"payment-service\"}[1m])) * 100",
          "threshold": 5.0,
          "operator": "lt"
        }
      ]
    }
  }
}
```

Response:
```json
{
  "id": "exp-123456",
  "name": "pod-failure-test",
  "status": "scheduled",
  "created_at": "2023-05-01T10:00:00Z"
}
```

#### Update Experiment

```
PUT /experiments/{id}
```

Request body: Same as create experiment

Response: Same as get experiment

#### Delete Experiment

```
DELETE /experiments/{id}
```

Response:
```json
{
  "message": "Experiment deleted successfully"
}
```

#### Start Experiment

```
POST /experiments/{id}/start
```

Response:
```json
{
  "id": "exp-123456",
  "status": "running",
  "started_at": "2023-05-01T10:05:00Z"
}
```

#### Stop Experiment

```
POST /experiments/{id}/stop
```

Response:
```json
{
  "id": "exp-123456",
  "status": "stopped",
  "ended_at": "2023-05-01T10:07:30Z"
}
```

#### Get Experiment Results

```
GET /experiments/{id}/results
```

Response:
```json
{
  "affected_resources": [
    {
      "kind": "Pod",
      "name": "payment-service-5d4f8b9c76-2xvqz",
      "namespace": "production"
    }
  ],
  "metrics": [
    {
      "name": "availability",
      "value": 99.5,
      "unit": "percent"
    },
    {
      "name": "error_rate",
      "value": 2.3,
      "unit": "percent"
    }
  ],
  "events": [
    {
      "timestamp": "2023-05-01T10:05:00Z",
      "message": "Experiment started"
    },
    {
      "timestamp": "2023-05-01T10:05:10Z",
      "message": "Pod payment-service-5d4f8b9c76-2xvqz terminated"
    },
    {
      "timestamp": "2023-05-01T10:05:25Z",
      "message": "New pod payment-service-5d4f8b9c76-3ywrt created"
    },
    {
      "timestamp": "2023-05-01T10:10:00Z",
      "message": "Experiment completed"
    }
  ]
}
```

### Templates

#### List Templates

```
GET /templates
```

Query parameters:
- `category` (optional): Filter by category (infrastructure, network, application)
- `limit` (optional): Maximum number of results (default: 20)
- `offset` (optional): Pagination offset (default: 0)

Response:
```json
{
  "total": 15,
  "templates": [
    {
      "id": "tmpl-123456",
      "name": "Pod Failure Template",
      "description": "Template for pod failure experiments",
      "category": "infrastructure",
      "created_at": "2023-04-01T10:00:00Z",
      "action": {
        "type": "podFailure"
      }
    },
    // More templates...
  ]
}
```

#### Get Template

```
GET /templates/{id}
```

Response:
```json
{
  "id": "tmpl-123456",
  "name": "Pod Failure Template",
  "description": "Template for pod failure experiments",
  "category": "infrastructure",
  "created_at": "2023-04-01T10:00:00Z",
  "action": {
    "type": "podFailure",
    "mode": "one",
    "count": 1,
    "duration": "5m",
    "interval": "10s",
    "gracePeriod": 0
  },
  "parameters": [
    {
      "name": "namespace",
      "description": "Target namespace",
      "type": "string",
      "required": true
    },
    {
      "name": "app",
      "description": "Application selector",
      "type": "string",
      "required": true
    },
    {
      "name": "duration",
      "description": "Experiment duration",
      "type": "string",
      "default": "5m"
    }
  ]
}
```

#### Create Template

```
POST /templates
```

Request body:
```json
{
  "name": "Pod Failure Template",
  "description": "Template for pod failure experiments",
  "category": "infrastructure",
  "action": {
    "type": "podFailure",
    "mode": "one",
    "count": 1,
    "duration": "5m",
    "interval": "10s",
    "gracePeriod": 0
  },
  "parameters": [
    {
      "name": "namespace",
      "description": "Target namespace",
      "type": "string",
      "required": true
    },
    {
      "name": "app",
      "description": "Application selector",
      "type": "string",
      "required": true
    },
    {
      "name": "duration",
      "description": "Experiment duration",
      "type": "string",
      "default": "5m"
    }
  ]
}
```

Response:
```json
{
  "id": "tmpl-123456",
  "name": "Pod Failure Template",
  "created_at": "2023-05-01T10:00:00Z"
}
```

#### Update Template

```
PUT /templates/{id}
```

Request body: Same as create template

Response: Same as get template

#### Delete Template

```
DELETE /templates/{id}
```

Response:
```json
{
  "message": "Template deleted successfully"
}
```

#### Create Experiment from Template

```
POST /templates/{id}/experiments
```

Request body:
```json
{
  "name": "pod-failure-test",
  "parameters": {
    "namespace": "production",
    "app": "payment-service",
    "duration": "10m"
  },
  "schedule": {
    "timeWindow": {
      "start": "2023-06-01T01:00:00Z",
      "end": "2023-06-01T02:00:00Z"
    }
  }
}
```

Response:
```json
{
  "id": "exp-123456",
  "name": "pod-failure-test",
  "status": "scheduled",
  "created_at": "2023-05-01T10:00:00Z"
}
```

### Schedules

#### List Schedules

```
GET /schedules
```

Query parameters:
- `status` (optional): Filter by status (active, completed, cancelled)
- `limit` (optional): Maximum number of results (default: 20)
- `offset` (optional): Pagination offset (default: 0)

Response:
```json
{
  "total": 10,
  "schedules": [
    {
      "id": "sched-123456",
      "experiment_id": "exp-123456",
      "status": "active",
      "created_at": "2023-05-01T10:00:00Z",
      "next_run": "2023-06-01T01:00:00Z",
      "time_window": {
        "start": "2023-06-01T01:00:00Z",
        "end": "2023-06-01T02:00:00Z"
      }
    },
    // More schedules...
  ]
}
```

#### Get Schedule

```
GET /schedules/{id}
```

Response:
```json
{
  "id": "sched-123456",
  "experiment_id": "exp-123456",
  "status": "active",
  "created_at": "2023-05-01T10:00:00Z",
  "next_run": "2023-06-01T01:00:00Z",
  "time_window": {
    "start": "2023-06-01T01:00:00Z",
    "end": "2023-06-01T02:00:00Z"
  }
}
```

#### Update Schedule

```
PUT /schedules/{id}
```

Request body:
```json
{
  "time_window": {
    "start": "2023-07-01T01:00:00Z",
    "end": "2023-07-01T02:00:00Z"
  }
}
```

Response: Same as get schedule

#### Delete Schedule

```
DELETE /schedules/{id}
```

Response:
```json
{
  "message": "Schedule deleted successfully"
}
```

### Targets

#### List Targets

```
GET /targets
```

Query parameters:
- `namespace` (optional): Filter by Kubernetes namespace
- `kind` (optional): Filter by resource kind (Pod, Deployment, etc.)
- `limit` (optional): Maximum number of results (default: 20)
- `offset` (optional): Pagination offset (default: 0)

Response:
```json
{
  "total": 25,
  "targets": [
    {
      "kind": "Deployment",
      "name": "payment-service",
      "namespace": "production",
      "labels": {
        "app": "payment-service",
        "tier": "backend"
      },
      "pods": 3,
      "ready_pods": 3
    },
    // More targets...
  ]
}
```

#### Get Target

```
GET /targets/{namespace}/{kind}/{name}
```

Response:
```json
{
  "kind": "Deployment",
  "name": "payment-service",
  "namespace": "production",
  "labels": {
    "app": "payment-service",
    "tier": "backend"
  },
  "pods": 3,
  "ready_pods": 3,
  "containers": [
    {
      "name": "payment-service",
      "image": "example/payment-service:v1.2.3",
      "ready": true
    },
    {
      "name": "sidecar",
      "image": "example/sidecar:v1.0.0",
      "ready": true
    }
  ],
  "conditions": [
    {
      "type": "Available",
      "status": "True",
      "last_transition_time": "2023-05-01T10:00:00Z"
    },
    {
      "type": "Progressing",
      "status": "True",
      "last_transition_time": "2023-05-01T10:00:00Z"
    }
  ]
}
```

### Metrics

#### Get Platform Metrics

```
GET /metrics
```

Response:
```json
{
  "experiments": {
    "total": 42,
    "running": 2,
    "completed": 35,
    "failed": 5
  },
  "resources": {
    "cpu_usage": 0.25,
    "memory_usage": 512,
    "memory_unit": "MB"
  },
  "targets": {
    "namespaces": 5,
    "deployments": 15,
    "pods": 45
  }
}
```

#### Get Experiment Metrics

```
GET /metrics/experiments
```

Query parameters:
- `timeframe` (optional): Time range (1h, 24h, 7d, 30d) (default: 24h)
- `interval` (optional): Aggregation interval (1m, 5m, 1h, 1d) (default: 1h)

Response:
```json
{
  "timeframe": "24h",
  "interval": "1h",
  "data": [
    {
      "timestamp": "2023-05-01T00:00:00Z",
      "running": 1,
      "completed": 2,
      "failed": 0
    },
    {
      "timestamp": "2023-05-01T01:00:00Z",
      "running": 2,
      "completed": 1,
      "failed": 0
    },
    // More data points...
  ]
}
```

### Settings

#### Get Settings

```
GET /settings
```

Response:
```json
{
  "general": {
    "platform_name": "Chaos Engineering Platform",
    "default_namespace": "chaos-engineering"
  },
  "security": {
    "token_expiration": 86400,
    "require_approval": true,
    "approval_roles": ["admin", "approver"]
  },
  "monitoring": {
    "prometheus_url": "http://prometheus.monitoring:9090",
    "grafana_url": "http://grafana.monitoring:3000"
  },
  "notifications": {
    "slack_webhook": "https://hooks.slack.com/services/...",
    "email_server": "smtp.example.com",
    "email_port": 587,
    "email_from": "chaos@example.com"
  }
}
```

#### Update Settings

```
PUT /settings
```

Request body:
```json
{
  "general": {
    "platform_name": "Chaos Engineering Platform",
    "default_namespace": "chaos-engineering"
  },
  "security": {
    "token_expiration": 86400,
    "require_approval": true,
    "approval_roles": ["admin", "approver"]
  },
  "monitoring": {
    "prometheus_url": "http://prometheus.monitoring:9090",
    "grafana_url": "http://grafana.monitoring:3000"
  },
  "notifications": {
    "slack_webhook": "https://hooks.slack.com/services/...",
    "email_server": "smtp.example.com",
    "email_port": 587,
    "email_from": "chaos@example.com"
  }
}
```

Response: Same as get settings

## Custom Experiment Types

### List Custom Experiment Types

```
GET /experiment-types
```

Response:
```json
{
  "total": 3,
  "types": [
    {
      "id": "type-123456",
      "name": "customPodFailure",
      "description": "Custom pod failure experiment",
      "created_at": "2023-04-01T10:00:00Z"
    },
    // More types...
  ]
}
```

### Get Custom Experiment Type

```
GET /experiment-types/{id}
```

Response:
```json
{
  "id": "type-123456",
  "name": "customPodFailure",
  "description": "Custom pod failure experiment",
  "created_at": "2023-04-01T10:00:00Z",
  "schema": {
    "properties": {
      "mode": {
        "type": "string",
        "enum": ["one", "fixed", "random", "all"],
        "description": "How to select pods"
      },
      "count": {
        "type": "integer",
        "minimum": 1,
        "description": "Number of pods to terminate"
      },
      "duration": {
        "type": "string",
        "pattern": "^\\d+[smh]$",
        "description": "Experiment duration"
      },
      "interval": {
        "type": "string",
        "pattern": "^\\d+[smh]$",
        "description": "Time between pod terminations"
      },
      "gracePeriod": {
        "type": "integer",
        "minimum": 0,
        "description": "Grace period for pod termination"
      }
    },
    "required": ["mode", "duration"]
  },
  "implementation": {
    "type": "kubernetes",
    "script": "#!/bin/bash\n# Implementation script\n..."
  }
}
```

### Create Custom Experiment Type

```
POST /experiment-types
```

Request body:
```json
{
  "name": "customPodFailure",
  "description": "Custom pod failure experiment",
  "schema": {
    "properties": {
      "mode": {
        "type": "string",
        "enum": ["one", "fixed", "random", "all"],
        "description": "How to select pods"
      },
      "count": {
        "type": "integer",
        "minimum": 1,
        "description": "Number of pods to terminate"
      },
      "duration": {
        "type": "string",
        "pattern": "^\\d+[smh]$",
        "description": "Experiment duration"
      },
      "interval": {
        "type": "string",
        "pattern": "^\\d+[smh]$",
        "description": "Time between pod terminations"
      },
      "gracePeriod": {
        "type": "integer",
        "minimum": 0,
        "description": "Grace period for pod termination"
      }
    },
    "required": ["mode", "duration"]
  },
  "implementation": {
    "type": "kubernetes",
    "script": "#!/bin/bash\n# Implementation script\n..."
  }
}
```

Response:
```json
{
  "id": "type-123456",
  "name": "customPodFailure",
  "created_at": "2023-05-01T10:00:00Z"
}
```

### Update Custom Experiment Type

```
PUT /experiment-types/{id}
```

Request body: Same as create custom experiment type

Response: Same as get custom experiment type

### Delete Custom Experiment Type

```
DELETE /experiment-types/{id}
```

Response:
```json
{
  "message": "Custom experiment type deleted successfully"
}
```

## Error Handling

The API uses standard HTTP status codes to indicate the success or failure of a request:

- `200 OK`: The request was successful
- `201 Created`: The resource was created successfully
- `400 Bad Request`: The request was invalid
- `401 Unauthorized`: Authentication failed
- `403 Forbidden`: The authenticated user does not have permission
- `404 Not Found`: The requested resource was not found
- `409 Conflict`: The request conflicts with the current state
- `500 Internal Server Error`: An error occurred on the server

Error responses include a JSON body with details:

```json
{
  "error": {
    "code": "invalid_parameter",
    "message": "Invalid parameter: duration must be a valid time duration",
    "details": {
      "parameter": "duration",
      "value": "5x",
      "expected": "A valid time duration (e.g., 5m, 1h)"
    }
  }
}
```

## Rate Limiting

The API implements rate limiting to prevent abuse. The rate limits are:

- 100 requests per minute per IP address
- 1000 requests per hour per user

When a rate limit is exceeded, the API returns a `429 Too Many Requests` status code with a `Retry-After` header indicating how many seconds to wait before retrying.

## Pagination

List endpoints support pagination using the `limit` and `offset` query parameters:

- `limit`: Maximum number of results to return (default: 20, max: 100)
- `offset`: Number of results to skip (default: 0)

The response includes the total number of results and the current page of results.

## Filtering

List endpoints support filtering using query parameters. The available filters depend on the endpoint and are documented in the endpoint descriptions.

## Sorting

List endpoints support sorting using the `sort` query parameter:

```
GET /experiments?sort=created_at:desc
```

The `sort` parameter takes the form `field:direction`, where `field` is the field to sort by and `direction` is either `asc` (ascending) or `desc` (descending).

## Webhooks

The platform supports webhooks for event notifications. You can configure webhooks in the settings:

```
POST /settings/webhooks
```

Request body:
```json
{
  "url": "https://example.com/webhook",
  "events": ["experiment.started", "experiment.completed", "experiment.failed"],
  "secret": "your-webhook-secret"
}
```

Response:
```json
{
  "id": "webhook-123456",
  "url": "https://example.com/webhook",
  "events": ["experiment.started", "experiment.completed", "experiment.failed"],
  "created_at": "2023-05-01T10:00:00Z"
}
```

Webhook payloads include the event type and relevant data:

```json
{
  "event": "experiment.completed",
  "timestamp": "2023-05-01T10:10:00Z",
  "data": {
    "id": "exp-123456",
    "name": "pod-failure-test",
    "status": "completed",
    "started_at": "2023-05-01T10:05:00Z",
    "ended_at": "2023-05-01T10:10:00Z"
  }
}
```

## SDK

The platform provides SDKs for common programming languages:

- [Python SDK](https://github.com/example/chaos-engineering-python)
- [Go SDK](https://github.com/example/chaos-engineering-go)
- [Java SDK](https://github.com/example/chaos-engineering-java)
- [JavaScript SDK](https://github.com/example/chaos-engineering-js)

## CLI

The platform provides a command-line interface (CLI) for interacting with the API:

```
# Install the CLI
pip install chaos-engineering-cli

# Configure the CLI
chaos config set api-url https://<control-plane-address>/api/v1
chaos auth login

# List experiments
chaos experiments list

# Create an experiment
chaos experiments create -f experiment.yaml

# Get experiment results
chaos experiments results exp-123456
```

## Examples

### Creating a Pod Failure Experiment

```bash
curl -X POST https://<control-plane-address>/api/v1/experiments \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "pod-failure-test",
    "target": {
      "namespace": "production",
      "selector": {
        "app": "payment-service"
      }
    },
    "action": {
      "type": "podFailure",
      "mode": "one",
      "count": 1,
      "duration": "5m",
      "interval": "10s",
      "gracePeriod": 0
    }
  }'
```

### Scheduling a Recurring Experiment

```bash
curl -X POST https://<control-plane-address>/api/v1/experiments \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "weekly-pod-failure",
    "target": {
      "namespace": "production",
      "selector": {
        "app": "payment-service"
      }
    },
    "action": {
      "type": "podFailure",
      "mode": "one",
      "count": 1,
      "duration": "5m",
      "interval": "10s",
      "gracePeriod": 0
    },
    "schedule": {
      "cron": "0 1 * * 2",
      "timeZone": "UTC"
    }
  }'
```

### Creating a Custom Experiment Type

```bash
curl -X POST https://<control-plane-address>/api/v1/experiment-types \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "customPodFailure",
    "description": "Custom pod failure experiment",
    "schema": {
      "properties": {
        "mode": {
          "type": "string",
          "enum": ["one", "fixed", "random", "all"],
          "description": "How to select pods"
        },
        "count": {
          "type": "integer",
          "minimum": 1,
          "description": "Number of pods to terminate"
        },
        "duration": {
          "type": "string",
          "pattern": "^\\d+[smh]$",
          "description": "Experiment duration"
        }
      },
      "required": ["mode", "duration"]
    },
    "implementation": {
      "type": "kubernetes",
      "script": "#!/bin/bash\n# Implementation script\n..."
    }
  }'
```

## API Versioning

The API uses versioning in the URL path (e.g., `/api/v1`). When breaking changes are introduced, a new version is created (e.g., `/api/v2`).

The current API versions are:

- `v1`: Current stable version

## Support

If you encounter any issues with the API, please contact support at support@example.com or open an issue on the [GitHub repository](https://github.com/example/chaos-engineering). 