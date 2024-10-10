# From VM1 - Application rule
Invoke-WebRequest -Uri https://aboutme.omegamadlab.com -UseBasicParsing | Select-Object StatusCode
Invoke-WebRequest -Uri https://portal.azure.com -UseBasicParsing | Select-Object StatusCode

# From VM1 - Network rule with FQDN
Test-NetConnection -ComputerName "vm2.internal.azurecookbook.info" -Port 445
Test-NetConnection -ComputerName "vm2.internal.azurecookbook.info" -Port 3389
