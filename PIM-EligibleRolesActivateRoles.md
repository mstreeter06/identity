# PIM-EligibleRolesActivateRoles.ps1

## Description

This PowerShell script automates the activation of eligible Privileged Identity Management (PIM) roles for the current user in Microsoft Entra (formerly Azure Active Directory). It connects to Microsoft Graph, retrieves the user's eligible roles, allows interactive selection of roles to activate, and submits activation requests with specified justification and duration.

## Prerequisites

- **PowerShell**: Ensure you have PowerShell installed (version 5.1 or later recommended).
- **Microsoft Graph PowerShell Module**: Install the module if not already present.
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  ```
- **Permissions**: You must have the necessary permissions in Microsoft Entra to activate PIM roles.
- **Scopes**: Connect to Microsoft Graph with at least the following scopes:
  - `User.Read.All`
  - `RoleManagement.ReadWrite.Directory`

## Usage

1. **Connect to Microsoft Graph**:
   ```powershell
   Connect-MgGraph -Scopes "User.Read.All", "RoleManagement.ReadWrite.Directory"
   ```

2. **Run the Script**:
   ```powershell
   .\PIM-EligibleRolesActivateRoles.ps1
   ```

3. **Follow Prompts**:
   - The script will display a list of your eligible roles with index numbers.
   - Enter the number(s) of the roles to activate (comma-separated, e.g., `1,3`) or `A` for all.
   - Provide a justification for activation.
   - Specify the duration in hours (default is 8 hours if invalid input).

## Parameters

The script is interactive and does not accept command-line parameters. It prompts for:
- **Role Selection**: Choose from the listed eligible roles.
- **Justification**: A required reason for activating the roles.
- **Duration**: Number of hours for the activation (must be positive integer).

## Examples

### Example 1: Activate a Single Role
```
Available Roles:
[1] Global Administrator
[2] User Administrator

Enter the number(s) of the roles to activate (comma-separated, e.g., 1,3) or 'A' for all: 1

Selected Roles for Activation:
RoleDisplayName    CreatedDateTime       MemberType
-----------------  -------------------  ----------
Global Administrator 2023-10-01T00:00:00Z Eligible

Enter a justification for activating these roles: Performing maintenance tasks
Enter the duration in hours for the activation (e.g., 1, 4, 8) - default 8 hours: 4

Attempting to activate role: Global Administrator
Successfully submitted activation request for Global Administrator.
Request ID: abc123-def456
Request Status: Provisioned
```

### Example 2: Activate Multiple Roles
```
Enter the number(s) of the roles to activate: 1,2

Selected Roles for Activation:
RoleDisplayName    CreatedDateTime       MemberType
-----------------  -------------------  ----------
Global Administrator 2023-10-01T00:00:00Z Eligible
User Administrator   2023-10-01T00:00:00Z Eligible

Enter a justification: Emergency access required
Enter the duration: 2
```

## Notes

- Ensure your account has eligible PIM roles assigned. If no roles are found, the script will exit with a warning.
- Activation requests are submitted to Microsoft Entra and may require approval based on your organization's PIM policies.
- The script uses UTC time for scheduling and ISO 8601 format as required by PIM.
- If activation fails, check your permissions and Graph connection.
- This script performs "self-activation" for the current user only.

## Troubleshooting

- **Connection Issues**: Verify you are connected to Microsoft Graph with the correct scopes.
- **Permission Errors**: Ensure you have PIM eligibility and activation permissions.
- **No Eligible Roles**: Check your PIM assignments in the Azure portal.
- **Activation Failures**: Review the error messages and consult Microsoft documentation for PIM role activation.

## License

This script is provided as-is. Use at your own risk.