#!/bin/sh

# Test script for kcShell.

KC_SCRIPT=${KC_SCRIPT:-./kcshell.sh}
KC_HOST=$(uname -n 2>/dev/null || hostname 2>/dev/null || printf "unknown")
failures=0
tmp_dir=$(mktemp -d) || exit 1

trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

run_test() {
  test_name=$1
  expected_status=$2
  expected_output=$3
  shift 3

  printf "Running test: %s\n" "$test_name"
  output=$("$@" 2>&1)
  actual_status=$?

  if [ "$actual_status" -eq "$expected_status" ] && [ "$output" = "$expected_output" ]; then
    printf "  PASS\n\n"
    return 0
  fi

  printf "  FAIL\n"
  printf "    Expected status: %s\n" "$expected_status"
  printf "    Got status:      %s\n" "$actual_status"
  printf "    Expected: %s\n" "$expected_output"
  printf "    Got:      %s\n\n" "$output"
  failures=$((failures + 1))
}

run_match() {
  test_name=$1
  expected_status=$2
  expected_pattern=$3
  shift 3

  printf "Running test: %s\n" "$test_name"
  output=$("$@" 2>&1)
  actual_status=$?

  if [ "$actual_status" -eq "$expected_status" ] && printf "%s\n" "$output" | grep -Eq "$expected_pattern"; then
    printf "  PASS\n\n"
    return 0
  fi

  printf "  FAIL\n"
  printf "    Expected status:  %s\n" "$expected_status"
  printf "    Got status:       %s\n" "$actual_status"
  printf "    Expected pattern: %s\n" "$expected_pattern"
  printf "    Got:              %s\n\n" "$output"
  failures=$((failures + 1))
}

expected_os_info="Operating System: kcOS = $(grep '^ID=' /etc/os-release | cut -f2 -d'=' 2>/dev/null || uname)
Architecture: kcArch = $(uname -m)
OS Like: kcOSLIKE = $(grep '^ID_LIKE=' /etc/os-release | cut -f2 -d'=' 2>/dev/null || uname)"

test_file="$tmp_dir/test_file"
touch "$test_file"

run_test "kc version" 0 "kcShell v24.10.06" "$KC_SCRIPT" version
run_match "kc log info" 0 "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z \\| $KC_HOST \\| \\[info\\] Test message$" "$KC_SCRIPT" log info "Test message"
run_test "kc check existing file" 0 "File or folder exists: $test_file" "$KC_SCRIPT" check "$test_file"
run_test "kc check non-existing file" 1 "Could not find: $tmp_dir/nonexistent_file" "$KC_SCRIPT" check "$tmp_dir/nonexistent_file"
run_match "kc help" 0 "Available commands:" "$KC_SCRIPT" help
run_match "kc help find" 0 "Usage: kc find \\[target\\] \\[search-word\\]" "$KC_SCRIPT" help find
run_test "kc os info" 0 "$expected_os_info" "$KC_SCRIPT" os info
run_match "kc update unknown" 1 "Unknown command: update" "$KC_SCRIPT" update
run_match "kc list unknown" 1 "Unknown command: list" "$KC_SCRIPT" list

if command -v zsh >/dev/null 2>&1; then
  run_match "kc find under zsh" 0 "kcshell\\.sh" zsh "$KC_SCRIPT" find . kcshell.sh
fi

if [ "$failures" -eq 0 ]; then
  printf "All tests passed.\n"
else
  printf "%s test(s) failed.\n" "$failures"
  exit 1
fi
