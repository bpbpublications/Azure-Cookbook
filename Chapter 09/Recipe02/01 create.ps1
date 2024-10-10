$envPrefix = "Recipe09-02"
$location = "westeurope"
$rgName = "$envPrefix-rg"

# Prepare the resource group
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

# Get the bicep file from the git repo
if (Get-Item .\storage.bicep) {
    Remove-Item .\storage.bicep
}

Invoke-WebRequest -URI "https://raw.githubusercontent.com/AzureMasterchef/AzureCookbook/main/09-Azure%20Compliance/Recipe02/storage.bicep" `
    -OutFile storage.bicep

if (Get-Item .\landing_zone.bicep) {
    Remove-Item .\landing_zone.bicep
}

Invoke-WebRequest -URI "https://raw.githubusercontent.com/AzureMasterchef/AzureCookbook/main/09-Azure%20Compliance/Recipe02/landing_zone.bicep" `
    -OutFile landing_zone.bicep

# Create a template spec for landing_zone.bicep
$templateSpec_v1 = New-AzTemplateSpec -Name "$envPrefix-landingZone-ts" `
                    -Version 1.0 `
                    -ResourceGroupName $rg.ResourceGroupName `
                    -Location $location `
                    -TemplateFile ./landing_zone.bicep

# Create a deployment stack starting from the template spec. The deployment stack targets the subscription, since landing_zone.bicep create a resource group at that scope
$storageAccountName = "recipe0902stg$(Get-Random -Minimum 000000 -Maximum 999999)"
$storageAccountName | Out-File storageAccountName.txt

$parameters = @{
    rgName = "$envPrefix-target-rg"
    storageAccountName = $storageAccountName
    location = $location
}

New-AzSubscriptionDeploymentStack  `
    -Name "$envPrefix-DeploymentStack" `
    -location $location `
    -TemplateSpec $templateSpec_v1.versions.Id `
    -TemplateParameterObject $parameters `
    -DeleteAll `
    -DenySettingsApplyToChildScopes `
    -DenySettingsMode "DenyDelete"
