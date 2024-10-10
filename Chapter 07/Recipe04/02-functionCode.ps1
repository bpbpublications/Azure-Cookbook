# Input bindings are passed in via param block.
param([byte[]] $InputBlob, $TriggerMetadata)

$enc = [System.Text.Encoding]::UTF8

# Convert the byte[] into a string, then into a CSV object 
$csvObj = $enc.GetString($InputBlob) | ConvertFrom-Csv -Delimiter ","

# Convert the CSV into a JSON string, then encode it as a byte[]
$jsonText = $csvObj | ConvertTo-Json
$outBlob = $enc.GetBytes($jsonText)

# Push the blob through the output binding
Push-OutputBinding -Name OutputBlob -Value $outBlob