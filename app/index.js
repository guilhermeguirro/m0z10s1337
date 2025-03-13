/**
 * Chaos Engineering Control Plane
 * 
 * This is a simplified version of the control plane for demonstration purposes.
 * In a real implementation, this would be written in TypeScript with proper
 * architecture and testing.
 */

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const winston = require('winston');
const promClient = require('prom-client');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Initialize Express app
const app = express();
const httpPort = process.env.PORT || 8080;
const grpcPort = process.env.GRPC_PORT || 9090;

// Configure logging
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

// Initialize Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Experiment metrics
const experimentsCreated = new promClient.Counter({
  name: 'chaos_experiments_created_total',
  help: 'Total number of chaos experiments created',
  labelNames: ['type']
});

const experimentsCompleted = new promClient.Counter({
  name: 'chaos_experiments_completed_total',
  help: 'Total number of chaos experiments completed',
  labelNames: ['type', 'status']
});

const experimentDuration = new promClient.Histogram({
  name: 'chaos_experiment_duration_seconds',
  help: 'Duration of chaos experiments in seconds',
  labelNames: ['type'],
  buckets: [60, 300, 600, 1800, 3600]
});

register.registerMetric(experimentsCreated);
register.registerMetric(experimentsCompleted);
register.registerMetric(experimentDuration);

// In-memory storage for experiments (would use a database in production)
const experiments = {};
const results = {};

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Log all requests
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  next();
});

// Routes
app.get('/', (req, res) => {
  res.json({
    name: 'Chaos Engineering Control Plane',
    version: '1.0.0',
    status: 'running'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Readiness check endpoint
app.get('/ready', (req, res) => {
  res.status(200).json({ status: 'ready' });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// API endpoints
app.get('/api/experiments', (req, res) => {
  res.json(Object.values(experiments));
});

app.get('/api/experiments/:id', (req, res) => {
  const experiment = experiments[req.params.id];
  if (!experiment) {
    return res.status(404).json({ error: 'Experiment not found' });
  }
  res.json(experiment);
});

app.post('/api/experiments', (req, res) => {
  const id = uuidv4();
  const experiment = {
    id,
    ...req.body,
    status: 'pending',
    createdAt: new Date().toISOString()
  };
  
  experiments[id] = experiment;
  
  // Record metric
  experimentsCreated.inc({ type: experiment.action.type });
  
  logger.info(`Created experiment ${id}`, { experiment });
  
  // In a real implementation, this would be queued for execution
  // For demo purposes, we'll just mark it as scheduled
  setTimeout(() => {
    experiment.status = 'scheduled';
    logger.info(`Scheduled experiment ${id}`);
  }, 1000);
  
  res.status(201).json(experiment);
});

app.put('/api/experiments/:id/start', (req, res) => {
  const experiment = experiments[req.params.id];
  if (!experiment) {
    return res.status(404).json({ error: 'Experiment not found' });
  }
  
  if (experiment.status !== 'scheduled') {
    return res.status(400).json({ error: 'Experiment is not in scheduled state' });
  }
  
  experiment.status = 'running';
  experiment.startedAt = new Date().toISOString();
  
  logger.info(`Started experiment ${experiment.id}`);
  
  // In a real implementation, this would trigger the actual chaos injection
  // For demo purposes, we'll just simulate completion after a delay
  setTimeout(() => {
    completeExperiment(experiment.id, 'completed');
  }, 5000);
  
  res.json(experiment);
});

app.put('/api/experiments/:id/stop', (req, res) => {
  const experiment = experiments[req.params.id];
  if (!experiment) {
    return res.status(404).json({ error: 'Experiment not found' });
  }
  
  if (experiment.status !== 'running') {
    return res.status(400).json({ error: 'Experiment is not running' });
  }
  
  completeExperiment(experiment.id, 'stopped');
  
  res.json(experiment);
});

app.get('/api/results', (req, res) => {
  res.json(Object.values(results));
});

app.get('/api/results/:id', (req, res) => {
  const result = results[req.params.id];
  if (!result) {
    return res.status(404).json({ error: 'Result not found' });
  }
  res.json(result);
});

// Helper function to complete an experiment
function completeExperiment(id, status) {
  const experiment = experiments[id];
  if (!experiment) {
    logger.error(`Experiment ${id} not found for completion`);
    return;
  }
  
  experiment.status = status;
  experiment.completedAt = new Date().toISOString();
  
  // Calculate duration
  if (experiment.startedAt) {
    const startTime = new Date(experiment.startedAt).getTime();
    const endTime = new Date(experiment.completedAt).getTime();
    const durationSeconds = (endTime - startTime) / 1000;
    
    experimentDuration.observe({ type: experiment.action.type }, durationSeconds);
  }
  
  // Record completion metric
  experimentsCompleted.inc({ 
    type: experiment.action.type,
    status: status
  });
  
  // Create a result
  const result = {
    id: uuidv4(),
    experimentId: id,
    status,
    metrics: {
      // In a real implementation, this would include actual metrics
      errorRate: Math.random() * 2, // Simulated error rate percentage
      latency: 100 + Math.random() * 200, // Simulated latency in ms
      availability: 99.5 + Math.random() * 0.5 // Simulated availability percentage
    },
    completedAt: experiment.completedAt
  };
  
  results[result.id] = result;
  experiment.resultId = result.id;
  
  logger.info(`Completed experiment ${id} with status ${status}`, { result });
}

// Start the server
app.listen(httpPort, () => {
  logger.info(`HTTP server listening on port ${httpPort}`);
});

// In a real implementation, we would also start a gRPC server here
logger.info(`gRPC server would be listening on port ${grpcPort}`);

// Handle graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  // Close servers, database connections, etc.
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  // Close servers, database connections, etc.
  process.exit(0);
}); 
