import {
  id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg"
  to = azurerm_resource_group.res-0
}
import {
  id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Storage/storageAccounts/synapseexampleqmwqotst"
  to = azurerm_storage_account.res-1
}
import {
  id = "https://synapseexampleqmwqotst.blob.core.windows.net/synapse"
  to = azurerm_storage_container.res-3
}
import {
  id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw"
  to = azurerm_synapse_workspace.res-7
}
import {
  id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw/extendedAuditingSettings/Default"
  to = azurerm_synapse_workspace_extended_auditing_policy.res-11
}
import {
  id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw/integrationRuntimes/AutoResolveIntegrationRuntime"
  to = azurerm_synapse_integration_runtime_azure.res-12
}
import {
  id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw/securityAlertPolicies/Default"
  to = azurerm_synapse_workspace_security_alert_policy.res-13
}
import {
  id = "/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourceGroups/synapsemanagedvnet-example-rg/providers/Microsoft.Synapse/workspaces/synapseexampleqmwqot-synw/vulnerabilityAssessments/Default"
  to = azurerm_synapse_workspace_vulnerability_assessment.res-14
}
