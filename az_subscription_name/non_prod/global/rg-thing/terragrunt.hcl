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
}

include {
  path = find_in_parent_folders()
}

terraform {
  source = ".//."
}

inputs = {
  resource_group_name = "${basename(get_terragrunt_dir())}-001" # Uses the folder name to construct the resource name
}
