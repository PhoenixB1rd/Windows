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

    .EXAMPLE
    View the disk timeout value for a single server.
    Get-DiskTimeout -ServerName myserver.tlr.thomson.com

    .EXAMPLE
    View the disk timeout value for an array of servers and export the data to a csv (which can then be opened using Excel).
    Get-Contect C:\temp\listofservers.txt | Get-DiskTimeout | Export-csv C:\temp\results.csv -NoTypeInformation

    .NOTES
    Author - Hailey Dettmer


    #>

    [CmdletBinding()] param
    (
    [Parameter(ValueFromPipeline=$True)][string]$ServerName
    )

    $Added = @()
    $ServerNames | % 
    {
       $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $_.Guest.Hostname)
       Add-Member -InputObject $_ -MemberType NoteProperty -Name TimeoutValue -Value ($reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\Disk\").GetValue("TimeoutValue"))
       Add-Member -InputObject $_ -MemberType NoteProperty -Name ManageDisksonSystemBuses -Value ($reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\ClusDisk\Parameters\").GetValue("ManageDisksonSystemBuses"))
       Add-Member -InputObject $_ -MemberType NoteProperty -Name Max -Value ($reg.OpenSubKey("SYSTEM\CurrentControlSet\Control\Class{iscsi_driver_GUID}\instance_id\Parameters\").GetValue("Max"))
       Add-Member -InputObject $_ -MemberType NoteProperty -Name Link -Value ($reg.OpenSubKey("SYSTEM\CurrentControlSet\Control\Class{iscsi_driver_GUID}\instance_id\Parameters\").GetValue("Link"))
       $Added += $_
    } 
    return $Added 
}