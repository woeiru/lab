#!/bin/bash

# Test edge cases for aux_use function
source /home/es/lab/lib/gen/aux

# Test function without proper comments
test_no_comments() {
    aux_use
}

# Test function with missing description
# missing description test
# param1 param2
test_missing_description() {
    aux_use
}

#Test function with only one comment line
test_one_comment() {
    aux_use
}

# Test function with 'function' keyword
# test with function keyword
# function test
# param1
function test_function_keyword() {
    aux_use
}

# Test function called directly (not from a function)
echo "=== Testing edge cases ==="

echo ""
echo "1. Function without proper comments:"
test_no_comments

echo ""  
echo "2. Function with missing description:"
test_missing_description

echo ""
echo "3. Function with only one comment:"
test_one_comment

echo ""
echo "4. Function declared with 'function' keyword:"
test_function_keyword

echo ""
echo "5. Calling aux_use directly (should show help):"
aux_use
