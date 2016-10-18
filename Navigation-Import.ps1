Add-PSSnapin "Microsoft.SharePoint.Powershell" -ErrorAction SilentlyContinue

# import settings (update to match the destination environment settings)
$DestinationUrl = "http://example.com/"
$DestinationTermStoreName = "Managed Metadata Service Application"
$DestinationTermGroupName = "Site Collection - example.com"
$DestinationTermSetName = "Top Navigation"
$ImportFileName = "Navigation.xml"

# import term set
function ImportTermset([string]$siteUrl, [string]$termStoreName, [string]$groupName, [string]$termSetName, [string]$exportedFileName){

  # connect to site and term store
  $Site = get-SPSite $siteUrl
  $session = Get-SPTaxonomySession -Site $Site
  $termStore = $session.TermStores[$termStoreName]
  if($termStore -ne $null){

    write-host "Connected to"$termStore.Name -Foreground Magenta

    # connect to the group and term set
    if($termStore.Groups[$groupName] -eq $null){
      $termStoreGroup = $termStore.CreateGroup($groupName)
      write-host "Group [$groupName] created" -Foreground Cyan
    }
    else{
      $termStoreGroup =$termStore.Groups[$groupName]
      write-host "Group [$groupName] found" -Foreground Cyan
    }

    # get exported file
    $ScriptsFolder = [System.IO.Path]::GetDirectoryName($MyInvocation.PSCommandPath)
    $filePath = [System.IO.Path]::Combine($ScriptsFolder, $exportedFileName)
    if(-not (Test-Path $filePath)){
      write-host "$filePath does not exist" -Foreground Red
    }
    else{
      write-host "Importing [$filePath]..." -Foreground Green

      # get exported xml
      [xml]$termsetXML = Get-Content $filePath
      if($termsetXML -eq $null){
        write-host "Exported file not valid" -Foreground Red
        return
      }

      # find or create term set
      $termSet = $termStoreGroup.TermSets | where{$_.name -eq $termSetName}
      if($termSet -ne $null){
        write-host "Term set [$termsetname] found" -Foreground Yellow
      }
      else{
        $termSet = $termStoreGroup.CreateTermSet($termSetName)
        write-host "Term set [$termsetname] created" -Foreground Yellow
        $termStore.CommitAll()
      }

      # sort order?
      $names = @{}
      $order = @{}
      if($termsetXML.TermSet.Sort -ne $null){
        $i = 0
        foreach($name in $termsetXML.TermSet.Sort.InnerText.Split("|")){
          $names[$i] = $name
          $i++
        }
      }

      # import terms
      foreach($term in $termsetXML.TermSet.Terms.Term){
        ImportTerm $term $termSet
      }

      # sort
      if($termsetXML.TermSet.Sort -ne $null){
        write-host "Ordering term set..." -Foreground Yellow
        $orderstring = ""
        $i = 0
        $order = $order.GetEnumerator() | Sort-Object Name
        foreach($item in $order.GetEnumerator()){
          if($i -gt 0){
            $orderstring += ":"
          }
          $orderstring += $item.Value
          $i++
        }
        #write-host $orderstring
        $termSet.CustomSortOrder = $orderstring
      }

    }

    # update the term store
    $termStore.CommitAll()

  }

}

# import term
function ImportTerm([System.Xml.XmlNode]$term, $parent){

  # get term
  $name = $term.Name
  $name = $name -replace '&','&'
  write-host "Term [$name]"

  # create term
  $newterm = $parent.CreateTerm($name, 1033)

  # IsAvailableForTagging
  $newterm.IsAvailableForTagging = $term.IsAvailableForTagging

  # SimpleLinkUrl
  if($term.SimpleLinkUrl -ne $null){
    $newterm.SetLocalCustomProperty('_Sys_Nav_SimpleLinkUrl', $term.SimpleLinkUrl)
  }

  # TargetUrl
  $TargetUrl = $term.TargetUrl
  if($TargetUrl -ne $null){
    $newterm.SetLocalCustomProperty('_Sys_Nav_TargetUrl', $TargetUrl)
  }

  # TargetUrlForChildTerms
  $TargetUrlForChildTerms = $term.TargetUrlForChildTerms
  if($TargetUrlForChildTerms -ne $null){
    $newterm.SetLocalCustomProperty('_Sys_Nav_TargetUrlForChildTerms', $TargetUrlForChildTerms)
  }

  # Title
  if($term.Title -ne $null){
    $newterm.SetLocalCustomProperty('_Sys_Nav_Title', $term.Title)
  }

  # Exclusions
  if($term.Exclusions -ne $null){
    $newterm.SetLocalCustomProperty('_Sys_Nav_ExcludedProviders', $term.Exclusions)
  }

  # commit
  $termStore.CommitAll()

  # sort?
  foreach($item in $names.GetEnumerator()){
    if($term.Name -eq $item.Value){
      $order[$item.Key] = $newterm.ID
      break
    }
  }

  # child terms
  ImportChildTerms $term $newterm

}

# import child terms
function ImportChildTerms([System.Xml.XmlNode]$node, $parent){
  foreach($childnode in $node.Terms.Term){
    ImportTerm $childnode $parent
  }
}

#import
ImportTermset -siteUrl $DestinationUrl -termStoreName $DestinationTermStoreName -groupName $DestinationTermGroupName -termSetName $DestinationTermSetName -exportedFileName $ImportFileName
