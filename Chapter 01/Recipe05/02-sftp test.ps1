Write-Output "This is a test file" | Out-File testfile.txt -Force

$sftpCommand = @"
mkdir /testfolder
cd /testfolder
put testfile.txt
ls
"@

# Replace the value of $sftpConnString with the data of your storage account
$sftpConnString = "recipe0105346186092sa.demouser@recipe0105346186092sa.blob.core.windows.net"

# When required, provide the password of demouser
$sftpCommand | sftp $sftpConnString