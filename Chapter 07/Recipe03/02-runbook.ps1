# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity).context

# Set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

$storageAccount = Get-AzResource -ResourceGroupName "Recipe07-03-rg" `
                    -Name 'recipe0703*' `
                    -ResourceType "Microsoft.Storage/StorageAccounts" | 
                    Get-AzStorageAccount

Write-Output "Azure Cookbook - Recipe 07.03" | Out-File -FilePath .\recipe0703.txt

$storageContext = New-AzStorageContext -UseConnectedAccount -BlobEndpoint $storageAccount.PrimaryEndpoints.blob

Set-AzStorageBlobContent -Container "recipe0703" -File ".\recipe0703.txt" -Blob "Recipe0703" -Context $storageContext