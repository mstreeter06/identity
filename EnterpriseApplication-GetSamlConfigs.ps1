# Credit: https://github.com/orgs/msgraph/discussions/63
# Prerequisites: Install-Module Microsoft.Graph.Applications, *Microsoft.Graph.Beta.Applications*, Microsoft.Graph.Identity.SignIns
# * To gather #PreferredTokenSigningKeyEndDateTime value, you need to use the Beta Graph Get-MgBetaServicePrincipal cmdlet *

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All"

# Find all SAML Applications
[System.Collections.Generic.List[PSObject]]$samlApplicationsArray = @()
$samlApplications = Get-MgBetaServicePrincipal -Filter "PreferredSingleSignOnMode eq 'saml'" -All

foreach ($samlApp in $samlApplications) {
    $object = [PSCustomObject][ordered]@{
        DisplayName                         = $samlApp.DisplayName
        Id                                  = $samlApp.Id
        AppId                               = $samlApp.AppId
        LoginUrl                            = $samlApp.LoginUrl
        LogoutUrl                           = $samlApp.LogoutUrl
        NotificationEmailAddresses          = $samlApp.NotificationEmailAddresses -join '|'
        AppRoleAssignmentRequired           = $samlApp.AppRoleAssignmentRequired
        PreferredSingleSignOnMode           = $samlApp.PreferredSingleSignOnMode
        PreferredTokenSigningKeyEndDateTime = $samlApp.PreferredTokenSigningKeyEndDateTime
        # PreferredTokenSigningKeyEndDateTime is date time, compared to now and see it is valid
        PreferredTokenSigningKeyValid       = $samlApp.PreferredTokenSigningKeyEndDateTime -gt (Get-Date)
        ReplyUrls                           = $samlApp.ReplyUrls -join '|'
        SignInAudience                      = $samlApp.SignInAudience # AzureADMyOrg = Single tenant, AzureADMultipleOrgs = Multitenant
    }

    $samlApplicationsArray.Add($object)
}

#return $samlApplicationsArray

# Export to CSV
$samlApplicationsArray | Export-Csv -Path ".\Temp\SamlApps.csv" -Encoding UTF8 -NoClobber -NoTypeInformation 
