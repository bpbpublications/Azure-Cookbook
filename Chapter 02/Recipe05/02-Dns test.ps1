# Verify forwarders configuration on the DNS server
Get-DnsServerForwarder

# Try resolution on the CLIENT-VM
nslookup samplerecord.recipe0205.demo
nslookup www.contoso.com

# Configure the DNS server to use Azure DNS and reset the cache
Set-DnsServerForwarder -IPAddress "168.63.129.16" -TimeOut 5 -PassThru
Clear-DnsServerCache -Force -Confirm:$false

# Try again resolution on the CLIENT-VM, this time using Azure DNS
Clear-DnsClientCache -Confirm:$false
nslookup samplerecord.recipe0205.demo
nslookup www.contoso.com
nslookup aboutme.omegamadlab.com