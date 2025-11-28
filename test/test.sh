#!/bin/bash
# Full test suite including terraform plan
# This script requires AWS credentials and OCM token

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
    checkov -d . --framework terraform --skip-check CKV_TF_1,CKV_AWS_130 --quiet || {
        echo "ERROR: checkov security scan failed" >&2
        exit 1
    }
else
    echo "⚠ checkov not found (optional - install with: pip install checkov)"
fi

echo "Running Terraform plan..."
terraform plan -out=main.plan || { echo "ERROR: Terraform plan failed" >&2; exit 1; }

echo ""
echo "✓ All tests passed!"
