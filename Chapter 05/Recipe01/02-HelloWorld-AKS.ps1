$envPrefix = "Recipe05-01-AKS"
$location = "westeurope"
$rgName = "$envPrefix-rg"

$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if(-not $rg) {
    $rg = New-AzResourceGroup -Name $rgName -Location $location
}

$aksName = "recipe05-01-aks"

New-AzAksCluster -ResourceGroupName $rgName `
    -Name $aksName `
    -NodeCount 1 `
    -EnableManagedIdentity `
    -GenerateSshKey

Import-AzAksCredential -ResourceGroupName $rgName -Name $aksName

# Check the number of nodes
kubectl get nodes

# Create a YAML deployment in the cloud shell and paste the content of the 03-HelloWorld-AKS_deployment.yaml file
code 03-HelloWorld-AKS_deployment.yaml

# Apply the deployment and check the status
kubectl apply -f 03-HelloWorld-AKS_deployment.yaml

kubectl get pods

kubectl get service hello-world-apache-service --watch

# Apply a change to the number of replicas in the YAML file, and apply it again
code 03-HelloWorld-AKS_deployment.yaml

kubectl apply -f 03-HelloWorld-AKS_deployment.yaml

kubectl get pods