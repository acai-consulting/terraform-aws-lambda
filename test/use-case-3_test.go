package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestLambdaUC3(t *testing.T) {
	// retryable errors in terraform testing.
	t.Log("Starting lambda module test")

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/use-case-3",
		NoColor:      false,
		Lock:         true,
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	lambdaResultOutput1 := terraform.OutputMap(t, terraformOptions, "use_case_3_lambda1_result")
	t.Logf("Lambda Output1: %s", lambdaResultOutput1)

	// Extract the statusCode and assert it
	statusCode1 := lambdaResultOutput1["statusCode"]
	// Print the status code
	t.Logf("Derived StatusCode1: %s", statusCode1)
	assert.Equal(t, "200", statusCode1, "Expected statusCode to be 200")

	lambdaResultOutput2 := terraform.OutputMap(t, terraformOptions, "use_case_3_lambda2_result")
	t.Logf("Lambda Output2: %s", lambdaResultOutput2)

	// Extract the statusCode and assert it
	statusCode2 := lambdaResultOutput2["statusCode"]
	// Print the status code
	t.Logf("Derived StatusCode: %s", statusCode2)
	assert.Equal(t, "200", statusCode2, "Expected statusCode to be 200")
}
