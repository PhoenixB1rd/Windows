Function Get-RemoteServices
{
    <#
    .SYNOPSIS
    Returns the value of a WMI or CMI class object.
    
    .DESCRIPTION
    Get-RemoteServices allows the use of different protocols and different session options in the same function. This function can be used with either WMI-classes or CMI-classes. You can optionally 
    pass in credentials if the server you are querying is remote, or if a seperate set of credentials is needed to access the server.

    .PARAMETER PSCredential
    The Username and Password stored as a credential for authenticating to remote servers (Only applies to remote servers)

    .PARAMETER ServerName
    A single server name or an array of server names.

    .PARAMETER Option
    Specifies the CimSession Protocol option to use.

    .PARAMETER ClassName
    Specifies which WMI or CMI class to query on the server(s).

    .EXAMPLE
    

    .EXAMPLE 


    .NOTES
    Author = PhoenixB1rd

    #>
    [CmdletBinding()] param(
        $PSCredential,
        [Parameter(ValueFromPipeline=$True)][string]$ServerName,
        $Options,
        $ClassName
    )

   
    $Option = New-CimSessionOption -Protocol DCOM
      foreach ($Computer in $ServerName) {
        try {
          if ($Credential) {
            $Session = New-CimSession -Credential $PSCredential -ComputerName $Computer -SessionOption $Option
          }
          else {
            $Session = New-CimSession -ComputerName $Computer -SessionOption $Option
          }
        }
        catch {
          break
        }
        Get-CimInstance -CimSession $Session -ClassName $ClassName 
        }

}