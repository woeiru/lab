# Log Shipping Configuration Examples
# Enhanced Logging System - Centralized Collection Setup

This directory contains configuration examples for shipping structured logs from the enhanced auxiliary logging system to centralized logging platforms.

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

- `fluentd.conf` - Fluentd configuration for JSON log shipping
- `filebeat.yml` - Elastic Filebeat configuration
- `logstash.conf` - Logstash pipeline configuration
- `rsyslog.conf` - Rsyslog forwarding configuration
- `promtail.yml` - Grafana Loki Promtail configuration

## Environment Variables

Set these variables to configure the logging behavior:

```bash
# Log format selection
export AUX_LOG_FORMAT="json"  # json|csv|kv|human

# Enable debug logging 
export AUX_DEBUG_ENABLED="1"  # 1=enabled, 0=disabled

# Cluster identification
export CLUSTER_ID="production-cluster-01"
export NODE_ID="worker-node-03"
export SERVICE_NAME="application-service"
export POD_NAME="app-pod-12345"

# Metrics endpoint for performance data
export METRICS_ENDPOINT="http://prometheus:9090"

# Master verbosity control
export MASTER_TERMINAL_VERBOSITY="on"  # on|off
```

## Usage Examples

See `usage_examples.md` for detailed implementation examples and best practices.
