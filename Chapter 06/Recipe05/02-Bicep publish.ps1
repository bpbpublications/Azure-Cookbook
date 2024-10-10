# Replace the value of $acrLoginServer with the uri of your ACR
$acrLoginServer = '<your-acr-uri-here>'
bicep publish .\vnet.bicep --target br:$acrLoginServer/modules/vnet:v1
bicep publish .\vm.bicep --target br:$acrLoginServer/modules/vm:v1

