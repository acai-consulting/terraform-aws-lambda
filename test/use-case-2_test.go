package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestLambdaUC2(t *testing.T) {
	// retryable errors in terraform testing.
	t.Log("Starting lambda module test")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/use-case-2",
		NoColor:      false,
		Lock:         true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	lambdaResultOutput := terraform.OutputMap(t, terraformOptions, "use_case_2_lambda_result")
	t.Logf("Lambda Output: %s", lambdaResultOutput)

	// Extract the statusCode and assert it
	statusCode := lambdaResultOutput["statusCode"]
	// Print the status code
	t.Logf("Derived StatusCode: %s", statusCode)
	assert.Equal(t, "200", statusCode, "Expected statusCode to be 200")
}
