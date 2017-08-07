Param(
    [string]$resource_group_name,
    [string]$keyvault_name,
    [string]$location,
    [string]$subscription_id = "",
    [string]$path_to_certificate,
    [string]$secret_name,
    [string]$password_for_cert
)

#az login

if ($subscription_id.Length -gt 0)
{
    "Selecting subscription $subscription_id"
    az account set --subscription $subscription_id
}

"Creating resource group in azure"
az group create --location $location --name $resource_group_name

"Creating keyvault"
az keyvault create -n $keyvault_name -g $resource_group_name --enabled-for-template-deployment true --enabled-for-deployment true

"Uploading certificate"
$secretInfo = az keyvault certificate import --vault-name $keyvault_name --name $secret_name --file $path_to_certificate --password $password_for_cert | ConvertFrom-Json

"Certificate thumbprint:"
$secretInfo.x509ThumbprintHex

"Certificate Url in KeyVault:"
$secretInfo.sid
