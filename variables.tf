variable "location" {
  description = "The region where the VM will be created. This parameter is required"
  type        = string
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created. This parameter is required"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources."
  type        = map(string)
  default     = null
}

variable "workspace" {
  type = object({
    name                                 = string
    storage_data_lake_gen2_filesystem_id = string
    sql_identity_control_enabled         = optional(bool, true)
    sql_administrator_login              = optional(string, "sqladminuser")
    sql_administrator_login_password     = optional(string, null)
    compute_subnet_id                    = optional(string, null)
    data_exfiltration_protection_enabled = optional(bool, true)
    linking_allowed_for_aad_tenant_ids   = optional(list(string), null)
    managed_resource_group_name          = optional(string, null)
    managed_virtual_network_enabled      = optional(bool, true)
    public_network_access_enabled        = optional(bool, true)
    purview_id                           = optional(string, null)
    azuread_only_authentication          = optional(bool, false)
    trusted_service_bypass_enabled       = optional(bool, true)
    allow_azure_services                 = optional(bool, true)

    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string), null)
    }), {})

    aad_admin = optional(object({
      login     = string
      object_id = string
      tenant_id = string
    }), null)

    azure_devops_repo = optional(object({
      account_name    = string
      branch_name     = string
      last_commit_id  = optional(string, null)
      project_name    = optional(string, null)
      repository_name = string
      root_folder     = optional(string, "/synapse")
      tenant_id       = optional(string, null)
    }), null)

    github_repo = optional(object({
      account_name    = string
      branch_name     = string
      last_commit_id  = optional(string, null)
      repository_name = string
      root_folder     = optional(string, "/synapse")
      git_url         = optional(string, null)
    }), null)

    customer_managed_key = optional(object({
      key_versionless_id = string
      key_name           = optional(string, "cmk")
    }), null)

    sql_aad_admin = optional(object({
      login     = string
      object_id = string
      tenant_id = string
    }), null)
  })

  #   validation {
  #     condition     = var.workspace.sql_administrator_login == null ? var.workspace.aad_admin != null : true
  #     error_message = "If sql_administrator_login is not defined, aad_admin block should be defined"
  #   }
}

variable "firewall_rules" {
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))

  default = {}

  nullable = false
}

variable "access_control" {
  type = map(list(string))

  default = {}

  nullable = false
}
