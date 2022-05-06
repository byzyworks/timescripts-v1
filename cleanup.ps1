$BIN        = '.\bin'
$CONFIGS    = '.\cfg'
$TODOS      = '.\todo'
$LOG        = '.\log.txt'

Remove-Item $BIN -Recurse -Force | Out-Null
Remove-Item $CONFIGS -Recurse -Force | Out-Null
Remove-Item $LOG -Force | Out-Null
$todoList = (Get-Item -Path $TODOS\*)
foreach ($todo in $todoList) {
	if ($todo -like '* _auto') {
		Remove-Item $todo -Force | Out-Null
	}
}