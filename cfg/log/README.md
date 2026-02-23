# Logging Configuration

This directory contains configuration files, deployment examples, and documentation for the auxiliary logging system (`lib/gen/aux`). The logging system provides structured logging with cluster metadata support for distributed environments.

## Supported Log Formats

Multiple output formats are supported:
- **JSON** (`AUX_LOG_FORMAT=json`) - Elasticsearch/OpenSearch
- **CSV** (`AUX_LOG_FORMAT=csv`) - Data analysis tools
- **Key-Value** (`AUX_LOG_FORMAT=kv`) - Splunk and other systems
- **Human** (`AUX_LOG_FORMAT=human`) - Default readable format

## Log Files Generated

### Operational Logs
- `${LOG_DIR}/aux_operational.log` - Human-readable operational events
- `${LOG_DIR}/aux_operational.jsonl` - JSON Lines format for structured ingestion
- `${LOG_DIR}/aux_operational.csv` - CSV format with headers

### Debug Logs  
- `${LOG_DIR}/aux_debug.log` - Human-readable debug information
- `${LOG_DIR}/aux_debug.jsonl` - JSON Lines format for debug data
- `${LOG_DIR}/aux_debug.csv` - CSV format debug logs

## Configuration Files

Configurations for log shipping and aggregation platforms:

- `fluentd.conf` - Fluentd configuration for JSON log shipping
- `filebeat.yml` - Elastic Filebeat configuration
- `usage_examples.md` - Implementation examples and deployment patterns
- `enhanced_logging_dev_summary.md` - Technical details
- `enhanced_logging_next_steps.md` - Implementation guide

## Integration

The auxiliary logging system is located in `lib/gen/aux` and provides:

- Structured logging in JSON, CSV, key-value, and human-readable formats
- Cluster metadata integration
- Logging functions for business, security, audit, and performance events
- Distributed tracing support with correlation IDs

## Quick Start

1. **Source the logging system:**
   ```bash
   source lib/gen/aux
   ```

2. **Configure output format:**
   ```bash
   export AUX_LOG_FORMAT="json"
   ```

3. **Use logging functions:**
   ```bash
   aux_info "Application started successfully"
   aux_business "Order processed" "order_id=12345,amount=99.99"  
   aux_security "Login attempt" "user=admin,ip=192.168.1.100"
   ```

4. **Deploy log shipping:**
   - Copy `fluentd.conf` or `filebeat.yml` to your log shipper
   - Configure endpoints and credentials
   - Monitor `${LOG_DIR}/aux_operational.jsonl` for structured logs
