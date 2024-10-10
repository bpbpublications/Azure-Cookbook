code landing_zone.bicep

$envPrefix = "Recipe09-02"
$location = "westeurope"
$rgName = "$envPrefix-rg"

# Prepare the resource group
$rg = Get-AzResourceGroup -Name $rgName

# Generate a new version of the Template Spec
$templateSpec_v2 = New-AzTemplateSpec -Name "$envPrefix-landingZone-ts" `
                    -Version 2.0 `
                    -ResourceGroupName $rg.ResourceGroupName `
                    -Location $location `
                    -TemplateFile ./landing_zone.bicep

# Update the deployment stack with the new version of the template spec
$parameters = @{
    rgName = "$envPrefix-target-rg"
    storageAccountName = Get-Content .\storageAccountName.txt
    location = $location
}

Set-AzSubscriptionDeploymentStack  `
    -Name "$envPrefix-DeploymentStack" `
    -location $location `
    -TemplateSpec $templateSpec_v2.versions.Id `
    -TemplateParameterObject $parameters `
    -DeleteAll `
    -DenySettingsApplyToChildScopes `
    -DenySettingsMode "DenyDelete"

# Delete the deployment stack and all the related resources
Remove-AzSubscriptionDeploymentStack `
  -Name "$envPrefix-DeploymentStack" `
  -DeleteAll