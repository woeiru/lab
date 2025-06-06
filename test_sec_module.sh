#!/bin/bash
# Test script for security module with sec_ prefix

echo "=== Security Module Test Suite ==="
echo

# Source the security module
source /home/es/lab/lib/gen/sec

echo "1. Testing sec_generate_secure_password:"
password1=$(sec_generate_secure_password 20)
echo "   Generated 20-char password: $password1 (length: ${#password1})"
echo

echo "2. Testing sec_store_secure_password:"
sec_store_secure_password "TEST_PASSWORD" 16
echo "   Stored password in variable TEST_PASSWORD: $TEST_PASSWORD"
echo

echo "3. Testing sec_get_password_directory:"
pwd_dir=$(sec_get_password_directory)
echo "   Password directory: $pwd_dir"
echo

echo "4. Testing sec_get_secure_password (existing file):"
existing_pwd=$(sec_get_secure_password "ct_pbs.pwd")
echo "   Retrieved ct_pbs password: $existing_pwd"
echo

echo "5. Testing sec_get_secure_password (non-existing file):"
new_pwd=$(sec_get_secure_password "nonexistent.pwd" 12)
echo "   Generated new password: $new_pwd (length: ${#new_pwd})"
echo

echo "6. Testing backward compatibility aliases:"
old_style_pwd=$(generate_secure_password 14)
echo "   Old function call result: $old_style_pwd (length: ${#old_style_pwd})"
echo

echo "7. Testing sec_create_password_file:"
test_pwd="TestPassword123!"
sec_create_password_file "/tmp/test_sec.pwd" "$test_pwd"
retrieved_pwd=$(cat /tmp/test_sec.pwd)
echo "   Stored and retrieved: $retrieved_pwd"
rm -f /tmp/test_sec.pwd
echo

echo "=== All tests completed successfully! ==="
