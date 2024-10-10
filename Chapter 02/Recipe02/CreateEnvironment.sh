# Define resource names and location
resource_group_name="Recipe02-02-rg"
location1="northeurope"
location2="westus"
network1_name="VNet1"
network2_name="VNet2"

# Create resource group
echo "Resource Group creation"
az group create --name $resource_group_name --location $location1 --query "{ResourceGroup:name}" -o none

# Create NSGs
echo "NSGs creation"
az network nsg create --name NSG1 --resource-group $resource_group_name --location $location1 -o none
az network nsg create --name NSG2 --resource-group $resource_group_name --location $location2 -o none

# Create VNet 1 and subnets
echo "VNet1 creation"
az network vnet create --resource-group $resource_group_name --name $network1_name --location $location1 --address-prefix 10.0.0.0/16 -o none
az network vnet subnet create --resource-group $resource_group_name --vnet-name $network1_name --name FrontEndSubnet --address-prefix 10.0.0.0/24 --network-security-group NSG1 -o none
az network vnet subnet create --resource-group $resource_group_name --vnet-name $network1_name --name BackEndSubnet --address-prefix 10.0.1.0/24 -o none

# Create VNet 2 and subnets
echo "VNet2 creation"
az network vnet create --resource-group $resource_group_name --name $network2_name --location $location2 --address-prefix 10.1.0.0/16 -o none
az network vnet subnet create --resource-group $resource_group_name --vnet-name $network2_name --name Subnet1 --address-prefix 10.1.0.0/24 -o none
az network vnet subnet create --resource-group $resource_group_name --vnet-name $network2_name --name Subnet2 --address-prefix 10.1.1.0/24 --network-security-group NSG2 -o none

# Create VNet peerings
echo "VNet peerings creation"
az network vnet peering create --resource-group $resource_group_name --name $network1_name-to-$network2_name --vnet-name $network1_name --remote-vnet $network2_name --allow-vnet-access -o none
az network vnet peering create --resource-group $resource_group_name --name $network2_name-to-$network1_name --vnet-name $network2_name --remote-vnet $network1_name --allow-vnet-access -o none

# Create a VM in VNet1
echo "VM1 creation"
az vm create --resource-group $resource_group_name --location $location1 --name VM1 --vnet-name $network1_name --subnet FrontEndSubnet --image Ubuntu2204 --admin-username azureuser --admin-password Pa55w.rd1234 -o none

# Create a VM in VNet2 without Public IP
echo "VM2 creation"
az vm create --resource-group $resource_group_name --location $location2 --name VM2 --vnet-name $network2_name --subnet Subnet1 --image Ubuntu2204 --admin-username azureuser --admin-password Pa55w.rd1234 --public-ip-address "" -o none