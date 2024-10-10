Param(
    [string]$ResourceGroup,
    [string]$VMName
)

$automationAccount = "Recipe07-01-aa"

# Ensures you do not inherit an AzContext in your runbook
$null = Disable-AzContextAutosave -Scope Process

# Connect using a Managed Service Identity
try {
    $AzureConnection = (Connect-AzAccount -Identity).context
}
catch {
    Write-Output "There is no system-assigned user identity. Aborting." 
    exit
}

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureConnection.Subscription -DefaultProfile $AzureConnection

# Get current state of VM
$status = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Status -DefaultProfile $AzureContext).Statuses[1].Code

Write-Output "`r`n Beginning VM status: $status `r`n"

# Start or stop VM based on current state
if ($status -eq "Powerstate/deallocated") {
    Start-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -DefaultProfile $AzureContext
}
elseif ($status -eq "Powerstate/running") {
    Stop-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -DefaultProfile $AzureContext -Force
}

# Get new state of VM
$status = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Status -DefaultProfile $AzureContext).Statuses[1].Code

Write-Output "`r`n Ending VM status: $status `r`n `r`n"

Write-Output "Account ID of current context: " $AzureContext.Account.Id