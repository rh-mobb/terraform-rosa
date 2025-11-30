#!/bin/bash
# Pre-commit checks (skips terraform plan)
# This script does not require AWS credentials

set -e

echo "Running Terraform validate..."
terraform validate || { echo "ERROR: Terraform validate failed" >&2; exit 1; }

echo "Running Terraform fmt -check..."
terraform fmt -check -recursive || {
    echo "ERROR: Terraform fmt -check failed. Run 'terraform fmt -recursive' to fix." >&2
    exit 1
}

if command -v tflint >/dev/null 2>&1; then
    echo "Running tflint..."
    tflint --init || true
    tflint || { echo "ERROR: tflint failed" >&2; exit 1; }
else
    echo "⚠ tflint not found (optional - install with: brew install tflint)"
fi

if command -v checkov >/dev/null 2>&1; then
    echo "Running checkov security scan..."
    checkov -d . --framework terraform --quiet || {
        echo "ERROR: checkov security scan failed" >&2
        exit 1
    }
else
    echo "⚠ checkov not found (optional - install with: pip install checkov)"
fi

echo ""
echo "✓ All pre-commit checks passed! (plan skipped - use 'make test' for full test suite)"
