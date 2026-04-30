# EnterpriseApps-GetSamlConfigs.ps1

## Description

This PowerShell script retrieves SAML (Security Assertion Markup Language) application configurations from Microsoft Azure Active Directory (Azure AD) using the Microsoft Graph API. It collects details about service principals configured for SAML single sign-on (SSO) and exports the information to a CSV file for analysis or reporting.

The script gathers key SAML configuration properties such as display names, URLs, signing key validity, and audience settings, making it useful for auditing SAML applications in an Azure AD tenant.

## Prerequisites

Before running this script, ensure the following:

1. **PowerShell Modules**: Install the required Microsoft Graph modules:
   - `Microsoft.Graph.Applications`
   - `Microsoft.Graph.Beta.Applications`
   - `Microsoft.Graph.Identity.SignIns`

   You can install them using:
   ```powershell
   Install-Module Microsoft.Graph.Applications
   Install-Module Microsoft.Graph.Beta.Applications
   Install-Module Microsoft.Graph.Identity.SignIns
   ```

2. **Permissions**: The account running the script must have appropriate permissions in Azure AD. The script requires the `Application.Read.All` scope.

3. **Execution Policy**: Ensure your PowerShell execution policy allows script execution. You may need to run:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
   ```

## Usage

1. Open PowerShell and navigate to the directory containing the script.

2. Run the script:
   ```powershell
   .\EnterpriseApps-GetSamlConfigs.ps1
   ```

3. When prompted, authenticate with your Azure AD credentials that have the necessary permissions.

4. The script will process all SAML applications and export the results to a CSV file in the `.\Temp\` directory (relative to the script's location). The filename will include a timestamp, e.g., `SamlApps-20230430-123456.csv`.

## Output

The CSV file contains the following columns for each SAML application:

- **DisplayName**: The display name of the application.
- **Id**: The service principal ID.
- **AppId**: The application ID.
- **LoginUrl**: The login URL for SAML.
- **LogoutUrl**: The logout URL for SAML.
- **NotificationEmailAddresses**: Email addresses for notifications (pipe-separated if multiple).
- **AppRoleAssignmentRequired**: Whether app role assignment is required.
- **PreferredSingleSignOnMode**: The SSO mode (should be 'saml').
- **PreferredTokenSigningKeyEndDateTime**: The end date/time of the preferred token signing key.
- **PreferredTokenSigningKeyValid**: Boolean indicating if the signing key is still valid (compared to current date).
- **ReplyUrls**: Reply URLs (pipe-separated if multiple).
- **SignInAudience**: The sign-in audience (e.g., 'AzureADMyOrg' for single tenant, 'AzureADMultipleOrgs' for multi-tenant).

## Troubleshooting

- **Authentication Errors**: Ensure you have the correct permissions and that the Microsoft Graph modules are installed and up to date.
- **Module Not Found**: If you encounter module import errors, reinstall the modules or check your PowerShell module path.
- **CSV Export Issues**: Verify that the `.\Temp\` directory exists and is writable. The script uses `-NoClobber` to avoid overwriting existing files.
- **Beta API Usage**: The script uses the Beta version of the Microsoft Graph API for some properties (e.g., `PreferredTokenSigningKeyEndDateTime`). Be aware that Beta APIs may change.
- **Execution Policy**: If the script won't run, adjust your execution policy as mentioned in prerequisites.

## Notes

- This script connects to Microsoft Graph interactively. For automated scenarios, consider using app-only authentication.
- The script filters for service principals with `PreferredSingleSignOnMode eq 'saml'`.
- All dates are handled in UTC.
- The script uses the Beta Graph API for certain properties; monitor Microsoft documentation for any changes.

## Credits

Based on discussion from: https://github.com/orgs/msgraph/discussions/63