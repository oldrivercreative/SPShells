# source: http://jeffreypaarhuis.com/2013/02/12/send-test-email-from-sharepoint/

Add-PSSnapin "Microsoft.SharePoint.Powershell" -ErrorAction SilentlyContinue

# email configuration
$email = "hi@test.com"
$subject = "SharePoint 2013 SMTP Test"
$body = "This is a test email originating from the SharePoint 2013 web application server. Please disregard."

# get web
$site = New-Object Microsoft.SharePoint.SPSite "http://sharepoint"
$web = $site.OpenWeb()

# send
[Microsoft.SharePoint.Utilities.SPUtility]::SendEmail($web, 0, 0, $email, $subject, $body)
