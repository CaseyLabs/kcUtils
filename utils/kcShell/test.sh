#!/bin/bash

# Test script for kcShell

# Function to run a test and report results
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_output="$3"

    echo "Running test: $test_name"
    local output
    output=$(eval "$command")
    
    if [ "$output" = "$expected_output" ]; then
        echo "  PASS"
    else
        echo "  FAIL"
        echo "    Expected: $expected_output"
        echo "    Got:      $output"
    fi
    echo
}

# Test kc_version
run_test "kc_version" "kc version" "kcShell v24.10.06"

# Test kc_log
run_test "kc_log info" "kc log info 'Test message'" "$(date +"%Y-%m-%dT%H:%M:%SZ") | $HOSTNAME | [info] Test message"

# Test kc_check for existing file
touch test_file
run_test "kc_check existing file" "kc check test_file" "File or folder exists: test_file"
rm test_file

# Test kc_check for non-existing file
run_test "kc_check non-existing file" "kc check nonexistent_file" "Could not find: nonexistent_file"

# Test kc_os info
run_test "kc_os info" "kc os info" "Operating System: kcOS = $(grep '^ID=' /etc/os-release | cut -f2 -d'=' 2>/dev/null || uname)
Architecture: kcArch = $(uname -m)
OS Like: kcOSLIKE = $(grep '^ID_LIKE=' /etc/os-release | cut -f2 -d'=' 2>/dev/null || uname)"

# Test kc_help
run_test "kc_help" "kc help" "$(kc help)"

echo "All tests completed."