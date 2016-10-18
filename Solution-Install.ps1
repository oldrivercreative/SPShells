#config
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$solution = "Solution.wsp"
$path = ".\" + $solution
$defaultwebapp = "example.com"

# add
Write-Host -ForegroundColor Cyan "Adding solution..."
Add-SPSolution (Resolve-Path $path)

# install
Write-Host -ForegroundColor Cyan "Installing solution..."
$webapp = Read-Host "  Enter web application name or GUID [$defaultwebapp]"
$webapp = ($defaultwebapp, $webapp)[[bool]$webapp]
Install-SPSolution -Identity $solution -GACDeployment -WebApplication $webapp -force

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
Write-Host "Installed in $($timer.Elapsed.ToString())." -ForegroundColor Green
