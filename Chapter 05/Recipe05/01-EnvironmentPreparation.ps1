$envPrefix = "Recipe05-05"
$location = "westeurope"
$rgName = "$envPrefix-rg"

## Check if the resource group exists

$exists=$(az group exists --name $rgName)

if($exists -eq "false") {
    az group create --name $rgName --location $location
}

## Create an Azure RBAC enabled cluster
az aks create --resource-group $rgName --name "$envPrefix-AKS" --enable-aad --enable-azure-rbac --generate-ssh-keys

## Assign the Azure Kubernetes Service RBAC Admin role to your user
$AKS_ID = $(az aks show -g $rgName -n "$envPrefix-AKS" --query id -o tsv)
az role assignment create --role "Azure Kubernetes Service RBAC Cluster Admin" --assignee "<REPLACE WITH A VALID UPN>" --scope $AKS_ID

## Connect to the cluster via Entra ID authentication
az aks get-credentials -g $rgName -n "$envPrefix-AKS"
kubectl get nodes

## Enable Calico as the network policy plug-in for the cluster
az aks update -g $rgName -n "$envPrefix-AKS" --network-policy calico

## Create the network policy specified in network-policy.yaml
kubectl apply -f network-policy.yaml

## Execute the Az CLI image in the default namespace
kubectl run azure-cli -it --rm --image=mcr.microsoft.com/azure-cli:latest -- bash

## Execute at the bash prompt inside the container
wget -qO- --header 'Metadata: true' "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq
## Close the session
exit

## Execute the Az CLI image in the noimds namespace
kubectl run azure-cli -it --rm -n noimds --image=mcr.microsoft.com/azure-cli:latest -- bash

## Execute at the bash prompt inside the container
wget -qO- --header 'Metadata: true' "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq
## Close the session
exit

## Register the Azure Policy provider
az provider register --namespace Microsoft.PolicyInsights

## Enable the Azure Policy addon
az aks enable-addons --addons azure-policy -g $rgName -n "$envPrefix-AKS"