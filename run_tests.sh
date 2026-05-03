#!/bin/bash

# ─────────────────────────────────────────────
#  Cylon Test Automation Script
#  Usage: bash run_tests.sh
# ─────────────────────────────────────────────

CYLON="./src/cylon.exe"
TESTS_VALID="./tests/valid"
TESTS_INVALID="./tests/invalid"
EXPECTED="./tests/expected"

PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         Cylon Automated Test Runner          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Run a single test ──
# $1 = test file path
# $2 = expected result (PASS or FAIL)
run_test() {
    local file=$1
    local expected=$2
    local name=$(basename "$file" .cylon)

    TOTAL=$((TOTAL + 1))

    # Run parser, capture exit code
    $CYLON "$file" > /dev/null 2>&1
    local exit_code=$?

    # exit code 0 = PASS, non-zero = FAIL
    if [ $exit_code -eq 0 ]; then
        actual="PASS"
    else
        actual="FAIL"
    fi

    if [ "$actual" == "$expected" ]; then
        echo -e "  ${GREEN}[PASS]${NC} $name"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}[FAIL]${NC} $name  (expected: $expected | got: $actual)"
        FAIL=$((FAIL + 1))
    fi
}

# ── Valid tests - all should exit 0 (PASS) ──
echo -e "${CYAN}--- Valid Tests (should all PASS) ---${NC}"
for f in "$TESTS_VALID"/*.cylon; do
    name=$(basename "$f" .cylon)
    expected_file="$EXPECTED/$name.txt"
    if [ -f "$expected_file" ]; then
        expected=$(cat "$expected_file" | tr -d '[:space:]')
    else
        expected="PASS"
    fi
    run_test "$f" "$expected"
done

echo ""

# ── Invalid tests - all should exit non-zero (FAIL) ──
echo -e "${CYAN}--- Invalid Tests (should all FAIL) ---${NC}"
for f in "$TESTS_INVALID"/*.cylon; do
    name=$(basename "$f" .cylon)
    expected_file="$EXPECTED/$name.txt"
    if [ -f "$expected_file" ]; then
        expected=$(cat "$expected_file" | tr -d '[:space:]')
    else
        expected="FAIL"
    fi
    run_test "$f" "$expected"
done

echo ""
echo "╔══════════════════════════════════════════════╗"
echo -e "║  Results: ${GREEN}$PASS passed${NC} | ${RED}$FAIL failed${NC} | $TOTAL total"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Exit with failure if any test failed
if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0