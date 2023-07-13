# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# FIXME: Update inline comments numbered as # 1, 2 and 3
locals {
  # Automatically load subscription variables
  subscription_vars = read_terragrunt_config(find_in_parent_folders("subscription.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  location        = local.region_vars.locals.location
  environment     = local.environment_vars.locals.environment
  subscription_id = local.subscription_vars.locals.subscription_id

  # Provider Pinnings
  terraform_required_version = ">= 1.3.1"
  provider_version_azurerm   = "3.44.1"
  provider_version_azuread   = "2.34.1"

  # Blob Storage
  resource_group_name  = "rg-tfstate-01"  # :1
  storage_account_name = "sttfstate26901" # :2
  container_name       = "tfstate"        # :3

}
# Configure remote state files
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    subscription_id      = "${local.subscription_id}"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    resource_group_name  = "${local.resource_group_name}"
    storage_account_name = "${local.storage_account_name}"
    container_name       = "${local.container_name}"
  }
}


generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "azurerm" {
  features {}
  subscription_id = "${local.subscription_id}"
}
provider "azuread" {
}
EOF
}

# Generate versions.tf for provider pinning
generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "${local.terraform_required_version}"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "${local.provider_version_azurerm}"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "${local.provider_version_azuread}"
    }
  }
}
 EOF
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.subscription_vars.locals,
  local.region_vars.locals,
  local.environment_vars.locals
)