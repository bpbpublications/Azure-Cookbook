# From VM1
Test-NetConnection -ComputerName 172.16.0.10 -Port 3389
Invoke-WebRequest -Uri www.omegamadlab.com -TimeoutSec 10 -UseBasicParsing

# From VM2
Test-NetConnection -ComputerName 192.168.0.10 -Port 3389
Invoke-WebRequest -Uri www.omegamadlab.com -TimeoutSec 10 -UseBasicParsing