# Enhanced Logging System Usage Examples
# Comprehensive guide for implementing the enhanced logging system

## Basic Usage Examples

### 1. Simple Operational Logging

```bash
#!/bin/bash
source lib/gen/aux

# Basic info, warning, and error logging
aux_info "Application started successfully"
aux_warn "Configuration file missing, using defaults"
aux_err "Database connection failed"

# Operational logging with explicit levels
aux_log "INFO" "User authentication successful" "user_id=12345,method=oauth"
aux_log "ERROR" "Payment processing failed" "order_id=67890,amount=99.99,error=timeout"
```

### 2. Structured Logging with Context

```bash
#!/bin/bash
source lib/gen/aux

# Set up environment for structured logging
export AUX_LOG_FORMAT="json"
export CLUSTER_ID="production-cluster-01"
export SERVICE_NAME="user-service"

# Log with rich context
aux_log "INFO" "Order created" "user_id=123,order_id=456,total=99.99,currency=USD"
aux_log "AUDIT" "Admin action performed" "admin_user=john,action=user_delete,target_user=jane"
```

### 3. Debug Logging for Development

```bash
#!/bin/bash
source lib/gen/aux

# Enable debug output
export MASTER_TERMINAL_VERBOSITY="on"
export AUX_DEBUG_ENABLED="1"

# Debug logging with automatic function context
aux_dbg "Starting user validation process"
aux_dbg "Found user record in database" "INFO"
aux_dbg "Validation completed successfully"

# Debug with variable inspection
local user_count=25
aux_dbg "Processing batch: user_count=$user_count, batch_size=10"
```

## Advanced Usage Patterns

### 4. Distributed Tracing

```bash
#!/bin/bash
source lib/gen/aux

# Start a distributed trace
aux_start_trace "user_registration"

# Log operations within the trace
aux_log "INFO" "Starting user registration process"
aux_dbg "Validating user input"
aux_dbg "Creating user record"
aux_log "INFO" "User registration completed successfully"

# End the trace
aux_end_trace
```

### 5. Performance Monitoring

```bash
#!/bin/bash
source lib/gen/aux

# Log performance metrics
aux_metric "api_response_time" 145.7 "gauge"
aux_metric "database_connections" 42 "gauge"
aux_metric "requests_processed" 1 "counter"

# Performance logging
aux_perf "Database query completed" "duration=250ms,table=users,rows=150"
```

### 6. Specialized Logging Types

```bash
#!/bin/bash
source lib/gen/aux

# Business logic events
aux_business "Order workflow completed" "order_id=12345,revenue=199.99,customer_tier=premium"

# Security events
aux_security "Suspicious login detected" "ip=192.168.1.100,user=admin,attempts=5,blocked=true"

# Audit trail
aux_audit "Data export performed" "user=analyst,dataset=customer_data,records=50000"

# Performance events
aux_perf "Cache refresh completed" "cache_type=user_sessions,size=10MB,duration=2.3s"
```

## Cluster Deployment Examples

### 7. Kubernetes Pod Configuration

```yaml
# kubernetes-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: enhanced-logging-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: enhanced-logging-app
  template:
    metadata:
      labels:
        app: enhanced-logging-app
    spec:
      containers:
      - name: app
        image: my-app:latest
        env:
        - name: AUX_LOG_FORMAT
          value: "json"
        - name: CLUSTER_ID
          value: "k8s-production"
        - name: NODE_ID
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: SERVICE_NAME
          value: "user-service"
        - name: METRICS_ENDPOINT
          value: "http://prometheus:9090"
        - name: LOG_DIR
          value: "/app/logs"
        volumeMounts:
        - name: log-volume
          mountPath: /app/logs
      volumes:
      - name: log-volume
        emptyDir: {}
```

### 8. Docker Compose Configuration

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    environment:
      - AUX_LOG_FORMAT=json
      - CLUSTER_ID=docker-cluster
      - NODE_ID=docker-node-01
      - SERVICE_NAME=web-app
      - METRICS_ENDPOINT=http://prometheus:9090
      - LOG_DIR=/app/logs
    volumes:
      - ./logs:/app/logs
      - /etc/hostname:/etc/hostname:ro
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: docker.app
```

## Log Format Examples

### 9. Different Output Formats

```bash
#!/bin/bash
source lib/gen/aux

