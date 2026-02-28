#!/bin/bash

# SyncLayer Test Runner Script
# Runs tests with proper setup and generates coverage reports

set -e

echo "🧪 SyncLayer Test Runner"
echo "========================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter found: $(flutter --version | head -n 1)"
echo ""

# Parse command line arguments
TEST_TYPE="${1:-all}"
COVERAGE="${2:-true}"

case $TEST_TYPE in
    "unit")
        echo "Running Unit Tests..."
        flutter test test/unit/ --reporter expanded
        ;;
    "integration")
        echo "Running Integration Tests..."
        flutter test test/integration/ --reporter expanded
        ;;
    "stress")
        echo "Running Stress Tests..."
        print_warning "Stress tests may take several minutes..."
        flutter test test/stress/ --reporter expanded
        ;;
    "quick")
        echo "Running Quick Tests (Unit + Integration)..."
        flutter test test/unit/ test/integration/ --reporter expanded
        ;;
    "all")
        echo "Running All Tests..."
        if [ "$COVERAGE" = "true" ]; then
            print_status "Coverage enabled"
            flutter test --coverage --reporter expanded
        else
            flutter test --reporter expanded
        fi
        ;;
    *)
        print_error "Unknown test type: $TEST_TYPE"
        echo "Usage: ./test_runner.sh [unit|integration|stress|quick|all] [coverage]"
        exit 1
        ;;
esac

TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    print_status "All tests passed!"
else
    print_error "Some tests failed (exit code: $TEST_EXIT_CODE)"
fi

# Generate coverage report if enabled
if [ "$COVERAGE" = "true" ] && [ "$TEST_TYPE" = "all" ] && [ -f "coverage/lcov.info" ]; then
    echo ""
    echo "📊 Generating Coverage Report..."
    
    # Check if lcov is installed
    if command -v lcov &> /dev/null; then
        # Generate HTML report
        genhtml coverage/lcov.info -o coverage/html --quiet
        print_status "Coverage report generated: coverage/html/index.html"
        
        # Calculate coverage percentage
        COVERAGE_PERCENT=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}')
        echo "📈 Line Coverage: $COVERAGE_PERCENT"
        
        # Open coverage report (macOS/Linux)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/html/index.html
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open coverage/html/index.html 2>/dev/null || true
        fi
    else
        print_warning "lcov not installed. Install with: brew install lcov (macOS) or apt-get install lcov (Linux)"
        print_status "Raw coverage data available at: coverage/lcov.info"
    fi
fi

echo ""
echo "========================"
echo "Test run complete!"
exit $TEST_EXIT_CODE
