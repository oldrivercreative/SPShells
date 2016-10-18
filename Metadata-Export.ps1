Add-PSSnapin "Microsoft.SharePoint.Powershell" -ErrorAction SilentlyContinue

# export settings (update to match the source environment settings)
$SourceUrl = "http://example.com/"
$SourceTermStoreName = "Managed Metadata Service Application"
$SourceTermGroupName = "Term Group Name"
$SourceTermSetName = "Term Set Name"
$ExportFileName = "Tags.xml"

function ExportTermset([string]$siteUrl, [string]$termStoreName, [string]$groupName, [string]$termsetName, [string]$fileName){

  # connect
  $Site = Get-SPSite $siteUrl
  $session = Get-SPTaxonomySession -Site $Site
  $termStore = $session.TermStores[$termStoreName]
  if($termStore -ne $null){

    # get set
    $group = $termStore.Groups | Where{$_.name -eq $groupName}
    if($group -ne $null){

      write-host "Group [$groupName]..." -Foreground Yellow
      $termset = $group.TermSets | Where {$_.name -eq $termsetName}
      if($termset -ne $null){

        # file path
        $ScriptsFolder = [System.IO.Path]::GetDirectoryName($MyInvocation.PSCommandPath)
        $filePath = [System.IO.Path]::Combine($ScriptsFolder, $fileName)

        # xml doc
        $XmlWriter = New-Object System.XMl.XmlTextWriter($filePath, $Null);
        $XmlWriter.Formatting = "Indented"
        $XmlWriter.Indentation = "4"
        $XmlWriter.WriteStartDocument()
        write-host "Exporting term set [$termsetName] to [$filePath]..." -Foreground Green

        # termset
        $XmlWriter.WriteStartElement("TermSet")
        $XmlWriter.WriteAttributeString("Name", $termset.Name)

        # CustomSortOrder
        $order = @{}
        if($termset.CustomSortOrder -ne $null){
          $i = 0
          $guids = $termset.CustomSortOrder.Split(":")
          foreach($guid in $guids){
            $order[$i] = $guid
            $i++
          }
        }

        # terms
        $XmlWriter.WriteStartElement("Terms")
        $termset.Terms | ForEach {
          WriteTerm $_
        }

        # /terms
        $XmlWriter.WriteEndElement()

        # Sort
        if($termset.CustomSortOrder -ne $null){
          $sortstring = ""
          $i = 0
          foreach($item in $order.GetEnumerator()){
            if($i -gt 0){
              $sortstring += "|"
            }
            $sortstring += $item.Value
            $i++
          }
          write-host $sortstring
          $XmlWriter.WriteStartElement("Sort")
          $xmlWriter.WriteCData($sortstring)
          $XmlWriter.WriteEndElement()
        }

        # /termset
        $XmlWriter.WriteEndElement()

        # close
        $XmlWriter.Flush()
        $XmlWriter.Close()

      }
      else{
        write-host "Termset specified for export does not exist" -ForegroundColor Cyan
      }
    }
    else{
      write-host "Group specified for export does not exist" -ForegroundColor Yellow
    }
  }
  else{
    write-host "Termstore specified for export does not exist" -ForegroundColor Cyan
  }
}

# write term to xml
function WriteTerm([Microsoft.SharePoint.Taxonomy.Term] $Term){

  # term
  #dump($Term.LocalCustomProperties)
  $XmlWriter.WriteStartElement("Term")

  # Name
  $updatedname = $Term.GetDefaultLabel(1033)
  $normalizedName = $updatedname -replace '&','&'
  write-host "Term [$normalizedName]"
  $XmlWriter.WriteAttributeString("Name", $normalizedName)

  # ID
  $XmlWriter.WriteAttributeString("ID", $Term.ID)

  # IsAvailableForTagging
  $XmlWriter.WriteAttributeString("IsAvailableForTagging", $Term.IsAvailableForTagging)

  # Title
  if($Term.LocalCustomProperties._Sys_Nav_Title -ne $null){
    $XmlWriter.WriteAttributeString("Title", $Term.LocalCustomProperties._Sys_Nav_Title)
  }

  # get children
  GetChildTerms $Term

  # /term
  $XmlWriter.WriteEndElement();

  # order?
  $i = 0
  foreach($item in $order.GetEnumerator()){
    if($item.Value -eq $Term.ID.ToString()){
      $order[$i] = $normalizedName
      break
    }
    $i++
  }

}

# get child terms
function GetChildTerms([Microsoft.SharePoint.Taxonomy.Term] $Term){

  # children?
  if($Term.Terms -ne $null){

    # terms
    $XmlWriter.WriteStartElement("Terms")
    $Term.Terms | ForEach {
      WriteTerm $_
    }

    # /terms
    $XmlWriter.WriteEndElement()

  }

}

# var dump
function dump($a) {
  if ($a -eq $null) {
    return "Null"
  } elseif ($a -is [object[]]) {
    $b = @()
    foreach ($x in $a) {
      $b += (pp $x)
    }
    $s = "@(" + [string]::Join(",", $b) + ")"
    return $s
  } else {
    return $a
  }
}

# export
ExportTermSet -siteUrl $SourceUrl -termStoreName $SourceTermStoreName -groupName $SourceTermGroupName -termsetName $SourceTermSetName -fileName $ExportFileName