# JSON format (best for Elasticsearch)
export AUX_LOG_FORMAT="json"
aux_log "INFO" "User login" "user_id=123,ip=192.168.1.1"
# Output: {"timestamp":"2025-06-08T23:58:51","level":"INFO","message":"User login","type":"operational","node_id":"server-01","cluster_id":"prod","service":"auth-service","context":"user_id=123,ip=192.168.1.1","pid":12345}

# CSV format (good for data analysis)
export AUX_LOG_FORMAT="csv"
aux_log "INFO" "User login" "user_id=123,ip=192.168.1.1"
# Output: "2025-06-08T23:58:51","INFO","User login","","server-01","prod","auth-service","user_id=123,ip=192.168.1.1"

# Key-value format (compatible with Splunk)
export AUX_LOG_FORMAT="kv"
aux_log "INFO" "User login" "user_id=123,ip=192.168.1.1"
# Output: timestamp=2025-06-08T23:58:51 level=INFO message="User login" type=operational node_id=server-01 cluster_id=prod service=auth-service user_id=123,ip=192.168.1.1

# Human-readable format (default)
export AUX_LOG_FORMAT="human"
aux_log "INFO" "User login" "user_id=123,ip=192.168.1.1"
# Output: [2025-06-08T23:58:51] [INFO] User login [user_id=123,ip=192.168.1.1]
```

## Error Handling and Validation

### 10. Robust Error Handling

```bash
#!/bin/bash
source lib/gen/aux

# Function with comprehensive logging
process_user_data() {
    local user_id="$1"
    
    # Validate input
    if [[ -z "$user_id" ]]; then
        aux_err "Missing required parameter: user_id"
        return 1
    fi
    
    aux_info "Starting user data processing" "user_id=$user_id"
    
    # Start tracing for this operation
    aux_start_trace "process_user_data"
    
    # Simulate processing with debug logging
    aux_dbg "Fetching user data from database"
    
    if ! fetch_user_data "$user_id"; then
        aux_err "Failed to fetch user data" "user_id=$user_id"
        aux_end_trace
        return 1
    fi
    
    aux_dbg "Processing user preferences"
    aux_metric "users_processed" 1 "counter"
    
    aux_info "User data processing completed" "user_id=$user_id"
    aux_end_trace
    
    return 0
}

# Usage with error handling
if ! process_user_data "12345"; then
    aux_err "User processing pipeline failed"
    exit 1
fi
```

## Integration with Existing Systems

### 11. Integration with Main Logging System

```bash
#!/bin/bash
source lib/gen/aux

# Check if main logging system is available
if type -t log &>/dev/null; then
    aux_info "Enhanced logging integrated with main system"
    # aux_log will automatically use the main logging system
else
    aux_warn "Main logging system not available, using fallback"
    # aux_log will use file-based logging
fi

# The enhanced logging system automatically detects and integrates with:
# - lo1 logging system (lib/core/lo1)
# - Master verbosity controls (MASTER_TERMINAL_VERBOSITY)
# - Existing log directories (LOG_DIR)
```

## Best Practices

### 12. Production Deployment Best Practices

```bash
#!/bin/bash
source lib/gen/aux

# Production configuration
export AUX_LOG_FORMAT="json"          # Use structured format
export CLUSTER_ID="prod-cluster-01"   # Identify your cluster
export SERVICE_NAME="$APP_NAME"       # Use application name
export MASTER_TERMINAL_VERBOSITY="off" # Reduce console output
export AUX_DEBUG_ENABLED="0"          # Disable debug in production

# Essential operational logging only
aux_info "Service started" "version=$APP_VERSION,config=$CONFIG_VERSION"
aux_audit "Service configuration loaded" "config_file=$CONFIG_FILE"

# Performance monitoring
aux_metric "service_startup_time" "$startup_duration" "gauge"
```

### 13. Development Environment Setup

```bash
#!/bin/bash
source lib/gen/aux

# Development configuration
export AUX_LOG_FORMAT="human"         # Human-readable for development
export MASTER_TERMINAL_VERBOSITY="on" # Enable console output
export AUX_DEBUG_ENABLED="1"          # Enable debug logging
export LOG_DEBUG_ENABLED="1"          # Enable lo1 debug logging

# Comprehensive logging for debugging
aux_info "Development environment initialized"
aux_dbg "Debug logging enabled for development"
aux_dbg "Log files will be created in: ${LOG_DIR:-$PWD/.log}"
```

This enhanced logging system provides enterprise-level logging capabilities with:
- Multiple output formats for different systems
- Automatic cluster metadata collection
- Distributed tracing support
- Performance metrics integration
- Seamless integration with existing logging infrastructure
