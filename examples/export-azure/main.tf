resource "azurerm_resource_group" "res-0" {
  location = "northeurope"
  name     = "synapsemanagedvnet-example-rg"
}
resource "azurerm_storage_account" "res-1" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  is_hns_enabled           = true
  location                 = "northeurope"
  name                     = "synapseexampleqmwqotst"
  resource_group_name      = "synapsemanagedvnet-example-rg"
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}
resource "azurerm_storage_container" "res-3" {
  name                 = "synapse"
  storage_account_name = "synapseexampleqmwqotst"
}
resource "azurerm_synapse_workspace" "res-7" {
  data_exfiltration_protection_enabled = true
  location                             = "northeurope"
  managed_virtual_network_enabled      = true
  name                                 = "synapseexampleqmwqot-synw"
  resource_group_name                  = "synapsemanagedvnet-example-rg"
  sql_administrator_login              = "sqladminuser"
  sql_identity_control_enabled         = true
  storage_data_lake_gen2_filesystem_id = "https://synapseexampleqmwqotst.dfs.core.windows.net/synapse"
  tags = {
    ManagedByTerraform = "True"
  }
  identity {
    type = "SystemAssigned"
  }
  depends_on = [
    azurerm_resource_group.res-0,
  ]
}
resource "azurerm_synapse_workspace_extended_auditing_policy" "res-11" {
  log_monitoring_enabled = false
  synapse_workspace_id   = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw"
  depends_on = [
    azurerm_synapse_workspace.res-7,
  ]
}
resource "azurerm_synapse_integration_runtime_azure" "res-12" {
  location             = "AutoResolve"
  name                 = "AutoResolveIntegrationRuntime"
  synapse_workspace_id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw"
  depends_on = [
    azurerm_synapse_workspace.res-7,
  ]
}
resource "azurerm_synapse_workspace_security_alert_policy" "res-13" {
  policy_state         = "Disabled"
  synapse_workspace_id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw"
  depends_on = [
    azurerm_synapse_workspace.res-7,
  ]
}
resource "azurerm_synapse_workspace_vulnerability_assessment" "res-14" {
  storage_container_path             = ""
  workspace_security_alert_policy_id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw/securityAlertPolicies/Default"
  depends_on = [
    azurerm_synapse_workspace_security_alert_policy.res-13,
  ]
}
