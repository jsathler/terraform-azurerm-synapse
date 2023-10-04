locals {
  tags = merge(var.tags, { ManagedByTerraform = "True" })
}

resource "azurerm_synapse_workspace" "default" {
  name                                 = "${var.workspace.name}-synw"
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = var.workspace.storage_data_lake_gen2_filesystem_id

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

resource "azurerm_synapse_firewall_rule" "allow_azure_services" {
  count                = var.workspace.allow_azure_services && var.workspace.public_network_access_enabled ? 1 : 0
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

resource "azurerm_synapse_firewall_rule" "default" {
  for_each             = { for key, value in var.firewall_rules : key => value }
  name                 = "${each.key}-syfw"
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  start_ip_address     = each.value.start_ip_address
  end_ip_address       = each.value.end_ip_address
}

# resource "azurerm_role_assignment" "default" {
#   scope                = azurerm_storage_account.default.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_synapse_workspace.default.id
# }

#Synapse Access Control
locals {
  access_control = flatten([for key, value in var.access_control : [
    for principal_id in value : {
      role_name    = key
      principal_id = principal_id
    }
  ]])
}

resource "azurerm_synapse_role_assignment" "roles" {
  for_each             = { for key, value in local.access_control : "${value.role_name}-${value.principal_id}" => value }
  synapse_workspace_id = azurerm_synapse_workspace.default.id
  role_name            = each.value.role_name
  principal_id         = each.value.principal_id
}

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
