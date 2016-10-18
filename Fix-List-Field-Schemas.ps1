Add-PSSnapin "Microsoft.SharePoint.Powershell" -ErrorAction SilentlyContinue

# update settings
$url = "http://example.com/"
$site = Get-SPSite -Identity $url
write-host “Site [$($site.Url)]" -ForegroundColor Yellow

# field list
$updatefields = @(
  "Field1",
  "Field2",
  "Field3"
)

# all web lists
foreach($web in $site.AllWebs){
  if($web -ne $null){

    # web name
    write-host "  Web [$($web.Url)]" -ForegroundColor Cyan

    # update lists
    foreach($list in $web.Lists){

      # get list
      write-host "    List [$($list.Title)]"

      # update fields
      foreach($field in $list.Fields){
        foreach($updatefield in $updatefields){
          if($field.Title -eq $updatefield -and $field.SourceID -ne "http://schemas.microsoft.com/sharepoint/v3"){
            $schema = $field.SchemaXml -ireplace 'SourceID="([^"]*)"','SourceID="http://schemas.microsoft.com/sharepoint/v3"'
            $field.SchemaXml = $schema
            $field.Update()
            write-host "      Field [$($field.Title)] updated."
            # write-host "        $($schema)"
          }
        }
      }

    }

    # dispose web
    $web.Dispose()

  }
}

# dispose site
$site.Dispose()
