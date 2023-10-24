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
    storage_account_id                   = string
    storage_account_filesystem_name      = optional(string, null)
    storage_account_private_endpoint     = optional(bool, false)
    storage_account_filesystem_id        = optional(string, null)
    sql_identity_control_enabled         = optional(bool, true)
    sql_administrator_login              = optional(string, "localadmin")
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
    allow_azure_services                 = optional(bool, false)

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

    firewall_rules = optional(map(object({
      start_ip_address = string
      end_ip_address   = string
    })), null)

    access_control = optional(map(list(string)), null)
  })

  validation {
    condition     = var.workspace.storage_account_filesystem_id == null ? var.workspace.storage_account_id != null && var.workspace.storage_account_filesystem_name != null : true
    error_message = "If storage_account_filesystem_id is not set, storage_account_id and storage_account_filesystem_name should be defined"
  }

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

# variable "access_control" {
#   type = map(list(string))

#   default = {}

#   nullable = false
# }

variable "sql_pools" {
  type = map(object({
    sku_name                  = optional(string, "DW100c")
    create_mode               = optional(string, null)
    collation                 = optional(string, null)
    data_encrypted            = optional(bool, false)
    geo_backup_policy_enabled = optional(bool, true)
    tags                      = optional(map(string), null)
  }))
  default  = {}
  nullable = false
}

variable "irs" {
  type = map(object({
    description      = optional(string, null)
    type             = optional(string, "Azure")
    location         = optional(string, "AutoResolve")
    compute_type     = optional(string, "General")
    core_count       = optional(number, 8)
    time_to_live_min = optional(number, 0)
  }))
  default = {}

  nullable = false

  validation {
    condition     = var.irs != null ? alltrue([for ir in var.irs : can(index(["Azure", "Self-hosted"], ir.type) >= 0)]) : true
    error_message = "Allowed values for type are Azure and Self-hosted"
  }

  validation {
    condition     = var.irs != null ? alltrue([for ir in var.irs : can(index(["General", "ComputeOptimized", "MemoryOptimized"], ir.compute_type) >= 0)]) : true
    error_message = "Allowed values for compute_type are General, ComputeOptimized and MemoryOptimized"
  }
}
