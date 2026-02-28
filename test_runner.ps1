# SyncLayer Test Runner Script (PowerShell)
# Runs tests with proper setup and generates coverage reports

param(
    [string]$TestType = "all",
    [string]$Coverage = "true"
)

Write-Host "🧪 SyncLayer Test Runner" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

function Print-Status {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Print-Status "Flutter found: $flutterVersion"
    Write-Host ""
} catch {
    Print-Error "Flutter is not installed or not in PATH"
    exit 1
}

# Run tests based on type
$testExitCode = 0

switch ($TestType) {
    "unit" {
        Write-Host "Running Unit Tests..." -ForegroundColor Cyan
        flutter test test/unit/ --reporter expanded
        $testExitCode = $LASTEXITCODE
    }
    "integration" {
        Write-Host "Running Integration Tests..." -ForegroundColor Cyan
        flutter test test/integration/ --reporter expanded
        $testExitCode = $LASTEXITCODE
    }
    "stress" {
        Write-Host "Running Stress Tests..." -ForegroundColor Cyan
        Print-Warning "Stress tests may take several minutes..."
        flutter test test/stress/ --reporter expanded
        $testExitCode = $LASTEXITCODE
    }
    "quick" {
        Write-Host "Running Quick Tests (Unit + Integration)..." -ForegroundColor Cyan
        flutter test test/unit/ test/integration/ --reporter expanded
        $testExitCode = $LASTEXITCODE
    }
    "all" {
        Write-Host "Running All Tests..." -ForegroundColor Cyan
        if ($Coverage -eq "true") {
            Print-Status "Coverage enabled"
            flutter test --coverage --reporter expanded
        } else {
            flutter test --reporter expanded
        }
        $testExitCode = $LASTEXITCODE
    }
    default {
        Print-Error "Unknown test type: $TestType"
        Write-Host "Usage: .\test_runner.ps1 [-TestType unit|integration|stress|quick|all] [-Coverage true|false]"
        exit 1
    }
}

Write-Host ""
if ($testExitCode -eq 0) {
    Print-Status "All tests passed!"
} else {
    Print-Error "Some tests failed (exit code: $testExitCode)"
}

# Generate coverage report if enabled
if (($Coverage -eq "true") -and ($TestType -eq "all") -and (Test-Path "coverage/lcov.info")) {
    Write-Host ""
    Write-Host "📊 Generating Coverage Report..." -ForegroundColor Cyan
    
    # Check if genhtml is available (from lcov package)
    $genhtmlPath = Get-Command genhtml -ErrorAction SilentlyContinue
    
    if ($genhtmlPath) {
        # Generate HTML report
        genhtml coverage/lcov.info -o coverage/html --quiet
        Print-Status "Coverage report generated: coverage/html/index.html"
        
        # Open coverage report
        Start-Process "coverage/html/index.html"
    } else {
        Print-Warning "genhtml not installed. Install lcov to generate HTML reports."
        Print-Status "Raw coverage data available at: coverage/lcov.info"
        Write-Host "You can view coverage in VS Code with the Coverage Gutters extension"
    }
}

Write-Host ""
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Test run complete!"
exit $testExitCode
