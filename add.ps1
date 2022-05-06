
param (
	[Parameter(Mandatory)]
	[Alias("Epochs")]
	[string[]] $EpochsRaw                            ,
	[Parameter(Mandatory)]
	[string]   $Message                              ,
	[int]      $Urgency            = 1               ,
	[int]      $Priority           = 0               ,
	[int]      $TodoRepeating      = 1               ,
	[string]   $ExpirationDatetime = "NeverExpire"   ,
	[int]      $ExpirationEpoch    = -1              ,
	[string]   $ConflictResolution = 'AddSeconds(5)' ,
	[float]    $RandomMaximum      = 1               ,
	[float]    $RandomThreshold    = 0               ,
	[string[]] $RequiredWeekdays   = 'AnyWeekday'    ,
	[string[]] $Sounds             = 'NoSound'       ,
	[string[]] $Commands           = 'NoCommands'
)

[string] $DATETIME_FORMAT = '%Y/%m/%d %H:%M:%S'
[string] $CONFIGS         = '.\cfg'
[string] $TODOS           = '.\todo'
[string] $ADD             = '.\add.ps1'
[string] $LOG             = '.\log.txt'
[string] $NO_COMMAND      = 'NoCommands'
[string] $NO_TIME         = 'Inherit'
[string] $NO_WAIT         = 'NeverRepeat'
[string] $NO_STOP         = 'RepeatForever'
[string] $NO_EXPIRE       = 'NeverExpire'
[string] $EXPIRE_NEXT     = 'NextRepeat'
[string] $NO_WEEKDAY      = 'AnyWeekday'
[string] $NO_SOUND        = 'NoSound'
[int]    $URG_HIDDEN      = 0
[int]    $URG_LOW         = 1
[int]    $URG_MEDIUM      = 2
[int]    $URG_HIGH        = 3
[int]    $PRI_NO_PERSIST  = -1
[int]    $PRI_LOG_ONLY    = 0
[int]    $TODO_ONCE       = 0
[int]    $TODO_DECREMENT  = 1
[int]    $TODO_INCREMENT  = 2

[string]      $repackedRequiredWeekdays = ''
[string]      $repackedSounds           = ''
[string]      $repackedCommands         = ''
[string[]]    $epoch                    = @()
[hashtable[]] $epochs                   = @()
[string]      $datetime                 = ''
[int]         $id                       = 0
[string]      $script                   = ''
[string]      $nextDatetime             = ''
[int]         $nextId                   = 0
[string]      $nextScript               = ''
[string]      $nextEpochs               = ''
[string]      $stopDatetime             = ''
[int]         $stopId                   = 0
[int]         $expirationId             = 0
[string]      $content                  = ''
[int]         $rank                     = 0
[string]      $weekday                  = ''
[switch]      $pass                     = $false
[float]       $random                   = 0.0

for ($i = 0; $i -lt $EpochsRaw.length; $i++) {
	$epoch = $EpochsRaw[$i] -split ','
	$epochs += @{ 'Time' = $epoch[0]; `
	              'Wait' = $epoch[1]; `
				  'Stop' = $epoch[2]  }
}

for ($i = 0; $i -lt $epochs.length; $i++) {
	if ($epochs[$i]['Time'] -ne $NO_TIME) {
		$epochs[$i]['Time'] = (Get-Date $epochs[$i]['Time'] -UFormat $DATETIME_FORMAT)
		$datetime = $epochs[$i]['Time']
	} else {
		$epochs[$i]['Time'] = $datetime
	}
	if (($i -ge 1) -and ($epochs[$i]['Time'] -ne $epochs[($i - 1)]['Time'])) {
		$rank = $i
	}
}

