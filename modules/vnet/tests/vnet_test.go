package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestVnetModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/basic",
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	vnetName := terraform.Output(t, terraformOptions, "vnet_name")
	assert.Equal(t, "test-basic-vnet", vnetName)

	subnetIDs := terraform.OutputMap(t, terraformOptions, "subnet_ids")
	assert.Contains(t, subnetIDs, "web")
	assert.Contains(t, subnetIDs, "app")

	vnetID := terraform.Output(t, terraformOptions, "vnet_id")
	assert.NotEmpty(t, vnetID)
}

func TestVnetModuleWithNSG(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./fixtures/with_nsg",
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	nsgIDs := terraform.OutputMap(t, terraformOptions, "nsg_ids")
	assert.Contains(t, nsgIDs, "web", "NSG should be created for subnet with rules")
	assert.NotContains(t, nsgIDs, "data", "No NSG for subnet without rules")
}
