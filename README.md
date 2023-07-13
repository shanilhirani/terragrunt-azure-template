# Terragrunt Azure Boilerplate

## Terraform and Terragrunt is are required to use this module.
[dotfiles](.) have been created to help control versioning of terragrunt and terraform in case of upstream or out of band changes.

Additionally, [envrc](.envrc) can be used for managing environment variables.

Version Pinning:
- [Terraform](.terraform-version)
- [Terragrunt](.terragrunt-version)

## How To

### Azure Subscription
 An Active Azure Subscription is required.

### Create Service Roles
 Authentication with Azure can be achieved by using an SPN account/role and setting the appropriate environment variables.
 If you intend to use Azure KV for secrets management than optional cmdlets are included where appropriate.

 Docs:
 - [Terraform Guide: Service Principal Client Secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
 - [Learn Microsoft: Terraform Authenticate to Azure](https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=bash#create-a-service-principal)

 Create a service principal by running the `cmdlet` below ensuring you replace the `"${az_subscription_id}"` variable with an actual id.

 ```bash
 az ad sp create-for-rbac  --name "spn_terraform" --role="Contributor" --scopes="/subscriptions/${az_subscription_id}"
 # Optional for KV
 az ad sp create-for-rbac  --name "spn_keyvault" --role="Contributor" --scopes="/subscriptions/${az_subscription_id}"
 ```

### Create Azure Storage Account
 Terraform State using Azure Storage as backend requires a `resource group`, `storage account` and `storage account container`

 Docs:
 - [Learn Microsoft: Store Terraform state in Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli)

 Run the following to create an Azure storage account and container.

 ```bash
 RESOURCE_GROUP_NAME="rg-tfstate-01"
 STORAGE_ACCOUNT_NAME="sttfstate$RANDOM"
 CONTAINER_NAME="tfstate"

 az group create --name ${RESOURCE_GROUP_NAME} --location eastus
 az storage account create --resource-group ${RESOURCE_GROUP_NAME} --name ${STORAGE_ACCOUNT_NAME} --sku Standard_LRS --encryption-services blob
 az storage container create --name ${CONTAINER_NAME} --account-name ${STORAGE_ACCOUNT_NAME}
 ```

### Optional: Create Azure Key Vault for us with SOPS
 A Dedicated Key Vault for Terragrunt with SOPS/KV.

 This enables you to manage the azure client credentials for the SPN Terraform role we created earlier, without having to store anything plaintext as SOPS (Azure KV) to perform encrypt and decrypt of secrets files.

 Docs:
 - [Create a key vault using the Azure CLI](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-cli)
 - [SOPS: Azure Key Vault](https://github.com/mozilla/sops#24encrypting-using-azure-key-vault)

 We need to create the following low level resources:

 - `resource group`
 - `keyvault`
 - `keyvault key`
 - `keyvault policy`


 ```bash
 RESOURCE_GROUP_NAME="rg-sops-01"
 KEY_VAULT_NAME="kv-sops-$RANDOM"
 KEY_NAME="sops-key"
 AZURE_CLIENT_ID="spn_keyvault_id"

 az group create --name ${RESOURCE_GROUP_NAME} --location eastus
 az keyvault create --name ${KEY_VAULT_NAME} --resource-group ${RESOURCE_GROUP_NAME} --location eastus
 az keyvault key create --name ${KEY_NAME} --vault-name ${KEY_VAULT_NAME} --protection software --ops encrypt decrypt
 az keyvault set-policy --name ${KEY_VAULT_NAME} --resource-group ${RESOURCE_GROUP_NAME} --spn ${AZURE_CLIENT_ID} --key-permissions encrypt decrypt list get
 az keyvault key show --name ${KEY_NAME} --vault-name ${KEY_VAULT_NAME} --query key.kid
 ```

 Once these resources have been created you then need to perform an `az login` or set shell variables for the SOPS SPN, then perform encryption of your `secrets.yaml` (added to `.gitignore`) to [secrets.enc.yaml](secrets.enc.yaml)

 Example:

 ```bash
 KV="https://$KEY_VAULT_NAME.vault.azure.net/keys/$KEY_NAME/XXX"
 sops --encrypt --azure-kv $KV ../secrets.yaml > ../secrets.enc.yaml
 ```

### Configuring Environment Variables
 [envrc](.envrc) contains user-defined environmental variables which **can** be updated with  client ID, secret and subscription Id.

 It also contains a helper function for SOPS should you chose to use which will export key/values from `secrects.enc.yaml` into shell.

 To enable this feature uncomment the block.

 ```bash
 # use_sops() {
 #     local path=${1:-$PWD/secrets.enc.yaml}
 #     eval "$(sops -d --extract '["SPN_TERRAGRUNT"]' --output-type dotenv "$path" | direnv dotenv bash /dev/stdin)"
 #     watch_file "$path"
 # }
 # use sops
 ```

 Update the following in [envrc](.envrc)

 ```bash
 # SPN Export Vars
 export ARM_CLIENT_ID=""
 export ARM_CLIENT_SECRET=""
 export ARM_TENANT_ID=""
 export ARM_SUBSCRIPTION_ID=""
 ```

### "FIXME" / "TODO"
 This repo contains various "FIXME"/"TODOS" which must be updated before deploying as come of these values need updated beforehand so please ensure that you find and replace FIXME markers.




### Write, Plan and Apply
 Once you have confirmed the above, you should be good to terragrunt.
 ```bash
 terragrunt run-all plan | apply
 ```
