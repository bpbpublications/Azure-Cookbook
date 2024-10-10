$resource_group_name = "Recipe07-02-rg"
$location = "westeurope"
$automation_account_name="Recipe07-02-aa"

# Create resource group
New-AzResourceGroup -Name $resource_group_name -Location $location
$resourceGroup = Get-AzResourceGroup -Name $resource_group_name

# Create Automation Account
New-AzAutomationAccount -ResourceGroupName $resource_group_name `
                        -Name $automation_account_name `
                        -Location $location `
                        -Plan Free -AssignSystemIdentity
$automationAccount = Get-AzAutomationAccount -ResourceGroupName $resource_group_name `
                                             -Name $automation_account_name

# Assign roles to the Automation Account
$resourceGroupId = $resourceGroup.ResourceId 
New-AzRoleAssignment -ObjectId $automationAccount.Identity.PrincipalId `
                     -Scope "$resourceGroupId/providers/Microsoft.Automation/automationAccounts/$automation_account_name" `
                     -RoleDefinitionName "Automation Contributor"
