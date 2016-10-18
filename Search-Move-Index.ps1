# settings
$SearchServiceName = "Search Service Application"  # The name of your Search Service Application being altered
$Server = "spweb1-index"   # The name of the Index server currently being used
$IndexLocation = "E:\SearchIndex" # The full path to the new Index location

# move search index
function SearchIndexMove($SearchServiceName,$Server,$IndexLocation) {

  # dependencies
  Add-PSSnapin Microsoft.SharePoint.PowerShell -ea 0;

  # Get the Search Service Application
  Write-Host -ForegroundColor Cyan "Getting service application...";
  $SSA = Get-SPServiceApplication -Name $SearchServiceName;

  # Get the Search Service Instance
  Write-Host -ForegroundColor Cyan "Getting service instance...";
  $Instance = Get-SPEnterpriseSearchServiceInstance -Identity $Server;

  # Get the current Search topology
  Write-Host -ForegroundColor Cyan "Getting topology...";
  $Current = Get-SPEnterpriseSearchTopology -SearchApplication $SSA -Active;

  # Create a clone of the current Search topology
  Write-Host -ForegroundColor Cyan "Cloning topology...";
  $Clone = New-SPEnterpriseSearchTopology -Clone -SearchApplication $SSA -SearchTopology $Current;

  # Add a new Index Component and the new Index location
  Write-Host -ForegroundColor Cyan "Adding index component to new location...";
  New-SPEnterpriseSearchIndexComponent -SearchTopology $Clone -IndexPartition 0 -SearchServiceInstance $Instance -RootDirectory $IndexLocation | Out-Null;
  if (!$?) { throw "ERROR: Check that `"$IndexLocation`" exists on `"$Server`""; }

  # Set the new Search topology as "Active"
  Write-Host -ForegroundColor Cyan "Setting new topology as active...";
  Set-SPEnterpriseSearchTopology -Identity $Clone;

  # Remove the old Search topology
  Write-Host -ForegroundColor Cyan "Removing old topology...";
  Remove-SPEnterpriseSearchTopology -Identity $Current -Confirm:$false;

  # There is an additional Index Component that needs removing
  # Get the Search topology again
  Write-Host -ForegroundColor Cyan "Getting search topology again...";
  $Current = Get-SPEnterpriseSearchTopology -SearchApplication $SSA -Active;

  # Create a clone of the current Search topology
  Write-Host -ForegroundColor Cyan "Cloning current search topology...";
  $Clone = New-SPEnterpriseSearchTopology -Clone -SearchApplication $SSA -SearchTopology $Current;

  # Get the Index Component and remove the old one
  Write-Host -ForegroundColor Cyan "Getting index component and removing old one...";
  Get-SPEnterpriseSearchComponent -SearchTopology $Clone | ? {($_.GetType().Name -eq "IndexComponent") -and ($_.ServerName -eq $($Instance.Server.Address)) -and ($_.RootDirectory -ne $IndexLocation)} | Remove-SPEnterpriseSearchComponent -SearchTopology $Clone -Confirm:$false;

  # Set the new Search topology as "Active"
  Write-Host -ForegroundColor Cyan "Setting new topology as active again...";
  Set-SPEnterpriseSearchTopology -Identity $Clone;

  # Remove the old Search topology
  Write-Host -ForegroundColor Cyan "Removing old topology again...";
  Remove-SPEnterpriseSearchTopology -Identity $Current -Confirm:$False;
  Write-Host -ForegroundColor Green "Finished, remember to clean up the old Index location";

}

# run
SearchIndexMove -SearchServiceName $SearchServiceName -Server $Server -IndexLocation $IndexLocation
