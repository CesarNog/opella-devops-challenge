package integration

import (
	"encoding/json"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// planOutput holds the JSON structure of `terraform show -json <planfile>`
type planOutput struct {
	PlannedValues struct {
		RootModule struct {
			Resources []struct {
				Type   string                 `json:"type"`
				Name   string                 `json:"name"`
				Values map[string]interface{} `json:"values"`
			} `json:"resources"`
			ChildModules []struct {
				Address   string `json:"address"`
				Resources []struct {
					Type   string                 `json:"type"`
					Name   string                 `json:"name"`
					Values map[string]interface{} `json:"values"`
				} `json:"resources"`
			} `json:"child_modules"`
		} `json:"root_module"`
	} `json:"planned_values"`
	ResourceChanges []struct {
		Type   string `json:"type"`
		Name   string `json:"name"`
		Change struct {
			Actions []string `json:"actions"`
		} `json:"change"`
	} `json:"resource_changes"`
}

func loadPlanJSON(t *testing.T, envDir string) planOutput {
	t.Helper()

	opts := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: envDir,
		PlanFilePath: envDir + "/test.tfplan",
	})

	terraform.InitAndPlanAndShowWithStruct(t, opts)
	planJSON := terraform.InitAndPlanAndShow(t, opts)

	var plan planOutput
	require.NoError(t, json.Unmarshal([]byte(planJSON), &plan))
	return plan
}

type planResource struct {
	Type   string
	Name   string
	Values map[string]interface{}
}

func allResources(plan planOutput) []planResource {
	var resources []planResource
	for _, r := range plan.PlannedValues.RootModule.Resources {
		resources = append(resources, planResource{r.Type, r.Name, r.Values})
	}
	for _, m := range plan.PlannedValues.RootModule.ChildModules {
		for _, r := range m.Resources {
			resources = append(resources, planResource{r.Type, r.Name, r.Values})
		}
	}
	return resources
}

// TestDevPlanResourceCount verifies the expected number of resources in dev
func TestDevPlanResourceCount(t *testing.T) {
	planFile := os.Getenv("DEV_PLAN_JSON")
	if planFile == "" {
		t.Skip("Set DEV_PLAN_JSON to the path of dev plan JSON to run this test")
	}

	data, err := os.ReadFile(planFile)
	require.NoError(t, err)

	var plan planOutput
	require.NoError(t, json.Unmarshal(data, &plan))

	resourceCount := 0
	for _, rc := range plan.ResourceChanges {
		for _, action := range rc.Change.Actions {
			if action == "create" || action == "no-op" {
				resourceCount++
			}
		}
	}
	assert.GreaterOrEqual(t, resourceCount, 17, "Dev environment should manage at least 17 resources")
}

// TestDevPlanNamingConvention checks all named resources follow the naming pattern
func TestDevPlanNamingConvention(t *testing.T) {
	planFile := os.Getenv("DEV_PLAN_JSON")
	if planFile == "" {
		t.Skip("Set DEV_PLAN_JSON to the path of dev plan JSON to run this test")
	}

	data, err := os.ReadFile(planFile)
	require.NoError(t, err)

	var plan planOutput
	require.NoError(t, json.Unmarshal(data, &plan))

	resources := allResources(plan)
	for _, r := range resources {
		name, ok := r.Values["name"].(string)
		if !ok {
			continue
		}

		// Skip resources that don't follow the prefix pattern
		skipTypes := map[string]bool{
			"azurerm_subnet":                                    true,
			"azurerm_storage_container":                         true,
			"azurerm_subnet_network_security_group_association": true,
			"azurerm_role_assignment":                           true,
			"azurerm_key_vault_secret":                          true,
			"tls_private_key":                                   true,
		}
		if skipTypes[r.Type] {
			continue
		}

		assert.True(t,
			strings.Contains(name, "opella") && strings.Contains(name, "dev"),
			"Resource %s '%s' (name=%s) should contain project and environment in its name",
			r.Type, r.Name, name,
		)
	}
}

