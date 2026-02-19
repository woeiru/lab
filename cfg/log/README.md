# Logging Configuration - cfg/log/

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../../doc/README.md)

Enhanced auxiliary logging system configuration for `cfg/log/`.

This directory contains all configuration files, deployment examples, and documentation for the enhanced auxiliary logging system (`lib/gen/aux`). The enhanced logging system provides enterprise-grade structured logging with cluster metadata support for distributed environments.

## Supported Log Formats

The enhanced logging system supports multiple output formats:
- **JSON** (`AUX_LOG_FORMAT=json`) - Best for Elasticsearch/OpenSearch
- **CSV** (`AUX_LOG_FORMAT=csv`) - Good for data analysis tools
- **Key-Value** (`AUX_LOG_FORMAT=kv`) - Compatible with Splunk and other systems
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

This directory provides ready-to-deploy configurations for various log shipping and aggregation platforms:

- **`fluentd.conf`** - Fluentd configuration for JSON log shipping to Elasticsearch/OpenSearch
- **`filebeat.yml`** - Elastic Filebeat configuration for shipping to the Elastic Stack
- **`usage_examples.md`** - Comprehensive implementation examples and deployment patterns
- **`enhanced_logging_dev_summary.md`** - Complete development summary and technical details
- **`enhanced_logging_next_steps.md`** - Optional enhancement roadmap and implementation guide

## Integration with Enhanced Logging System

The enhanced auxiliary logging system is located in `lib/gen/aux` and provides:

- **Structured logging** in JSON, CSV, key-value, and human-readable formats
- **Cluster metadata** integration for distributed systems
- **Specialized logging functions** for business, security, audit, and performance events
- **Distributed tracing** support with correlation IDs
- **Multiple output destinations** with automatic log file management

## Quick Start

1. **Source the enhanced logging system:**
   ```bash
   source lib/gen/aux
   ```

2. **Configure output format:**
   ```bash
   export AUX_LOG_FORMAT="json"  # json|csv|kv|human
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

## Common Tasks
- Set `AUX_LOG_FORMAT` to match your downstream stack (`json`, `csv`, `kv`, `human`).
- Validate structured log output in `${LOG_DIR}/aux_operational.jsonl` after changes.
- Roll out shipper updates (`fluentd.conf` or `filebeat.yml`) with environment-specific endpoints and credentials.

## Troubleshooting
- If logs are missing, confirm `lib/gen/aux` is sourced and `LOG_DIR` is writable.
- If ingestion fails, verify format/parser alignment between `AUX_LOG_FORMAT` and shipper configuration.
- If shippers send no data, verify endpoint/credential settings and tail the local `aux_*.jsonl` files first.

## Related Docs
- [Configuration Root](../README.md)
- [Repository Root](../../README.md)
- [Documentation Hub](../../doc/README.md)
