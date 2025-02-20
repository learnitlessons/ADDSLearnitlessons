### Learnitlessons.com ###

New-VHD -ParentPath "D:\VM\vhd\win22.vhdx" -Path D:\vm\LIT-ROUTER\LIT-ROUTER.vhdx -Differencing -Verbose
New-VM -Name LIT-ROUTER -MemoryStartupBytes 3Gb -VHDPath D:\vm\LIT-ROUTER\LIT-ROUTER.vhdx -Path D:\vm\LIT-ROUTER  -Generation 1 -SwitchName Ext

set-vm LIT-ROUTER -CheckpointType Disabled
start-vm LIT-ROUTER



### STEP 1 ###

# LAN2                        10.0.0.1              24
# LAN1                        192.168.2.1           24
# WAN                         192.168.1.2           24

#-----------------------------------------------
# LIT-DC1 Configuration (192.168.1.22)
#-----------------------------------------------
# Set computer name
Rename-Computer -NewName "LIT-DC1" -Restart -Force

# Configure IP settings
$interfaceIndex = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceIndex
New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress 192.168.2.22 -PrefixLength 24 -DefaultGateway 192.168.2.1
Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses 192.168.1.1

# Verify configuration
Write-Host "LIT-DC1 Configuration:" -ForegroundColor Green
Get-NetIPAddress -InterfaceIndex $interfaceIndex | Format-Table
Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex | Format-Table

#-----------------------------------------------
# LIT-SVR1 Configuration (192.168.2.10)
#-----------------------------------------------
# Set computer name
Rename-Computer -NewName "LIT-SVR1" -Force

# Configure IP settings
$interfaceIndex = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceIndex
New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress 192.168.2.10 -PrefixLength 24 -DefaultGateway 192.168.2.1
Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses 192.168.1.1

# Verify configuration
Write-Host "LIT-SVR1 Configuration:" -ForegroundColor Green
Get-NetIPAddress -InterfaceIndex $interfaceIndex | Format-Table
Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex | Format-Table

#-----------------------------------------------
# LIT-SVR2 Configuration (10.0.0.10)
#-----------------------------------------------
# Set computer name
Rename-Computer -NewName "LIT-SVR2" -Force

# Configure IP settings
$interfaceIndex = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceIndex
New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress 10.0.0.10 -PrefixLength 24 -DefaultGateway 10.0.0.1
Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses 192.168.1.1

# Verify configuration
Write-Host "LIT-SVR2 Configuration:" -ForegroundColor Green
Get-NetIPAddress -InterfaceIndex $interfaceIndex | Format-Table
Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex | Format-Table

#-----------------------------------------------
# LIT-ROUTER Configuration
#-----------------------------------------------
# Set computer name
Rename-Computer -NewName "LIT-ROUTER" -Force

# Configure interfaces
# 1. WAN Interface connecting to WiFi Router
$wanInterface = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet"}
Rename-NetAdapter -Name $wanInterface.Name -NewName "WAN"
New-NetIPAddress -InterfaceIndex $wanInterface.InterfaceIndex -IPAddress 192.168.1.2 -PrefixLength 24 -DefaultGateway 192.168.1.1
Set-DnsClientServerAddress -InterfaceIndex $wanInterface.InterfaceIndex -ServerAddresses 192.168.1.1

# 2. LAN Interface for 192.168.2.0/24 network (LIT-SVR1)
$lan1Interface = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet 2"}
Rename-NetAdapter -Name $lan1Interface.Name -NewName "LAN1"
New-NetIPAddress -InterfaceIndex $lan1Interface.InterfaceIndex -IPAddress 192.168.2.1 -PrefixLength 24

# 3. LAN Interface for 10.0.0.0/24 network (LIT-SVR2)
$lan2Interface = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet 3"}
Rename-NetAdapter -Name $lan2Interface.Name -NewName "LAN2"
New-NetIPAddress -InterfaceIndex $lan2Interface.InterfaceIndex -IPAddress 10.0.0.1 -PrefixLength 24

# Create Lab Checkpoint
Stop-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER
Set-VM LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER -CheckpointType Production
Get-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER
Checkpoint-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER -SnapshotName 'net lab initial'
Start-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER



### STEP 2 ###

# Enable IP forwarding to act as a router
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name IPEnableRouter -Value 1

# Configure routing
# Get interface indexes first
$wanInterfaceIndex = (Get-NetAdapter -Name "WAN").InterfaceIndex
$lan1InterfaceIndex = (Get-NetAdapter -Name "LAN1").InterfaceIndex
$lan2InterfaceIndex = (Get-NetAdapter -Name "LAN2").InterfaceIndex

# Add routes
# Route to internal networks through the appropriate interfaces
New-NetRoute -DestinationPrefix 192.168.2.0/24 -InterfaceIndex $lan1InterfaceIndex -NextHop 192.168.2.1
New-NetRoute -DestinationPrefix 10.0.0.0/24 -InterfaceIndex $lan2InterfaceIndex -NextHop 10.0.0.1

# Default route to internet via WiFi router
New-NetRoute -DestinationPrefix 0.0.0.0/0 -InterfaceIndex $wanInterfaceIndex -NextHop 192.168.1.1

# Configure NAT for internet access
Install-WindowsFeature -Name Routing -IncludeManagementTools
Install-RemoteAccess -VpnType RoutingOnly
cmd.exe /c "netsh routing ip nat install"
cmd.exe /c "netsh routing ip nat add interface WAN mode=full"
cmd.exe /c "netsh routing ip nat add interface LAN1"
cmd.exe /c "netsh routing ip nat add interface LAN2"

# Verify configuration
Write-Host "LIT-ROUTER Configuration:" -ForegroundColor Green
Get-NetIPAddress | Where-Object {$_.InterfaceAlias -like "WAN" -or $_.InterfaceAlias -like "LAN*"} | Format-Table
Get-NetRoute | Format-Table

# Restart networking services to apply changes
Restart-Service -Name RemoteAccess

# Create Lab Checkpoint
Stop-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER 
Get-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER
Checkpoint-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER -SnapshotName 'net lab with routing'
Start-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER


# Revert to Checkpoint
Stop-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER 
@("LIT-DC1", "LIT-SVR1", "LIT-SVR2", "LIT-ROUTER") | ForEach-Object {
    Restore-VMSnapshot -VMName $_ -Name "net lab initial" -Confirm:$false
}


# Enter-PSSession
$Credentials=Get-Credential
etsn -VMName LIT-DC1 -Credential $Credentials
etsn -VMName LIT-SVR1 -Credential $Credentials
etsn -VMName LIT-SVR2 -Credential $Credentials
etsn -VMName LIT-ROUTER -Credential $Credentials


Get-VMNetworkAdapter -VMName "LIT-ROUTER" | Select-Object Name, SwithcName, MacAddress
Get-VMSwitch | Select-Object Name, SwitchType

Get-VMNetworkAdapter -VMName "LIT-ROUTER" |
Select-Object Name, MacAddress, SwitchName, @{
Name = "SwitchType";
Expression = { (Get-VMSwitch -Name $_.SwithName).SwitchType }
}

Stop-VM -Name LIT-DC1,LIT-SVR1,LIT-SVR2,LIT-ROUTER 
Remove-VM LIT-DC1 -Force
Remove-Item -Recurse D:\vm\LIT-DC1 -Force
