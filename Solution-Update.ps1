#config
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$solution = "Solution.wsp"
$path = ".\" + $solution

# add
Write-Host -ForegroundColor Cyan "Updating solution..."
Update-SPSolution -Identity $solution -LiteralPath (Resolve-Path $path) -GACDeployment -force

# wait for deploy
$deployed = $False
write-host "  Waiting" -nonewline
while ($deployed -eq $False) {
  sleep -s 2
  Write-Host "." -nonewline
  $s = Get-SPSolution -Identity $solution
  if ($s.Deployed -eq $True -And $s.JobExists -eq $False) {
    $deployed = $True
  }
}
write-host ""

# done
Write-Host "Updated in $($timer.Elapsed.ToString())." -ForegroundColor Green
