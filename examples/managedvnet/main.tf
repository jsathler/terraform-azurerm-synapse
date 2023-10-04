provider "azurerm" {
  features {}
}

provider "azapi" {
}

resource "azurerm_resource_group" "default" {
  name     = "synapsemanagedvnet-example-rg"
  location = "northeurope"
}


resource "random_string" "default" {
  length    = 6
  min_lower = 6
}

resource "azurerm_storage_account" "default" {
  name                     = "synapseexample${random_string.default.result}st"
  location                 = azurerm_resource_group.default.location
  resource_group_name      = azurerm_resource_group.default.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "default" {
  name               = "synapse"
  storage_account_id = azurerm_storage_account.default.id
}

data "azurerm_client_config" "default" {}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "synapse" {
  source              = "../../"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  workspace = {
    name                                 = "synapseexample${random_string.default.result}"
    managed_resource_group_name          = replace(azurerm_resource_group.default.name, "rg", "mrg")
    storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.default.id
    azuread_only_authentication          = true
    aad_admin = {
      login     = "Azure AD Admin"
      object_id = data.azurerm_client_config.default.object_id
      tenant_id = data.azurerm_client_config.default.tenant_id
    }
  }

  firewall_rules = {
    my-ip = {
      start_ip_address = chomp(data.http.myip.response_body)
      end_ip_address   = chomp(data.http.myip.response_body)
    }
  }

  access_control = {
    "Synapse Administrator" = ["8f83c55d-0cf3-4aaa-b0fd-67d0dcb8a927"]
  }
}

# resource "azurerm_role_assignment" "default" {
#   scope                = azurerm_storage_account.default.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = module.synapse.
# }