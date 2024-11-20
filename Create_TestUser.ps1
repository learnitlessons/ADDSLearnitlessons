 # Import the Active Directory module
Import-Module ActiveDirectory

# Define user parameters with timestamp for uniqueness
$timestamp = Get-Date -Format "MMddHHmm"
$userName = "TestUser$timestamp"
$userFirstName = "Test"
$userLastName = "User$timestamp"
$userPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
$userDomain = "learnitlessons.com"

# Create the new user
New-ADUser `
    -Name "$userFirstName $userLastName" `
    -GivenName $userFirstName `
    -Surname $userLastName `
    -SamAccountName $userName `
    -UserPrincipalName "$userName@$userDomain" `
    -AccountPassword $userPassword `
    -Enabled $true `
    -ChangePasswordAtLogon $true `
    -PasswordNeverExpires $false 
