output "id" {
  value = azurerm_synapse_workspace.default.id
}

output "name" {
  value = azurerm_synapse_workspace.default.name
}

output "connectivity_endpoints" {
  value = azurerm_synapse_workspace.default.connectivity_endpoints
}

output "managed_resource_group_name" {
  value = azurerm_synapse_workspace.default.managed_resource_group_name
}

output "sql_pool_ids" {
  value = { for key, value in azurerm_synapse_sql_pool.default : value.name => value.id }
}

output "self_hosted_ir_ids" {
  value = { for key, value in azurerm_synapse_integration_runtime_self_hosted.default : value.name => value.id }
}

output "azure_ir_ids" {
  value = { for key, value in azurerm_synapse_integration_runtime_azure.default : value.name => value.id }
}

output "self_hosted_ir_keys" {
  value = { for key, value in azurerm_synapse_integration_runtime_self_hosted.default : value.name => { authorization_key_primary = value.authorization_key_primary, authorization_key_secondary = value.authorization_key_secondary } }
}
