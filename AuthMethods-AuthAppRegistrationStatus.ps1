# AuthMethods-AuthAppRegistrationStatus.ps1
# This script gets the registration status of Microsoft Authenticator App as an authentication method for members of a security group
# V1.0 - 16-Apr-2026 - Initial version
# V1.1 - 16-Apr-2026 - Move GroupName and OutputCsvPath to Parameters
# V1.2 - 16-Apr-2026 - Large group optimization by batching API requests

# Prerequisites:
# Install-Module Microsoft.Graph.Groups
# Install-Module Microsoft.Graph.Users.Authentication

param(
    [Parameter(Mandatory=$true)]
    [string]$GroupName,

    [Parameter(Mandatory=$true)]
    [string]$OutputCsvPath
)

#region Connect to Microsoft Graph
# Scopes required:
# Group.Read.All - To read group memberships
# User.Read.All - To read basic user profiles
# UserAuthenticationMethod.Read.All - To read user authentication methods
# AuditLog.Read.All - To read sign-in activity (for SignInActivity property)
$RequiredScopes = @("Group.Read.All", "User.Read.All", "UserAuthenticationMethod.Read.All", "AuditLog.Read.All")

Write-Host "Connecting to Microsoft Graph with required scopes..." -ForegroundColor Cyan
try {
    # Attempt to connect. If already connected with sufficient scopes, it will reuse the connection.
    # Otherwise, it will prompt for authentication.
    Connect-MgGraph -Scopes $RequiredScopes -ErrorAction Stop
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. Please ensure you have the necessary permissions and try again. Error: $($_.Exception.Message)"
    return
}
#endregion

#region Get Security Group and Members
Write-Host "Searching for security group: '$GroupName'..." -ForegroundColor Cyan
try {
    $group = Get-MgGroup -Filter "DisplayName eq '$GroupName'" -ErrorAction Stop
    if (-not $group) {
        Write-Warning "No security group found with the name '$GroupName'."
        Disconnect-MgGraph
        return
    }
    Write-Host "Found group: $($group.DisplayName) (ID: $($group.Id))" -ForegroundColor Green
}
catch {
    Write-Error "Error finding security group: $($_.Exception.Message)"
    Disconnect-MgGraph
    return
}

Write-Host "Retrieving members of '$($group.DisplayName)'..." -ForegroundColor Cyan
$groupMembers = @()
try {
    # -All parameter handles pagination
    $groupMembers = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction Stop | Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.user' }
    Write-Host "Found $($groupMembers.Count) user members in the group." -ForegroundColor Green
}
catch {
    Write-Error "Error retrieving group members: $($_.Exception.Message)"
    Disconnect-MgGraph
    return
}

if ($groupMembers.Count -eq 0) {
    Write-Warning "No user members found in the security group. Exiting."
    Disconnect-MgGraph
    return
}
#endregion

#region Check Authentication Methods for Each User (Optimized with Batching)
$reportResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$batchSize = 20  # Max 20 requests per batch (Graph API limit)

Write-Host "Checking authentication methods for each user (using batched requests)..." -ForegroundColor Cyan

# Split users into batches
$userBatches = @()
for ($i = 0; $i -lt $groupMembers.Count; $i += $batchSize) {
    $userBatches += ,@($groupMembers[$i..([math]::Min($i + $batchSize - 1, $groupMembers.Count - 1))])
}

foreach ($batch in $userBatches) {
    $requests = @()
    $requestId = 0

    # Build batch requests for each user in the batch
    foreach ($member in $batch) {
        $userId = $member.Id
        $requestId++

        # Request 1: Get user details (with SignInActivity)
        $requests += @{
            id     = "$requestId-user"
            method = "GET"
            url    = "/users/$userId?`$select=UserPrincipalName,DisplayName,SignInActivity"
        }

        # Request 2: Get manager
        $requests += @{
            id     = "$requestId-manager"
            method = "GET"
            url    = "/users/$userId/manager?`$select=displayName,mail,userPrincipalName"
        }

        # Request 3: Get auth methods
        $requests += @{
            id     = "$requestId-auth"
            method = "GET"
            url    = "/users/$userId/authentication/methods"
        }
    }

    # Send batch request
    try {
        $batchResponse = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/`$batch" -Body @{ requests = $requests } -ErrorAction Stop
    }
    catch {
        Write-Warning "Batch request failed for a set of users. Error: $($_.Exception.Message). Skipping batch."
        continue
    }

    # Process batch responses
    $userData = @{}
    foreach ($response in $batchResponse.responses) {
        $parts = $response.id -split '-'
        $reqId = $parts[0]
        $type = $parts[1]
        $userId = $batch[$reqId - 1].Id  # Map back to user

        if (-not $userData.ContainsKey($userId)) {
            $userData[$userId] = @{
                UserDetails = $null
                Manager     = $null
                AuthMethods = @()
            }
        }

        if ($response.status -eq 200) {
            switch ($type) {
                'user'   { $userData[$userId].UserDetails = $response.body }
                'manager' { $userData[$userId].Manager = $response.body }
                'auth'   { $userData[$userId].AuthMethods = $response.body.value }
            }
        }
        else {
            Write-Warning "Failed to retrieve $type for user ID: $userId. Status: $($response.status)"
        }
    }

    # Build report for this batch
    foreach ($userId in $userData.Keys) {
        $data = $userData[$userId]
        if (-not $data.UserDetails) { continue }  # Skip if user details failed

        $userPrincipalName = $data.UserDetails.UserPrincipalName
        $displayName       = $data.UserDetails.DisplayName
        $lastSignIn        = $data.UserDetails.SignInActivity.LastSignInDateTime
        $lastSuccessfulSignIn = $data.UserDetails.SignInActivity.LastSuccessfulSignInDateTime

        # Manager info
        $managerName = "N/A"
        $managerMail = "N/A"
        if ($data.Manager) {
            $managerName = $data.Manager.displayName
            $managerMail = $data.Manager.mail
            if ([string]::IsNullOrWhiteSpace($managerMail)) { $managerMail = $data.Manager.userPrincipalName }
        }

        # Authenticator check
        $hasAuthenticator = $false
        foreach ($method in $data.AuthMethods) {
            if ($method.'@odata.type' -eq '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod') {
                $hasAuthenticator = $true
                break
            }
        }
        $status = if ($hasAuthenticator) { "Registered" } else { "Not Registered" }

        Write-Host "Processed user: $displayName ($userPrincipalName) -> $status" -ForegroundColor (if ($hasAuthenticator) { 'Green' } else { 'Red' })

        $reportResults.Add([PSCustomObject]@{
            DisplayName                  = $displayName
            UserPrincipalName            = $userPrincipalName
            UserId                       = $userId
            ManagerName                  = $managerName
            ManagerEmail                 = $managerMail
            AuthenticatorStatus          = $status
            LastSignInDateTime           = $lastSignIn
            LastSuccessfulSignInDateTime = $lastSuccessfulSignIn
            Group                        = $group.DisplayName
        })
    }
}
#endregion

#region Output Results
Write-Host "`nProcessing complete. Exporting results for $($reportResults.Count) users..." -ForegroundColor Cyan
$reportResults | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "Details exported to: $OutputCsvPath" -ForegroundColor Green

Disconnect-MgGraph
Write-Host "Script finished." -ForegroundColor Cyan
#endregion
