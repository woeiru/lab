#!/bin/bash
# Debug version to find the exact failing command

# Removing strict mode to see what fails
# set -euo pipefail

target_dir="/home/es/lab/lib/ops"
WORK_DIR="/tmp/debug_ai_$$"
mkdir -p "$WORK_DIR"

echo "Testing external commands extraction..."
external_cmds=$(grep -rho '\b[a-z][a-z0-9_-]*\b' "$target_dir" 2>/dev/null | \
               grep -vE '^(if|for|while|case|do|done|then|else|fi|function|local|return|exit|echo|printf)$' | \
               sort -u | (head -20 || true) | jq -R . | jq -s . 2>/dev/null || echo "[]")
echo "External commands: OK"

echo "Testing file sources count..."
file_sources=$(grep -rc "source\|\\\." "$target_dir" 2>/dev/null | awk -F: '{sum += $2} END {print sum+0}')
echo "File sources: $file_sources"

echo "Testing network usage count..."
network_usage=$(grep -rc "curl\|wget\|ssh\|scp\|rsync" "$target_dir" 2>/dev/null | awk -F: '{sum += $2} END {print sum+0}')
echo "Network usage: $network_usage"

echo "Testing database usage count..."
database_usage=$(grep -rc "mysql\|postgres\|sqlite\|redis" "$target_dir" 2>/dev/null | awk -F: '{sum += $2} END {print sum+0}')
echo "Database usage: $database_usage"

echo "Testing container usage count..."
container_usage=$(grep -rc "docker\|podman\|kubectl\|systemctl" "$target_dir" 2>/dev/null | awk -F: '{sum += $2} END {print sum+0}')
echo "Container usage: $container_usage"

echo "Testing service integration count..."
service_integration=$(grep -rc "systemctl\|service\|daemon" "$target_dir" 2>/dev/null | awk -F: '{sum += $2} END {print sum+0}')
echo "Service integration: $service_integration"

echo "Testing cron scheduling count..."
cron_scheduling=$(grep -rc "cron\|\*/[0-9]\|@daily\|@hourly" "$target_dir" 2>/dev/null | awk -F: '{sum += $2} END {print sum+0}')
echo "Cron scheduling: $cron_scheduling"

echo "Testing config management count..."
config_management=$(find "$target_dir" -name "*.conf" -o -name "*.cfg" -o -name "*.env" 2>/dev/null | wc -l)
echo "Config management: $config_management"

echo "Creating integration JSON..."
integration_data=$(cat << EOF
{
  "dependencies": {
    "external_commands": $external_cmds,
    "file_sources": $file_sources,
    "network_usage": $network_usage,
    "database_usage": $database_usage,
    "container_usage": $container_usage
  },
  "integration_patterns": {
    "service_integration": $service_integration,
    "cron_scheduling": $cron_scheduling,
    "config_management": $config_management
  }
}
EOF
)

echo "Testing jq processing..."
echo "$integration_data" | jq . > "$WORK_DIR/integration.json"
echo "Integration JSON created successfully"

rm -rf "$WORK_DIR"
echo "All tests passed!"