$id     = (Get-Date $datetime -UFormat '%s' -Millisecond 0)
$script = "$CONFIGS\$id $Message"
if ($ConflictResolution -eq 'Fail') {
	if (Test-Path $script) {
		exit
	}
} elseif ($ConflictResolution -ne 'Overwrite') {
	while (Test-Path $script) {
		$datetime = (Invoke-Expression "Get-Date (Get-Date `"$datetime`").$ConflictResolution -UFormat `"$DATETIME_FORMAT`"")
		$id       = (Get-Date $datetime -UFormat '%s' -Millisecond 0)
		$script   = "$CONFIGS\$id $Message"
	}
}

for ($i = 0; $i -lt $epochs.length; $i++) {
	if (($epochs[$i]['Wait'] -ne $NO_WAIT) -and ($rank -le $i)) {
		$nextDatetime = (Invoke-Expression "Get-Date (Get-Date `"$($epochs[$i]['Time'])`").$($epochs[$i]['Wait']) -UFormat `"$DATETIME_FORMAT`"")
		$nextId       = (Get-Date $nextDatetime -UFormat '%s' -Millisecond 0)
		if ($epochs[$i]['Stop'] -ne $NO_STOP) {
			if ($i -eq 0) {
				$epochs[0]['Stop'] = (Get-Date $epochs[0]['Stop'] -UFormat $DATETIME_FORMAT)
				$stopDatetime = $epochs[0]['Stop']
			} else {
				$stopDatetime = (Invoke-Expression "Get-Date (Get-Date `"$($epochs[($i - 1)]['Time'])`").$($epochs[$i]['Stop']) -UFormat `"$DATETIME_FORMAT`"")
			}
			$stopId = (Get-Date $stopDatetime -UFormat '%s' -Millisecond 0)
			if ($nextId -ge $stopId) {
				continue
			}
		}
		$nextEpochs = ''
		for ($j = 0; $j -lt $epochs.length; $j++) {
			if ($j -ge $i) {
				$nextEpochs += "'$nextDatetime"
			} else {
				$nextEpochs += "'$($epochs[$j]['Time'])"
			}
			$nextEpochs += ",$($epochs[$j]['Wait']),$($epochs[$j]['Stop'])'"
			if ($j -lt ($epochs.length - 1)) {
				$nextEpochs += ','
			}
		}
		$repackedRequiredWeekdays = "'$($RequiredWeekdays -join ''',''')'"
		$repackedSounds           = "`"$($Sounds -join '`",`"')`""
		$repackedCommands         = "`"$($Commands -join '`",`"')`""
		$content += "& $ADD -Epochs $nextEpochs -Message `"$Message`" -Urgency $Urgency -Priority $Priority -ExpirationDatetime `"$ExpirationDatetime`" -ExpirationEpoch $ExpirationEpoch -ConflictResolution `"$ConflictResolution`" -RandomMaximum $RandomMaximum -RandomThreshold $RandomThreshold -RequiredWeekdays $repackedRequiredWeekdays -Sounds $repackedSounds -Commands $repackedCommands`r`n"
	}
}

if ($RequiredWeekdays[0] -ne $NO_WEEKDAY) {
	$weekday = (Get-Date $datetime -UFormat '%A')
	$pass    = $false
	foreach ($requiredWeekday in $RequiredWeekdays) {
		if ($weekday -eq $requiredWeekday) {
			$pass = $true
			break
		}
	}
	if (-not ($pass)) {
		Set-Content $script -Value $content -Encoding 'UTF8' -NoNewLine
		exit
	}
}

if ($RandomMaximum -gt 1) {
	$random = (Get-Random -Minimum 0 -Maximum $RandomMaximum)
	if ($random -lt $RandomThreshold) {
		Set-Content $script -Value $content -Encoding 'UTF8' -NoNewLine
		exit
	}
}

$content += "`$currentDatetime = (Get-Date -UFormat `"$DATETIME_FORMAT`")`r`n"
$content += "`$currentId = (Get-Date `$currentDatetime -UFormat '%s' -Millisecond 0)`r`n"

if ($ExpirationDatetime -ne $NO_EXPIRE) {
	if ($ExpirationDatetime -eq $EXPIRE_NEXT) {
		$ExpirationDatetime = $epochs[($epochs.length - 1)]['Wait']
	}
	if ($ExpirationEpoch -eq 0) {
		$ExpirationDatetime = (Get-Date $ExpirationDatetime -UFormat $DATETIME_FORMAT)
	} else {
		if ($ExpirationEpoch -eq -1) {
			$ExpirationEpoch = $epochs.length
		}
		$ExpirationDatetime = (Invoke-Expression "Get-Date (Get-Date `"$($epochs[($ExpirationEpoch - 1)]['Time'])`").$ExpirationDatetime -UFormat `"$DATETIME_FORMAT`"")
	}
	$expirationId = (Get-Date $ExpirationDatetime -UFormat '%s' -Millisecond 0)
	$content += "if (`$currentId -ge $expirationId) {`r`n"
	$content += "    exit`r`n"
	$content += "}`r`n"
}

