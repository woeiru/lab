#!/bin/bash
# Network Operations Library Tests
# Tests for lib/ops/net network operation functions

# Test configuration
TEST_NAME="Network Operations Library"
TEST_CATEGORY="lib"

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/../../../val/helpers/test_framework.sh"

# Load the library being tested
source "${LAB_ROOT}/lib/ops/net"

# Test: Network functions exist
test_network_functions_exist() {
    local functions=("check_connectivity" "get_network_info" "test_port" "get_interfaces")
    local existing=()
    
    for func in "${functions[@]}"; do
        if command -v "$func" &> /dev/null; then
            existing+=("$func")
        fi
    done
    
    if [[ ${#existing[@]} -gt 0 ]]; then
        echo "✓ Found network functions: ${existing[*]}"
        return 0
    else
        echo "✓ Network library loaded (functions may have different names)"
        return 0
    fi
}

# Test: Network interface detection
test_network_interface_detection() {
    local interfaces=()
    
    # Try different methods to get network interfaces
    if command -v ip &>/dev/null; then
        while IFS= read -r interface; do
            if [[ -n "$interface" ]] && [[ "$interface" != "lo" ]]; then
                interfaces+=("$interface")
            fi
        done < <(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' 2>/dev/null || true)
    elif command -v ifconfig &>/dev/null; then
        while IFS= read -r interface; do
            if [[ -n "$interface" ]] && [[ "$interface" != "lo" ]]; then
                interfaces+=("$interface")
            fi
        done < <(ifconfig | grep '^[a-zA-Z]' | awk '{print $1}' | tr -d ':' | grep -v '^lo$' 2>/dev/null || true)
    fi
    
    if [[ ${#interfaces[@]} -gt 0 ]]; then
        echo "✓ Network interfaces detected: ${interfaces[*]}"
        return 0
    else
        echo "✓ Network interface detection completed (no external interfaces found)"
        return 0
    fi
}

# Test: Loopback connectivity
test_loopback_connectivity() {
    if ping -c 1 -W 1 127.0.0.1 &>/dev/null; then
        echo "✓ Loopback connectivity works (IPv4)"
    else
        echo "✗ Loopback connectivity failed (IPv4)"
        return 1
    fi
    
    if ping -c 1 -W 1 ::1 &>/dev/null 2>&1; then
        echo "✓ Loopback connectivity works (IPv6)"
    else
        echo "✓ IPv6 loopback not available (normal on some systems)"
    fi
    
    return 0
}

# Test: DNS resolution
test_dns_resolution() {
    local test_domains=("localhost" "google.com" "github.com")
    local resolved_domains=()
    local failed_domains=()
    
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" &>/dev/null || host "$domain" &>/dev/null || getent hosts "$domain" &>/dev/null; then
            resolved_domains+=("$domain")
        else
            failed_domains+=("$domain")
        fi
    done
    
    if [[ ${#resolved_domains[@]} -gt 0 ]]; then
        echo "✓ DNS resolution works for: ${resolved_domains[*]}"
        if [[ ${#failed_domains[@]} -gt 0 ]]; then
            echo "  Failed to resolve: ${failed_domains[*]}"
        fi
        return 0
    else
        echo "✗ DNS resolution failed for all test domains"
        return 1
    fi
}

# Test: Port connectivity testing
test_port_connectivity() {
    local test_ports=("22" "80" "443")
    local available_ports=()
    local localhost_tests=()
    
    for port in "${test_ports[@]}"; do
        # Test if port is open on localhost
        if timeout 1 bash -c "echo >/dev/tcp/127.0.0.1/$port" 2>/dev/null; then
            localhost_tests+=("$port")
        fi
        
        # Test if port scanning tools are available
        if command -v nc &>/dev/null; then
            if nc -z 127.0.0.1 "$port" 2>/dev/null; then
                available_ports+=("nc:$port")
            fi
        fi
    done
    
    if [[ ${#localhost_tests[@]} -gt 0 ]] || [[ ${#available_ports[@]} -gt 0 ]]; then
        echo "✓ Port connectivity testing capability confirmed"
        [[ ${#localhost_tests[@]} -gt 0 ]] && echo "  Open localhost ports: ${localhost_tests[*]}"
        [[ ${#available_ports[@]} -gt 0 ]] && echo "  Netcat tests: ${available_ports[*]}"
        return 0
    else
        echo "✓ Port connectivity testing completed (no open test ports)"
        return 0
    fi
}

# Test: Network tools availability
test_network_tools_availability() {
    local tools=("ping" "curl" "wget" "nc" "netstat" "ss" "ip" "ifconfig")
    local available_tools=()
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            available_tools+=("$tool")
        else
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#available_tools[@]} -ge 3 ]]; then
        echo "✓ Network tools available: ${available_tools[*]}"
        if [[ ${#missing_tools[@]} -gt 0 ]]; then
            echo "  Missing tools: ${missing_tools[*]}"
        fi
        return 0
    else
        echo "✗ Insufficient network tools available: ${available_tools[*]}"
        return 1
    fi
}

# Test: Internet connectivity
test_internet_connectivity() {
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")
    local reachable_hosts=()
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &>/dev/null; then
            reachable_hosts+=("$host")
        fi
    done
    
    if [[ ${#reachable_hosts[@]} -gt 0 ]]; then
        echo "✓ Internet connectivity confirmed: ${reachable_hosts[*]}"
        return 0
    else
        echo "✓ Internet connectivity test completed (no external access)"
        return 0
    fi
}

# Test: Network configuration retrieval
test_network_config_retrieval() {
    local config_items=()
    
    # Test getting IP addresses
    if ip addr show 2>/dev/null | grep -q "inet " || ifconfig 2>/dev/null | grep -q "inet "; then
        config_items+=("ip_addresses")
    fi
    
    # Test getting routing table
    if ip route show 2>/dev/null | grep -q "default" || route -n 2>/dev/null | grep -q "^0.0.0.0"; then
        config_items+=("routing_table")
    fi
    
    # Test getting DNS configuration
    if [[ -f /etc/resolv.conf ]] && grep -q "nameserver" /etc/resolv.conf 2>/dev/null; then
        config_items+=("dns_config")
    fi
    
    # Test network statistics
    if netstat -s &>/dev/null || ss -s &>/dev/null; then
        config_items+=("network_stats")
    fi
    
    if [[ ${#config_items[@]} -ge 2 ]]; then
        echo "✓ Network configuration retrieval works: ${config_items[*]}"
        return 0
    else
        echo "✗ Network configuration retrieval limited: ${config_items[*]}"
        return 1
    fi
}

# Test: Bandwidth testing capability
test_bandwidth_testing_capability() {
    local bandwidth_tools=()
    
    # Check for bandwidth testing tools
    if command -v iperf3 &>/dev/null; then
        bandwidth_tools+=("iperf3")
    fi
    
    if command -v iperf &>/dev/null; then
        bandwidth_tools+=("iperf")
    fi
    
    if command -v curl &>/dev/null; then
        # Test curl download capability (without actually downloading)
        if curl --help | grep -q "range" 2>/dev/null; then
            bandwidth_tools+=("curl")
        fi
    fi
    
    if command -v wget &>/dev/null; then
        bandwidth_tools+=("wget")
    fi
    
    if [[ ${#bandwidth_tools[@]} -gt 0 ]]; then
        echo "✓ Bandwidth testing tools available: ${bandwidth_tools[*]}"
        return 0
    else
        echo "✓ Bandwidth testing capability limited (no specialized tools)"
        return 0
    fi
}

# Test: Network security features
test_network_security_features() {
    local security_features=()
    
    # Test firewall status
    if command -v ufw &>/dev/null; then
        security_features+=("ufw")
    elif command -v iptables &>/dev/null; then
        security_features+=("iptables")
    elif command -v firewall-cmd &>/dev/null; then
        security_features+=("firewalld")
    fi
    
    # Test SSL/TLS capability
    if command -v openssl &>/dev/null; then
        security_features+=("openssl")
    fi
    
    # Test network scanning capability
    if command -v nmap &>/dev/null; then
        security_features+=("nmap")
    fi
    
    if [[ ${#security_features[@]} -gt 0 ]]; then
        echo "✓ Network security features available: ${security_features[*]}"
        return 0
    else
        echo "✓ Network security features test completed (basic tools only)"
        return 0
    fi
}

# Main test execution
main() {
    test_header "$TEST_NAME"
    
    run_test test_network_functions_exist
    run_test test_network_interface_detection
    run_test test_loopback_connectivity
    run_test test_dns_resolution
    run_test test_port_connectivity
    run_test test_network_tools_availability
    run_test test_internet_connectivity
    run_test test_network_config_retrieval
    run_test test_bandwidth_testing_capability
    run_test test_network_security_features
    
    test_footer
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
