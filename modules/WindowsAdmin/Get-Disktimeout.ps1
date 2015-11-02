function Get-DiskTimeout
{
    <#
    .SYNOPSIS
    Returns the disk timeout value for the virtual server.

    .DESCRIPTION
    The Get-DiskTimeout queries the virtual machine for the registry key that hold the disk timeout value. This commandlet 
    does not allow for credentials to be used. Therefore, this command must be used from a domain that has trusts with the domain the servers are located on.
    This command must also be ran with elevate permissions. So far, this can be accomplished through RDP or a Citrix box that has taken your M account credentials.

    .PARAMETER ServerName
    A single computer name or an array of server names.

    .PARAMETER Credential
    Specifies a user account that has permission to perform this action. The default is the current user. Type a
    user name, such as "User01", "Domain01\User01", or User@Contoso.com. Or, enter a PSCredential object, such as
    an object that is returned by the Get-Credential cmdlet. When you type a user name, you are prompted for a
    password.

    .PARAMETER ManageDiskOnSystemBuses
    Specifies if the command will also retrieve the value for HKLM\System\CurrentControlSet\Services\ClusDisk\Parameters\ManageDisksOnSystemBuses 
    Registry key. If this Switch is included, it will use an Invoke-Command for some querying. 
    If WSMAn is blocked or disallowed through a firewall this parameter will not work.


    .PARAMETER MaxRequestHoldTime
    Specifies if the command will also retrieve the value for HKLM\System\CurrentControlSet\Control\Class\{iSCSI_driver_GUID}\Instance_ID\Parameters\MxRequestHoldTime
    Registry key. 


    .PARAMETER LinkDownTime
    Specifies if the command will also retrieve the value for HKLM\System\CurrentControlSet\Control\Class\{iSCSI_driver_GUID}\Instance_ID\Parameters\LinkDownTime 
    Registry key. If this Switch is included, it will use an Invoke-Command for some querying. 
    If WSMAn is blocked or disallowed through a firewall this parameter will not work.



    .EXAMPLE
    View the disk timeout value for a single server.
    Get-DiskTimeout -ServerName myserver.tlr.thomson.com

    .EXAMPLE
    View the disk timeout value for an array of servers and export the data to a csv (which can then be opened using Excel).
    Import-Csv C:\temp\listofservers.csv | Get-DiskTimeout | Export-csv C:\temp\results.csv -NoTypeInformation

    .NOTES
    Author - PhoenixB1rd


    #>

    [CmdletBinding()] param
    (
        [Parameter(ValueFromPipeline=$True)][string[]]$ServerName,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,
        [switch]$ManageDisksonSystemBuses,
        [switch]$MaxRequestHoldTime,
        [switch]$LinkDownTime
    )
     $credSplat = @{}
    if ($Credential -ne $null)
    {
        $credSplat['Credential'] = $Credential
    }
      
     foreach($server in $ServerName)
   
     {
         $array = @()
         $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', "$Server".Guest.Hostname)
         $TimeoutValue = $reg.OpenSubKey("System\CurrentControlSet\Services\disk\").GetValue("TimeoutValue")

        Switch ($PSBoundParameters.Keys)
        {
            'ManageDisksonSystemBuses' { $SystemBuses = $reg.OpenSubKey("System\CurrentControlSet\Services\ClusDisk\Parameters\").GetValue("ManageDiskOnSystemBuses") }
        
            'MaxRequestHoldTime'
                                                                                                                                                                                {
                    $array1 = @()
                    foreach($server in $ServerName)
                    {
                        $Session = New-PSSession -ComputerName $Server -Credential @credSplat    #For the invoke commands later
                        $keynames = $reg.OpenSubKey("System\CurrentControlSet\Services\Class\").GetSubKeyNames()
       
                        foreach($key in $keynames)
                        {
                            #finding if there is a SCSI adapter driver entry in the registry, if there is it will be added to the first array. This likely will not work if WSMAN is not allowed through firewalls.
                            $Property = Invoke-Command -Session $Session -ScriptBlock { Get-ItemProperty -Path "Registry::HKLM\System\CurrentControlSet\Control\Class\$using:key" }
                            if ($Property.Class -match "SCSI")
                            {
                                $array1 += $key       #I used the array just in case there was more than one SCSI adapter entry in the registy
                            }
   
                        }
                        if($array1 -ne $null)
                        {
                            foreach($SCSIkey in $array1)
                            { 
                                $Instances = $reg.OpenSubKey("System\CurrentControlSet\Services\Class\$SCSIkey").GetSubKeyNames() 
                                if($Instances -ne $null) 
                                {
                                    $Instances.Remove("Properties")
                                    foreach($ID in $Instances)
                                    {
                                        if($reg.OpenSubKey("System\CurrentControlSet\Services\Class\$SCSIkey\$ID\Parameters\"))
                                        {
                                           $MaxRequest = $reg.OpenSubKey("System\CurrentControlSet\Services\Class\$SCSIkey\$ID\Parameters\").GetValue("MaxRequestHoldTime")
                                        }
                                    }       
                                }
                            }

                        }
                         else
                        {
                            $MaxRequest = "No SCSI driver found"
                        }
                    }

                  }

            'LinkDownTime'   
                                                                                                                                                                            {
                    $array2 = @()
                    foreach($server in $ServerName)
                    {
                        $Session = New-PSSession -ComputerName $Server -Credential @credsplat
                        $keynames = $reg.OpenSubKey("System\CurrentControlSet\Services\Class\").GetSubKeyNames()
       
                        foreach($key in $keynames)
                        {
                            $Property = Invoke-Command -Session $Session -ScriptBlock { Get-ItemProperty -Path "Registry::HKLM\System\CurrentControlSet\Control\Class\$using:key" }
                            if ($Property.Class -match "SCSI")
                            {
                                $array2 += $key
                            }
   
                        }
                        if($array2 -ne $null)
                        {
                            foreach($SCSIkey in $array2)
                            { 
                                $Instances = $reg.OpenSubKey("System\CurrentControlSet\Services\Class\$SCSIkey").GetSubKeyNames() 
                                if($Instances -ne $null) 
                                {
                                    $Instances.Remove("Properties")
                                    foreach($ID in $Instances)
                                    {
                                        if($reg.OpenSubKey("System\CurrentControlSet\Services\Class\$SCSIkey\$ID\Parameters\"))
                                        {
                                           $LinkDown = $reg.OpenSubKey("System\CurrentControlSet\Services\Class\$SCSIkey\$ID\Parameters\").GetValue("LinkDownTime")
                                        }
                                    $MxRequestHoldTime = Invoke-Command -Session $Session -ScriptBlock{ "$Using:reg".OpenSubKey("$Using:SCSIkey\$using:ID\Parameters").GetValue("MaxRequestHoldTime") }
                                    }       
                                }
                            }

                        }
                         else
                        {
                            $LinkDownTime = "No SCSI driver found"
                        }
                    }

       }
        }
    
        $array += $Object = New-Object psobject -Property @{
            ServerName = $Server
            TimeoutValue = $TimeoutValue
            ManageDiskOnSystemBuses = $SystemBuses
            MaxRequestHoldTime = $MaxRequest
            LinkDownTime = $LinkDownTime
            }
    
    }   
    Return $array
}

