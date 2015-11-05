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

    .PARAMETER PSCredential
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
    Registry key. If this Switch is included, it will use an Invoke-Command for some querying. 
    If WSMAn is blocked or disallowed through a firewall this parameter will not work.


    .PARAMETER LinkDownTime
    Specifies if the command will also retrieve the value for HKLM\System\CurrentControlSet\Control\Class\{iSCSI_driver_GUID}\Instance_ID\Parameters\LinkDownTime 
    Registry key. If this Switch is included, it will use an Invoke-Command for some querying. 
    If WSMAn is blocked or disallowed through a firewall this parameter will not work.



    .EXAMPLE
    View the disk timeout value for a single server using a stored credential variable.
    
    $creds = Get-Credential
    Get-DiskTimeout -ServerName myserver.tlr.thomson.com -PSCredential $creds

    .EXAMPLE
    View the disk timeout value for an array of servers, and adding the additional switches. Then piping the output
    to export the data to a csv (which can then be opened using Excel).
    
    $Creds = Get-Credential
    Import-Csv C:\temp\listofservers.csv | % {Get-DiskTimeout -Servername $_ -PSCredential $creds -ManageDisksonSystemBuses |
    Export-csv C:\temp\results.csv -NoTypeInformation
    
    
    .NOTES
    This Script may not work if you have to cross a domain to get to the remote registry values. 
    The credentials are for when I use an invoke command to get specific information from the registry.

    .NOTES
    Author - PhoenixB1rd


    #>

    [CmdletBinding()] param
    (
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string[]]$ServerName,
        [PsCredential]$PSCredential,
        [switch]$ManageDisksonSystemBuses,
        [switch]$MaxRequestHoldTime,
        [switch]$LinkDownTime
    )

    function Get-DiskRegKey {
        
    }

     $Array = @()
     $credSplat = @{}
    if ($PSCredential -ne $null)
    {
        $credSplat.add('Credential', $PSCredential)
    }
      
     foreach($Server in $ServerName)
 
     {
          $MaxRequest = @()
          $LinkDown = @()
          $Session = New-PSSession -ComputerName $Server  @credsplat
          $TimeoutValue = Invoke-Command -Session $Session -ScriptBlock { $reg = Get-Item -Path "Registry::HKLM\System\CurrentControlSet\Services\disk\" ; $reg.getValue("TimeoutValue") }
                   

        Switch ($PSBoundParameters.Keys)
        {
            'ManageDisksonSystemBuses'
                    { 
                        $names = Invoke-Command -Session $Session -ScriptBlock { $reg0 = Get-Item -Path "Registry::HKLM\System\CurrentControlSet\services\" ; $reg0.getsubkeynames() }
                        if($names -contains "ClusDisk")
                        {
                            $Manage = Invoke-Command -Session $Session -ScriptBlock { Get-ItemProperty -Path "Registry::HKLM\System\CurrentControlSet\services\clusDisk\Parameters\" }
                            $SystemBuses = $Manage.ManageDisksOnSystemBuses
                        }
                        else
                        {
                            $SystemBuses = "ManageDiskOnSystemBuses value was not found in the registry."
                        }
                    }
        
            'MaxRequestHoldTime'
                   {                                                                                                                                                             
                            $array1 = @()
                            $MaxRequest = $null
                            $keynames = Invoke-Command -Session $Session -ScriptBlock { $reg1 = Get-Item -Path "Registry::HKLM\System\CurrentControlSet\control\class\" ; $reg1.getsubkeynames() }
       
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
                                $Instances1 = @()
                                foreach($SCSIkey in $array1)
                                { 
                                    $Instances1 = Invoke-Command -Session $Session -ScriptBlock { $reg2 = Get-Item -Path "Registry::HKLM\System\CurrentControlSet\Control\Class\$using:ScsiKey" ; $reg2.Getsubkeynames() }
                                    if($Instances1 -ne $null) 
                                    {
                                        $Collection1 = $null
                                        $Collection1 = {$Instances1}.Invoke() 
                                        $Collection1.Remove("Properties") | Out-Null
                                        foreach($ID in $Collection1)
                                        {
                                            $Statement = Invoke-Command -Session $Session -ScriptBlock { Get-ItemProperty -Path "Registry::HKLM\System\CurrentControlSet\Control\Class\$using:ScsiKey\$using:ID\Parameters" }
                                            if($Statement -ne $null)
                                            {
                                               $MaxRequest += $Statement.MaxRequestHoldTime
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

            'LinkDownTime'   
                  {                                                                                                                                                             
                            $array2 = @()
                            $LinkDown = $null
                            $keynames2 = Invoke-Command -Session $Session -ScriptBlock { $reg3 = Get-Item -Path "Registry::HKLM\System\CurrentControlSet\control\class\" ; $reg3.getsubkeynames() }
       
                            foreach($key2 in $keynames2)
                            {
                                #finding if there is a SCSI adapter driver entry in the registry, if there is it will be added to the first array. This likely will not work if WSMAN is not allowed through firewalls.
                                $Property2 = Invoke-Command -Session $Session -ScriptBlock { Get-ItemProperty -Path "Registry::HKLM\System\CurrentControlSet\Control\Class\$using:key2" }
                                if ($Property2.Class -match "SCSI")
                                {
                                    $array2 += $key2       #I used the array just in case there was more than one SCSI adapter entry in the registy
                                }
   
                            }
                            if($array2 -ne $null)
                            {
                                $Instances2 = @()
                                foreach($SCSIkey2 in $array2)
                                { 
                                    $Instances2 = Invoke-Command -Session $Session -ScriptBlock { $reg4 = Get-Item -Path "Registry::HKLM\System\CurrentControlSet\Control\Class\$using:ScsiKey2" ; $reg4.Getsubkeynames() }
                                    if($Instances2 -ne $null) 
                                    {
                                        $Collection2 = $null
                                        $Collection2 = {$Instances2}.Invoke() 
                                        $Collection2.Remove("Properties") | Out-Null
                                        foreach($ID2 in $Collection2)
                                        {
                                            $Statement2 = Invoke-Command -Session $Session -ScriptBlock { Get-ItemProperty -Path "Registry::HKLM\System\CurrentControlSet\Control\Class\$using:ScsiKey2\$using:ID2\Parameters" }
                                            if($Statement2 -ne $null)
                                            {
                                              
                                               $LinkDown += ($Statement2.LinkDownTime)
                                            }
                                            
                                        }       
                                    }
                                }
                           
                            }
                             else
                            {
                                $LinkDown = "No SCSI driver found"
                            }
                  }
        }
    #This creates the a new object that is outputed to screen by default by can be exported into a csv file if after the function you type | export-csv <destination> -NoTypeInformation
            [pscustomobject]@{
            ServerName = $Server
            TimeoutValue = $TimeoutValue
            ManageDiskOnSystemBuses = $SystemBuses
            MaxRequestHoldTime = $MaxRequest
            LinkDownTime = $LinkDown
            }
       Remove-PSSession -Session $Session
    }   
  
 
}

