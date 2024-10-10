$envPrefix = "Recipe07-04"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Storage account used by the Function App
$saWebJobs = New-AzStorageAccount -ResourceGroupName $rgName `
                -Name "recipe0704webjobssa$(Get-Random -Maximum 99999)" `
                -Location $location `
                -SkuName Standard_LRS `
                -Kind StorageV2

# Storage account for blob transformation
$sa = New-AzStorageAccount -ResourceGroupName $rgName `
        -Name "recipe0704sa$(Get-Random -Maximum 9999999)" `
        -Location $location `
        -SkuName Standard_LRS `
        -Kind StorageV2

New-AzStorageContainer -Name "recipe0704-input" -Context $sa.Context
New-AzStorageContainer -Name "recipe0704-output" -Context $sa.Context

# Function App and configuration parameters
$functionApp = New-AzFunctionApp -ResourceGroupName $rgName `
                -Name "$envPrefix-Function" `
                -StorageAccountName $sa.StorageAccountName `
                -Location $location `
                -Runtime PowerShell `
                -RuntimeVersion 7.2 `
                -FunctionsVersion 4 `
                -osType Windows `
                -IdentityType SystemAssigned

$functionApp | Update-AzFunctionAppSetting -AppSetting @{"AzureWebJobsStorage" = $saWebJobs.Context}

# If you want to use the function app managed Identity to access the storage account, uncomment the following lines
# $functionApp | Update-AzFunctionAppSetting -AppSetting @{"AzureWebJobsStorage__accountname" = $saWebJobs.StorageAccountName}
# $functionApp | Update-AzFunctionAppSetting -AppSetting @{"recipe0704blob__blobServiceUri" = $sa.PrimaryEndpoints.Blob}
# $functionApp | Update-AzFunctionAppSetting -AppSetting @{"recipe0704blob__queueServiceUri" = $sa.PrimaryEndpoints.Queue}

# # Function App managed identity permisions to the storage accounts
# New-AzRoleAssignment -ObjectId $functionApp.IdentityPrincipalId `
#                         -RoleDefinitionName "Storage Blob Data Owner" `
#                         -Scope $sa.Id

# New-AzRoleAssignment -ObjectId $functionApp.IdentityPrincipalId `
#                         -RoleDefinitionName "Storage Queue Data Contributor" `
#                         -Scope $sa.Id

# New-AzRoleAssignment -ObjectId $functionApp.IdentityPrincipalId `
#                         -RoleDefinitionName "Storage Blob Data Owner" `
#                         -Scope $saWebJobs.Id