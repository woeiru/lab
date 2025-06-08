# AI Assistant Instructions for Enhanced Logging Integration

This document provides prompt templates and instructions for guiding AI assistants to properly integrate and utilize the enhanced auxiliary logging system when working with functions in the lab environment.

## Core Logging Integration Instructions

### Basic Integration Prompt
```
When working with functions in this lab environment, always integrate the enhanced logging system by:

1. Source the logging system with `source lib/gen/aux` at the beginning of scripts
2. Use appropriate logging functions for different event types:
   - `aux_info()` for informational operational events
   - `aux_warn()` for warnings and non-critical issues
   - `aux_err()` for errors and failures
   - `aux_dbg()` for debug information
3. Add structured context data using the format "key=value,key2=value2"
4. Use specialized logging for specific domains when appropriate

The enhanced logging system is located in `lib/gen/aux` and provides enterprise-grade structured logging with cluster metadata support.
```

### Function Enhancement Prompt
```
Enhance existing functions by adding comprehensive logging using the auxiliary logging system:

- Add entry/exit logging with `aux_info "Function ${FUNCNAME[0]} started"` 
- Log parameter validation with `aux_dbg "Validating parameters: param1=$1, param2=$2"`
- Log decision points with `aux_info` or `aux_warn` as appropriate
- Log errors with `aux_err "Error in ${FUNCNAME[0]}: description" "context=details"`
- Add performance logging with `aux_perf` for timing-critical operations
- Use `aux_business` for business logic events, `aux_security` for security events
- Include correlation context using structured key=value pairs

Configure output format with `export AUX_LOG_FORMAT="json"` for structured logging or leave default for human-readable output.
```

## Specific Use Case Instructions

### Error Handling Enhancement
```
When adding error handling to functions, integrate structured logging:

Replace basic error handling like:
```bash
if [ $? -ne 0 ]; then
    echo "Error occurred"
    return 1
fi
```

With enhanced logging:
```bash
if [ $? -ne 0 ]; then
    aux_err "Operation failed in ${FUNCNAME[0]}" "exit_code=$?,operation=command_name,context=additional_info"
    return 1
fi
```

This provides structured error data for centralized monitoring and alerting.
```

### Performance Monitoring Integration
```
Add performance monitoring to functions using the enhanced logging system:

1. Start timing with `aux_start_trace "operation_name"`
2. Log intermediate steps with `aux_perf "Checkpoint reached" "step=validation,duration=100ms"`
3. End timing with `aux_end_trace "operation_name"`
4. Log resource usage with `aux_metric "resource_usage" "cpu=45%,memory=2GB,disk_io=150MB/s"`

This enables performance analysis and capacity planning through centralized log aggregation.
```

### Business Logic Logging
```
When working with business logic functions, add appropriate business event logging:

- Use `aux_business` for workflow events: `aux_business "Order processed" "order_id=12345,status=completed,amount=99.99"`
- Use `aux_audit` for compliance events: `aux_audit "User permissions modified" "admin=john,target=jane,action=grant,resource=database"`
- Use `aux_security` for security events: `aux_security "Authentication attempt" "user=admin,method=oauth,result=success,ip=192.168.1.100"`

This creates structured audit trails for compliance and business intelligence.
```

## Advanced Integration Prompts

### Distributed System Context
```
When working with functions that may run in distributed environments, ensure cluster-aware logging:

1. The logging system automatically captures cluster metadata (node_id, cluster_id, service name)
2. Add request correlation using structured context: "request_id=uuid,session_id=session"
3. Use distributed tracing for cross-service calls:
   ```bash
   trace_id=$(aux_start_trace "external_api_call")
   # ... make API call ...
   aux_end_trace "$trace_id"
   ```
4. Log service boundaries with `aux_info "Service boundary crossed" "from=service_a,to=service_b,operation=data_sync"`

This enables request tracing across microservices and distributed systems.
```

