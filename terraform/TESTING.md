# Terraform Testing Guide

This document describes the test suite for the Terraform infrastructure code.

## Overview

The test suite uses Terraform's built-in testing framework (available in Terraform 1.6+) to validate:
- Variable validation rules
- Environment-specific configurations
- Output correctness
- Helm chart deployment settings

## Test Files

### `tests/variable_validation.tftest.hcl`
Tests all variable validations including:
- **project_id_validation**: Validates GCP project ID format
- **region_validation**: Validates GCP region format
- **cluster_name_validation**: Validates cluster name length constraints
- **namespace_validation**: Validates Kubernetes namespace naming conventions
- **environment_validation**: Validates environment values (dev, staging, production)

### `tests/dev.tftest.hcl`
Development environment-specific tests:
- **development_environment_validation**: Ensures dev environment uses correct configurations
- **dev_output_validation**: Verifies output values match input variables

### `tests/staging.tftest.hcl`
Staging environment-specific tests:
- **staging_environment_validation**: Validates staging-specific settings
- **staging_namespace_validation**: Ensures staging uses dedicated namespace

### `tests/production.tftest.hcl`
Production environment-specific tests:
- **production_environment_validation**: Validates production deployment settings
- **production_strict_validation**: Enforces strict rules for production (no 'latest' tags)

### `tests/helm_release.tftest.hcl`
Helm chart deployment tests:
- **helm_release_configuration**: Validates Helm release naming and chart path
- **helm_values_override**: Tests custom values override functionality

## Running Tests

### Run All Tests
```bash
terraform test
```

### Run Specific Test File
```bash
terraform test tests/variable_validation.tftest.hcl
```

### Run Tests with Verbose Output
```bash
terraform test -verbose
```

### Run Tests and Display Plan Details
```bash
terraform test -json | jq .
```

### Run Specific Test Run
```bash
terraform test tests/dev.tftest.hcl -run="development_environment_validation"
```

## Test Execution

### Prerequisites
- Terraform 1.6+
- Valid GCP credentials (credentials file or GOOGLE_APPLICATION_CREDENTIALS environment variable)
- Existing GKE cluster (for apply tests; plan tests don't require this)

### Important Notes

1. **Plan vs Apply**: The tests use `command = plan` which validates configuration without making actual API calls or modifying resources.

2. **No Resource Creation**: These tests do not create actual GCP or Kubernetes resources. They validate the Terraform configuration.

3. **Mock Data**: Tests use fictional project IDs and cluster names. Actual values must exist in GCP for `apply` tests.

## Test Structure

Each test file contains one or more `run` blocks:

```hcl
run "test_name" {
  command = plan  # or apply

  variables {
    # Variables for this test run
  }

  assert {
    condition     = # Boolean condition to test
    error_message = "Human-readable error message"
  }
}
```

## Adding New Tests

To add a new test:

1. Create a new `run` block in the appropriate test file
2. Set variables relevant to your test
3. Add `assert` blocks to validate conditions
4. Ensure the error message is descriptive

Example:
```hcl
run "new_test_scenario" {
  command = plan

  variables {
    project_id           = "test-project-1"
    environment          = "dev"
    cluster_name         = "test-cluster"
    region               = "us-central1"
    kubernetes_namespace = "default"
    helm_release_name    = "mainwebsite"
    helm_chart_path      = "../helm-dir"
    mainwebsite_image_tag = "v1.0.0"
    metrics_image_tag     = "v1.0.0"
  }

  assert {
    condition     = your_validation_condition
    error_message = "Descriptive error message"
  }
}
```

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Terraform Tests
  run: |
    terraform test
```

### GitLab CI Example
```yaml
terraform_test:
  script:
    - terraform test
```

### Jenkins Example
```groovy
stage('Terraform Tests') {
  steps {
    sh 'terraform test'
  }
}
```

## Troubleshooting

### Test Fails with "Provider configuration not found"
Ensure the provider configuration in `main.tf` is correct and credentials are available.

### Test Fails with "Variable not set"
Add the variable to the test's `variables` block or ensure it has a default value in `variables.tf`.

### Test Fails with "Data source not found"
For `apply` tests, ensure the referenced GKE cluster actually exists in GCP.

## Best Practices

1. **Descriptive Names**: Use clear test names that describe what is being tested
2. **Focused Tests**: Each test should validate one specific aspect
3. **Consistent Variables**: Use consistent variable values across related tests
4. **Error Messages**: Write clear error messages that help diagnose failures
5. **Documentation**: Update this file when adding new tests
6. **Validation Rules**: Leverage the validation blocks in `variables.tf`

## See Also

- [Terraform Testing Documentation](https://www.terraform.io/language/tests)
- [GCP Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest)
- [Kubernetes Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/kubernetes/latest)
