<#
    .SYNOPSIS
    Add-NewUsers.ps1 creates Active Directory users from a CSV file with specified attributes, adds them to specified groups, and handles errors if they occur.
 
    .DESCRIPTION
    Create Active Directory users from a CSV file with specified attributes, add them to specified groups, and handle errors gracefully.
 
    .PARAMETER CsvPath
    The path to the CSV file containing user details.
 
    .PARAMETER UPN
    The User Principal Name (UPN) suffix to be used for the new users.
 
    .PARAMETER password
    The password to be set for the new users.
 
    .PARAMETER Groups
    An array of groups to which the new users will be added.
 
    .NOTES
    Written by: Jesse Bethke
 
    .EXAMPLE
    .\Add-Users.ps1 -CsvPath "C:\Path\To\NewUsers.csv" -UPN "example.com" -password "P@ssw0rd" -Groups "Group1","Group2"
    This command will create new users from the specified CSV file, set their UPN suffix to "example.com", assign the password "P@ssw0rd", and add them to "Group1" and "Group2".
#>
 
param(
    [string]$CsvPath = "template.csv",
    [string]$UPN = "Sandbox.com",
    [string]$password = "P@ssw0rd"
)
 
# Import active directory module for running AD cmdlets
Import-Module ActiveDirectory
 
# Store the data from NewUsers.csv in the $ADUsers variable
$CsvPath = "$PSScriptRoot\$CsvPath"
$ADUsers = Import-Csv $CsvPath
 
# Loop through each row containing user details in the CSV file
foreach ($User in $ADUsers) {
    try {
        # Define the parameters using a hashtable
        $UserParams = @{
            SamAccountName        = $User.username
            UserPrincipalName     = "$($User.username)@$UPN"
            Name                  = "$($User.firstname) $($User.lastname)"
            GivenName             = $User.firstname
            Surname               = $User.lastname
            Enabled               = $True
            DisplayName           = "$($User.firstname) $($User.lastname)"
            Path                  = $User.ou #This field refers to the OU the user account is to be created in
            City                  = $User.city
            EmailAddress          = $User.email
            Title                 = $User.jobtitle
            Department            = $User.department
            AccountPassword       = (ConvertTo-SecureString $password -AsPlainText -Force)
            ChangePasswordAtLogon = $True
        }
 
        # Check to see if the user already exists in AD
        if (Get-ADUser -Filter "SamAccountName -eq '$($User.username)'") {
 
            # Give a warning if user exists
            Write-Host "A user with username $($User.username) already exists in Active Directory." -ForegroundColor Yellow
            # Check if the user is already a member of the groups specified in the CSV
            $UserGroups = $User.groups -split ","
            foreach ($Group in $UserGroups) {
                if (Get-ADGroupMember -Identity $Group | Where-Object { $_.SamAccountName -eq $User.username }) {
                    Write-Host "User $($User.username) is already a member of group $Group." -ForegroundColor Yellow
                }
                else {
                    Add-ADGroupMember -Identity $Group -Members $User.username
                    Write-Host "Added $($User.username) to group $Group." -ForegroundColor Cyan
                }
            }
        }
        else {
            # User does not exist then proceed to create the new user account
            # Account will be created in the OU provided by the $User.ou variable read from the CSV file
            New-ADUser @UserParams
 
            # If user is created, show message.
            Write-Host "The user $($User.username) is created." -ForegroundColor Green
            
            # Read groups from CSV and split them into an array
            $UserGroups = $User.groups -split ","
            
            # Add user to specified groups
            foreach ($Group in $UserGroups) {
                Add-ADGroupMember -Identity $Group -Members $User.username
                Write-Host "Added $($User.username) to group $Group." -ForegroundColor Cyan
            }
        }
    }
    catch {
        # Handle any errors that occur during account creation
        Write-Host "Failed to create user $($User.username) - $_" -ForegroundColor Red
    }
}