### Configuration and Environment Logging
```
Enhance configuration and environment management functions with structured logging:

1. Log configuration loading: `aux_info "Configuration loaded" "source=config_file,environment=production,values_count=25"`
2. Log environment validation: `aux_warn "Environment variable missing" "variable=API_KEY,default_used=true"`
3. Log configuration changes: `aux_audit "Configuration updated" "section=database,parameter=connection_pool,old_value=10,new_value=20"`
4. Log environment transitions: `aux_business "Environment switch" "from=development,to=production,validation=passed"`

Use `AUX_LOG_FORMAT="json"` for structured ingestion into configuration management systems.
```

### Integration Testing and Validation
```
When creating or enhancing test functions, integrate comprehensive logging:

1. Log test execution: `aux_info "Test suite started" "suite=integration,test_count=15,environment=testing"`
2. Log test results: `aux_info "Test completed" "test=user_authentication,result=passed,duration=250ms"`
3. Log failures with context: `aux_err "Test failed" "test=database_connection,error=timeout,expected=success,actual=connection_refused"`
4. Log validation steps: `aux_dbg "Validation checkpoint" "step=input_validation,data=user_input,status=valid"`

This provides detailed test execution logs for CI/CD pipeline analysis and debugging.
```

## Environment Configuration Instructions

### Quick Setup Prompt
```
Before implementing logging enhancements, set up the logging environment:

1. Source the enhanced logging system: `source lib/gen/aux`
2. Configure desired output format: `export AUX_LOG_FORMAT="json"` (or csv, kv, human)
3. Enable debug logging if needed: `export AUX_DEBUG=1`
4. Set cluster context if applicable:
   ```bash
   export CLUSTER_ID="production-cluster-01"
   export NODE_ID="worker-node-03" 
   export SERVICE_NAME="application-service"
   ```

Log files will be automatically created in `${LOG_DIR}/.log/` directory with appropriate formats for centralized collection.
```

### Deployment Context Prompt
```
When preparing functions for production deployment, ensure logging is configured for centralized collection:

1. Use JSON format for structured ingestion: `export AUX_LOG_FORMAT="json"`
2. Configure log shipping using provided configurations in `cfg/log/fluentd.conf` or `cfg/log/filebeat.yml`
3. Set appropriate log levels for production (avoid excessive debug logging)
4. Ensure sensitive data is not logged (use structured context without secrets)
5. Test log output with `cfg/log/usage_examples.md` patterns

The system outputs to multiple formats simultaneously for different analysis tools and monitoring systems.
```

## Example Integration Prompts

### Function Modernization
```
Take this existing function and enhance it with comprehensive logging using the auxiliary logging system. Add appropriate entry/exit logging, parameter validation logging, error handling with structured context, and performance monitoring. Use the specialized logging functions (aux_business, aux_security, aux_audit, aux_perf) where appropriate based on the function's purpose.

Source the logging system with `source lib/gen/aux` and configure structured output if needed.
```

### New Function Development
```
Create a new function that includes enterprise-grade logging from the start. Use the enhanced auxiliary logging system (`lib/gen/aux`) to provide:
- Structured operational logging with cluster metadata
- Comprehensive error handling with contextual information  
- Performance monitoring and metrics collection
- Business logic event tracking where applicable
- Debug logging for troubleshooting support

Configure appropriate log formats and ensure the function is ready for production deployment with centralized log collection.
```

### Legacy Code Enhancement
```
Modernize this legacy code by integrating the enhanced logging system without changing core functionality. Add structured logging that provides operational visibility, error tracking, and performance monitoring. Us the auxiliary logging functions appropriately and ensure backward compatibility while adding enterprise-grade observability.

Focus on adding value through logging without disrupting existing behavior.
```

## Usage Notes

- These instructions assume the enhanced auxiliary logging system is available at `lib/gen/aux`
- Log files are automatically created in `${LOG_DIR}/.log/` directory
- Structured formats (JSON, CSV) are available for centralized log aggregation
- The system includes cluster metadata and distributed tracing capabilities
- Configuration examples are available in `cfg/log/` directory

Use these prompts as templates and adapt them based on your specific requirements and the AI assistant you're working with.