// TestDevPlanSecuritySettings verifies security configurations in the plan
func TestDevPlanSecuritySettings(t *testing.T) {
	planFile := os.Getenv("DEV_PLAN_JSON")
	if planFile == "" {
		t.Skip("Set DEV_PLAN_JSON to the path of dev plan JSON to run this test")
	}

	data, err := os.ReadFile(planFile)
	require.NoError(t, err)

	var plan planOutput
	require.NoError(t, json.Unmarshal(data, &plan))

	resources := allResources(plan)

	for _, r := range resources {
		switch r.Type {
		case "azurerm_storage_account":
			assert.Equal(t, "TLS1_2", r.Values["min_tls_version"],
				"Storage account must enforce TLS 1.2")
			assert.Equal(t, false, r.Values["allow_nested_items_to_be_public"],
				"Storage account must not allow public blob access")

		case "azurerm_linux_virtual_machine":
			assert.Equal(t, true, r.Values["disable_password_authentication"],
				"VM must disable password authentication")

		case "azurerm_key_vault":
			assert.Equal(t, true, r.Values["enable_rbac_authorization"],
				"Key Vault must use RBAC authorization")
		}
	}
}

// TestDevPlanTagsPresent verifies all taggable resources have required tags
func TestDevPlanTagsPresent(t *testing.T) {
	planFile := os.Getenv("DEV_PLAN_JSON")
	if planFile == "" {
		t.Skip("Set DEV_PLAN_JSON to the path of dev plan JSON to run this test")
	}

	data, err := os.ReadFile(planFile)
	require.NoError(t, err)

	var plan planOutput
	require.NoError(t, json.Unmarshal(data, &plan))

	requiredTags := []string{"environment", "project", "region", "managed_by"}
	skipTagCheck := map[string]bool{
		"tls_private_key":             true,
		"azurerm_role_assignment":     true,
		"azurerm_storage_container":   true,
		"azurerm_key_vault_secret":    true,
		"azurerm_subnet":              true,
		"azurerm_subnet_network_security_group_association": true,
	}
	resources := allResources(plan)

	for _, r := range resources {
		if skipTagCheck[r.Type] {
			continue
		}
		tagsRaw, hasTags := r.Values["tags"]
		if !hasTags {
			continue
		}
		tags, ok := tagsRaw.(map[string]interface{})
		if !ok {
			continue
		}

		for _, tag := range requiredTags {
			_, exists := tags[tag]
			assert.True(t, exists,
				"Resource %s '%s' is missing required tag '%s'",
				r.Type, r.Name, tag)
		}

		assert.Equal(t, "dev", tags["environment"],
			"Resource %s '%s' should have environment=dev", r.Type, r.Name)
		assert.Equal(t, "terraform", tags["managed_by"],
			"Resource %s '%s' should have managed_by=terraform", r.Type, r.Name)
	}
}

// TestProdPlanNoPublicIP verifies prod VM has no public IP
func TestProdPlanNoPublicIP(t *testing.T) {
	planFile := os.Getenv("PROD_PLAN_JSON")
	if planFile == "" {
		t.Skip("Set PROD_PLAN_JSON to the path of prod plan JSON to run this test")
	}

	data, err := os.ReadFile(planFile)
	require.NoError(t, err)

	var plan planOutput
	require.NoError(t, json.Unmarshal(data, &plan))

	for _, rc := range plan.ResourceChanges {
		assert.NotEqual(t, "azurerm_public_ip", rc.Type,
			"Prod environment should not have a public IP resource")
	}
}

// TestProdPlanRestrictedSSH verifies prod SSH is restricted to VNET
func TestProdPlanRestrictedSSH(t *testing.T) {
	planFile := os.Getenv("PROD_PLAN_JSON")
	if planFile == "" {
		t.Skip("Set PROD_PLAN_JSON to the path of prod plan JSON to run this test")
	}

	data, err := os.ReadFile(planFile)
	require.NoError(t, err)

	var plan planOutput
	require.NoError(t, json.Unmarshal(data, &plan))

	resources := allResources(plan)
	for _, r := range resources {
		if r.Type != "azurerm_network_security_group" {
			continue
		}
		rulesRaw, ok := r.Values["security_rule"]
		if !ok {
			continue
		}
		rules, ok := rulesRaw.([]interface{})
		if !ok {
			continue
		}
		for _, ruleRaw := range rules {
			rule, ok := ruleRaw.(map[string]interface{})
			if !ok {
				continue
			}
			if rule["destination_port_range"] == "22" && rule["access"] == "Allow" {
				src := rule["source_address_prefix"].(string)
				assert.NotEqual(t, "*", src,
					"Prod SSH rule must restrict source (got '%s')", src)
			}
		}
	}
}
