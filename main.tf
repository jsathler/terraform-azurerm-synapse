locals {
  tags = merge(var.tags, { ManagedByTerraform = "True" })
}

###########
# Creates data lake file system if an existing filesystem_id is not provided
###########
resource "azurerm_storage_data_lake_gen2_filesystem" "default" {
  count              = var.workspace.storage_account_filesystem_id == null ? 1 : 0
  name               = var.workspace.storage_account_filesystem_name
  storage_account_id = var.workspace.storage_account_id
}

###########
# Synapse Workspace
###########

resource "azurerm_synapse_workspace" "default" {
  name                                 = "${var.workspace.name}-synw"
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = var.workspace.storage_account_filesystem_id != null ? var.workspace.storage_account_filesystem_id : azurerm_storage_data_lake_gen2_filesystem.default[0].id

  sql_administrator_login              = var.workspace.sql_administrator_login
  sql_administrator_login_password     = var.workspace.sql_administrator_login_password
  sql_identity_control_enabled         = var.workspace.sql_identity_control_enabled
  compute_subnet_id                    = var.workspace.compute_subnet_id
  data_exfiltration_protection_enabled = var.workspace.data_exfiltration_protection_enabled
  linking_allowed_for_aad_tenant_ids   = var.workspace.linking_allowed_for_aad_tenant_ids
  managed_resource_group_name          = var.workspace.managed_resource_group_name
  managed_virtual_network_enabled      = var.workspace.managed_virtual_network_enabled
  public_network_access_enabled        = var.workspace.public_network_access_enabled
  purview_id                           = var.workspace.purview_id
  tags                                 = local.tags

  dynamic "identity" {
    for_each = var.workspace.identity == null ? [] : [var.workspace.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "aad_admin" {
    for_each = var.workspace.aad_admin == null ? [] : [var.workspace.aad_admin]
    content {
      login     = aad_admin.value.login
      object_id = aad_admin.value.object_id
      tenant_id = aad_admin.value.tenant_id
    }
  }

  dynamic "azure_devops_repo" {
    for_each = var.workspace.azure_devops_repo == null ? [] : [var.workspace.azure_devops_repo]
    content {
      account_name    = azure_devops_repo.value.account_name
      branch_name     = azure_devops_repo.value.branch_name
      last_commit_id  = azure_devops_repo.value.last_commit_id
      project_name    = azure_devops_repo.value.project_name
      repository_name = azure_devops_repo.value.repository_name
      root_folder     = azure_devops_repo.value.root_folder
      tenant_id       = azure_devops_repo.value.tenant_id
    }
  }

  dynamic "github_repo" {
    for_each = var.workspace.github_repo == null ? [] : [var.workspace.github_repo]
    content {
      account_name    = github_repo.value.account_name
      branch_name     = github_repo.value.branch_name
      last_commit_id  = github_repo.value.last_commit_id
      repository_name = github_repo.value.repository_name
      root_folder     = github_repo.value.root_folder
      git_url         = github_repo.value.git_url
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.workspace.customer_managed_key == null ? [] : [var.workspace.customer_managed_key]
    content {
      key_versionless_id = customer_managed_key.value.key_versionless_id
      key_name           = customer_managed_key.value.key_name
    }
  }

  dynamic "sql_aad_admin" {
    for_each = var.workspace.sql_aad_admin == null ? [] : [var.workspace.sql_aad_admin]
    content {
      login     = sql_aad_admin.value.login
      object_id = sql_aad_admin.value.object_id
      tenant_id = sql_aad_admin.value.tenant_id
    }
  }
}

locals {
  firewall_rules = var.workspace.allow_azure_services && var.workspace.public_network_access_enabled ? merge(var.workspace.firewall_rules,
  { AllowAllWindowsAzureIps = { start_ip_address = "0.0.0.0", end_ip_address = "0.0.0.0" } }) : var.workspace.firewall_rules
}

resource "azurerm_synapse_firewall_rule" "default" {
  for_each             = local.firewall_rules == null ? {} : { for key, value in local.firewall_rules : key => value if var.workspace.public_network_access_enabled }
  name                 = each.key == "AllowAllWindowsAzureIps" ? each.key : "${each.key}-syfw"
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  start_ip_address     = each.value.start_ip_address
  end_ip_address       = each.value.end_ip_address
}

/*
Assigns permission on provided Storage account to the Synapse Workspace System Managed Identity
"Reader" on Storage account and "Storage Blob Data Owner" on container is an alternative
*/
resource "azurerm_role_assignment" "default" {
  scope                = var.workspace.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.default.identity[0].principal_id
}

/*
Synapse Access Control
Creating a list with role name and principal id
*/
locals {
  access_control = var.workspace.access_control == null ? [] : flatten([for key, value in var.workspace.access_control : [
    for principal_id in value : {
      role_name    = key
      principal_id = principal_id
    }
  ]])
}

resource "azurerm_synapse_role_assignment" "roles" {
  depends_on           = [azurerm_synapse_firewall_rule.default]
  for_each             = { for key, value in local.access_control : "${value.role_name}-${value.principal_id}" => value }
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  role_name            = each.value.role_name
  principal_id         = each.value.principal_id
}

# Azure AD only
resource "azapi_update_resource" "synapse_azuread_only_authentication" {
  type      = "Microsoft.Synapse/workspaces/azureADOnlyAuthentications@2021-06-01"
  name      = "default"
  parent_id = azurerm_synapse_workspace.default.id
  body = jsonencode({
    properties = {
      azureADOnlyAuthentication = var.workspace.azuread_only_authentication
    }
  })
}

# Trusted service bypass, but unfortunately it is not working ;(
# resource "azapi_update_resource" "synapse_trusted_service_bypass_enabled" {
#   count     = var.workspace.trusted_service_bypass_enabled ? 1 : 0
#   type      = "Microsoft.Synapse/workspaces/trustedServiceByPassConfiguration@2021-06-01-preview"
#   name      = "default"
#   parent_id = azurerm_synapse_workspace.default.id
# }

# resource "azapi_update_resource" "synapse_trusted_service_bypass_enabled" {
#   type        = "Microsoft.Synapse/workspaces/trustedServiceByPassConfiguration@2021-06-01-preview"
#   resource_id = "${azurerm_synapse_workspace.default.id}/trustedServiceByPassConfiguration/default"
#   body = jsonencode({
#     properties = {
#       trustedServiceBypassEnabled = var.workspace.trusted_service_bypass_enabled
#     }
#   })
# }

# resource "azapi_update_resource" "synapse_trusted_service_bypass_enabled" {
#   type        = "Microsoft.Synapse/workspaces/trustedServiceByPassConfiguration@2021-06-01"
#   resource_id = azurerm_synapse_workspace.default.id
#   body = jsonencode({
#     properties = {
#       trustedServiceBypassEnabled = var.workspace.azuread_only_authentication
#     }
#   })
# }

###########
# Integration Runtime
###########

resource "azurerm_synapse_integration_runtime_self_hosted" "default" {
  for_each             = { for key, value in var.irs : key => value if value.type == "Self-hosted" }
  name                 = "${each.key}-synirsh"
  description          = each.value.description
  synapse_workspace_id = azurerm_synapse_workspace.default.id
}

resource "azurerm_synapse_integration_runtime_azure" "default" {
  for_each             = { for key, value in var.irs : key => value if value.type == "Azure" }
  name                 = "${each.key}-synira"
  description          = each.value.description
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  location             = each.value.location
  compute_type         = each.value.compute_type
  core_count           = each.value.core_count
  time_to_live_min     = each.value.time_to_live_min
}

###########
# SQL and Spark Pools
###########
resource "azurerm_synapse_sql_pool" "default" {
  for_each                  = { for key, value in var.sql_pools : key => value }
  name                      = "${each.key}syndp"
  synapse_workspace_id      = azurerm_synapse_workspace.default.id
  sku_name                  = each.value.sku_name
  create_mode               = each.value.create_mode
  collation                 = each.value.collation
  data_encrypted            = each.value.data_encrypted
  geo_backup_policy_enabled = each.value.geo_backup_policy_enabled
  storage_account_type      = each.value.geo_backup_policy_enabled ? "GRS" : "LRS"
  tags                      = merge(local.tags, each.value.tags)
}

###########
# Create and approve managed private endpoint for Storage Account if storage_account_private_endpoint is set to true
###########

/*
Managed private endpoint
Unfortunately azurerm_synapse_managed_private_endpoint doesn't have the option to auto approve the private endpoint and it doesn't export the private endpoint name
We used azapi_resource to get private connections on Storage Account that match with private endpoint name created
*/
resource "azurerm_synapse_managed_private_endpoint" "default" {
  depends_on           = [azurerm_synapse_firewall_rule.default]
  count                = var.workspace.storage_account_private_endpoint ? 1 : 0
  name                 = "${split("/", var.workspace.storage_account_id)[8]}-synmpep"
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  target_resource_id   = var.workspace.storage_account_id
  subresource_name     = "blob"
}

data "azapi_resource" "storage_account_private_endpoint_approval" {
  depends_on             = [azurerm_synapse_managed_private_endpoint.default]
  count                  = var.workspace.storage_account_private_endpoint ? 1 : 0
  resource_id            = var.workspace.storage_account_id
  type                   = "Microsoft.Storage/storageAccounts@2022-09-01"
  response_export_values = ["properties.privateEndpointConnections"]
}

locals {
  private_endpoint_name = [for object in jsondecode(data.azapi_resource.storage_account_private_endpoint_approval[0].output).properties.privateEndpointConnections : object.name if strcontains(object.properties.privateEndpoint.id, "${azurerm_synapse_workspace.default.name}.${split("/", var.workspace.storage_account_id)[8]}-synmpep")]
}

resource "azapi_update_resource" "storage_account_private_endpoint_approval" {
  depends_on = [azurerm_synapse_managed_private_endpoint.default]
  count      = var.workspace.storage_account_private_endpoint ? 1 : 0
  type       = "Microsoft.Storage/storageAccounts/privateEndpointConnections@2022-09-01"
  name       = local.private_endpoint_name[0]
  parent_id  = var.workspace.storage_account_id

  body = jsonencode({
    properties = {
      privateEndpoint = {}
      privateLinkServiceConnectionState = {
        description = "Synapse Managed Network Endpoint"
        status      = "Approved"
      }
    }
  })
}

###########
# Create private endpoints for dev, sql and sql-ondemand
###########

module "private-endpoint" {
  for_each            = var.private_endpoints == null ? {} : { for key, value in var.private_endpoints : key => value }
  source              = "jsathler/private-endpoint/azurerm"
  version             = "0.0.2"
  location            = var.location
  resource_group_name = var.resource_group_name
  name_sufix_append   = var.name_sufix_append
  tags                = local.tags

  private_endpoint = {
    name                           = each.value.name
    subnet_id                      = each.value.subnet_id
    private_connection_resource_id = azurerm_synapse_workspace.default.id
    subresource_name               = each.key
    application_security_group_ids = each.value.application_security_group_ids
    private_dns_zone_id            = each.value.private_dns_zone_id
  }
}
