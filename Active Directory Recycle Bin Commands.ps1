# Import Active Directory module
Import-Module ActiveDirectory

# Check replication status
repadmin /replsummary

# Enable Active Directory Recycle Bin
Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target 'learnitlessons.com'

# Verify Recycle Bin status
Get-ADOptionalFeature -Filter 'name -like "recycle*"'

# Create test user
New-ADUser -Name "TestUser1" `
           -GivenName "Test" `
           -Surname "User" `
           -SamAccountName "TestUser1" `
           -UserPrincipalName "TestUser1@learnedlessons.com" `
           -Enabled $true `
           -AccountPassword (ConvertTo-SecureString "SomePass1" -AsPlainText -Force)

# Verify user creation
Get-ADUser TestUser1

# Delete test user
Remove-ADUser TestUser1 -Confirm:$false

# Search for deleted user
Get-ADObject -Filter {samAccountName -eq "TestUser1"} -IncludeDeletedObjects -Properties *

# Store deleted user info in variable
$deletedUser = Get-ADObject -Filter {samAccountName -eq "TestUser1"} -IncludeDeletedObjects -Properties *

# Restore deleted user
Restore-ADObject -Identity $deletedUser

# Verify user restoration
Get-ADUser TestUser1
