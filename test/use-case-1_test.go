package test

import (
	"strings"
	"testing"
	"github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestLambda(t *testing.T) {
	// retryable errors in terraform testing.
	t.Log("Starting lambda module test")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/uce-case-1",
		NoColor:      false,
		Lock:         true,
		Vars: map[string]interface{}{
			"function_name": "test_lambda",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	lambda_Arn := terraform.Output(t, terraformOptions, "lambda_arn")
	if strings.Contains(lambda_Arn, "test_lambda") {
		t.Log("PASSED: lambda_arn contains \"test_lambda\"")
	} else {
		t.Errorf("FAILED: expected lambda_arn to contain \"test_lambda\"")
	}

}
