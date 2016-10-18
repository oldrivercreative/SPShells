# config
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$solution = "Solution.wsp"
$defaultwebapp = "example.com"

# retract
Write-Host -ForegroundColor Cyan "Uninstalling solution..."
$webapp = Read-Host "  Enter web application name or GUID [$defaultwebapp]"
$webapp = ($defaultwebapp, $webapp)[[bool]$webapp]
Uninstall-SPSolution -Identity $solution -WebApplication $webapp -Confirm:$false

# wait for retract
$deployed = $True
write-host "  Waiting" -nonewline
while ($deployed -eq $True) {
  sleep -s 2
  Write-Host "." -nonewline
  $s = Get-SPSolution -Identity $solution
  if ($s.Deployed -eq $False -And $s.JobExists -eq $False) {
    $deployed = $False
  }
}
write-host ""

# remove
Write-Host -ForegroundColor Cyan "Removing solution..."
Remove-SPSolution -Identity $solution -Confirm:$false

# done
Write-Host "Uninstalled in $($timer.Elapsed.ToString())." -ForegroundColor Green
