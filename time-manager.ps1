cd $PSScriptRoot

$DATETIME_FORMAT = '%Y/%m/%d %H:%M:%S'
$CONFIGS         = '.\cfg'
$LOG             = '.\log.txt'

$startupDatetime = (Get-Date -UFormat $DATETIME_FORMAT)
$startupMessage  = "-------------------------------+`r`nSent     @ $startupDatetime | Time Manager Startup`r`nReceived @ $startupDatetime |`r`n-------------------------------+"

Write-Host $startupMessage

while ($true) {
	$currentId = (Get-Date -UFormat '%s')
	$entries = (Get-Item -Path $CONFIGS\*)
    foreach ($entry in $entries) {
		$entryId = ($entry.Name -split ' ')[0]
        if ($currentId -ge $entry.Name) {
			Rename-Item $entry -NewName "$entry.ps1"
            & "$entry.ps1"
			Remove-Item "$entry.ps1"
        }
    }
	Start-Sleep -Milliseconds 800
}