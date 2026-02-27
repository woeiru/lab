# Logging Configuration

This directory contains configuration files, deployment examples, and documentation for the auxiliary logging system (`lib/gen/aux`). The logging system provides structured logging with cluster metadata support for distributed environments.

## Supported Log Formats

Multiple output formats are supported:
- **JSON** (`AUX_LOG_FORMAT=json`) - Elasticsearch/OpenSearch
- **CSV** (`AUX_LOG_FORMAT=csv`) - Data analysis tools
- **Key-Value** (`AUX_LOG_FORMAT=kv`) - Splunk and other systems
- **Human** (`AUX_LOG_FORMAT=human`) - Default readable format

## Log Files Generated

- `${LOG_DIR}/aux.json` - Structured JSON events (operational and debug)
- `${LOG_DIR}/aux.csv` - CSV events with headers (operational and debug)
- `${LOG_DIR}/aux.log` - Human-readable or key-value events (consolidated stream)

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

## Logging Contract

To avoid drift, treat logging as a three-layer contract:

1. **Producer policy (`lib/.spec`)**
   - Defines required usage of `aux_*` functions for operational output.
   - Requires structured context data (`key=value` pairs).

2. **Emitter implementation (`lib/gen/aux`)**
   - Writes consolidated streams to `${LOG_DIR}/aux.json`, `${LOG_DIR}/aux.csv`, and `${LOG_DIR}/aux.log`.
   - Emits structured event types used by shipper routing (for example, `operational` and `debug`).

3. **Ingestion configuration (`cfg/log/*`)**
   - `filebeat.yml` and `fluentd.conf` must ingest the consolidated files emitted by `lib/gen/aux`.
   - Index routing must stay aligned with emitted event type and fallback text streams.

If you change one layer, validate the other two in the same change.

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
   - Monitor `${LOG_DIR}/aux.json` for structured logs