if ($Sounds -ne $NO_SOUND) {
	$random = (Get-Random -Minimum 0 -Maximum $Sounds.length)
	$content += "& 'C:\Program Files\VideoLAN\VLC\vlc.exe' -I null --play-and-exit --no-repeat `"$($Sounds[$random])`"`r`n"
}

if ($Commands -ne $NO_COMMAND) {
	for ($i = 0; $i -lt $Commands.length; $i++) {
		$content += "$($Commands[$i])`r`n"
	}
}

if ($Urgency -ge $URG_LOW) {
	$content += "`$message = `"Sent     @ $datetime | $Message``r``nReceived @ `$currentDatetime |``r``n-------------------------------+`"`r`n"
	$content += "Write-Host `$message`r`n"
	if ($Urgency -ge $URG_MEDIUM) {
		$content += "Add-Type -AssemblyName System.Windows.Forms`r`n"
		$content += "`$script:balloon = New-Object System.Windows.Forms.NotifyIcon`r`n"
		$content += "`$path = (Get-Process -id `$pid).Path`r`n"
		$content += "`$balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon(`$path)`r`n"
		$content += "`$balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::None`r`n"
		$content += "`$balloon.BalloonTipText = '$Message'`r`n"
		$content += "`$balloon.BalloonTipTitle = 'Time Manager'`r`n"
		$content += "`$balloon.Visible = `$true`r`n"
		$content += "`$balloon.ShowBalloonTip(5000)`r`n"
		$content += "`$script:balloon.Dispose()`r`n"
		if ($Urgency -ge $URG_HIGH) {
			$content += "[System.Windows.Forms.MessageBox]::Show('$Message', 'Time Manager', 'OK', 'None') | Out-Null`r`n"
		}
	}
}

if ($Priority -gt $PRI_NO_PERSIST) {
	$content += "Add-Content $LOG -Value `$message -Encoding 'UTF8'`r`n"
	if ($Priority -gt $PRI_LOG_ONLY) {
		if ($TodoRepeating -eq $TODO_ONCE) {
			$content += "`$priority = $Priority`r`n"
			$content += "if (-not (Test-Path `"$TODOS\(`$priority) $Message _auto`")) {`r`n"
			$content += "    Out-File `"$TODOS\(`$priority) $Message _auto`" | Out-Null`r`n"
			$content += "}`r`n"
		} elseif ($TodoRepeating -eq $TODO_DECREMENT) {
			$content += "`$new = `$true`r`n"
			$content += "for (`$i = $Priority; `$i -gt 0; `$i--) {`r`n"
			$content += "    if (Test-Path `"$TODOS\(`$i) $Message _auto`") {`r`n"
			$content += "        if (`$i -gt 1) {`r`n"
			$content += "            Rename-Item `"$TODOS\(`$i) $Message _auto`" `"(`$(`$i - 1)) $Message _auto`"`r`n"
			$content += "        }`r`n"
			$content += "        `$new = `$false`r`n"
			$content += "        break`r`n"
			$content += "    }`r`n" 
			$content += "}`r`n"
			$content += "if (`$new) {`r`n"
			$content += "    `$priority = $Priority; Out-File `"$TODOS\(`$priority) $Message _auto`" | Out-Null`r`n"
			$content += "}`r`n"
		} elseif ($TodoRepeating -eq $TODO_INCREMENT) {
			$content += "`$priority = $Priority`r`n"
			$content += "`$delays = 1`r`n"
			$content += "while (Test-Path `"$TODOS\(`$priority) $Message (`$delays) _auto`") {`r`n"
			$content += "    `$delays++`r`n"
			$content += "}`r`n"
			$content += "Out-File `"$TODOS\(`$priority) $Message (`$delays) _auto`" | Out-Null`r`n"
		}
	}
}

Set-Content $script -Value $content -Encoding 'UTF8' -NoNewLine