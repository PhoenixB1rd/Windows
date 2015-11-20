function Get-LocalAccountPolicy 
{
    <#
    .SYNOPSIS
    Returns the value of the local account group policy, will optionally create a report.

    .DESCRIPTION
    Queries the server, local or remote, for the local group policies that are inherited. 
    Then out of the group policies that are inherited, which ones are affecting the account lockout and password policies.
    
    .PARAMETER Server
    A computer name or an array of computer names to query their local policies.
    
    .PARAMETER DomainName
    Domain that the server(s) reside in, must be the FQDN for this script to work. the script is unable to check multiple domains at this time.
    
    .PARAMETER Path
    The location that you would like the report to be saved to.
    
    
    .PARAMETER ReportType
    If the Report type is specified, then the function will output a report of the group policy that is in control of the local account lockout and password policies.
    Default is HTML
    
    
    .EXAMPLE
    Places a list of server names into a variable. Calls the server variable in the script, generates an html report on the GPO that effect the account lockout
    and password policies. Then pipes the result of the report switch to an html file.

    $Servers = Get-Content C:\temp\servers.txt.
    Get-LocalAccountPolicy -Server $Servers -Domain contoso.com -Report HTML -Path C:\temp
    
    
    .NOTES
    This script requires the Group policy RSTAT tools to be installed as well as Active Directory.
    
    .NOTES
    Derived from many ideas and thoughts, referenced Hey,Scripting Guy for the ouput values. More can be found from Hey, Scripting Guy here:
    http://blogs.technet.com/b/heyscriptingguy/archive/2014/01/09/use-powershell-to-get-account-lockout-and-password-policy.aspx 

    .NOTES
    Created by PhoenixB1rd


    #>

    [CmdletBinding()] 
    param
    (
    [string]$ComputerName,
    [string]$DomainName,
    [string]$Path,
    [ValidateSet('HTML','XML')]
    [string]$Reportype = 'HTML' 
    )

    $Distname = Get-ADComputer $ComputerName -Server $DomainName
    $Ou = $DistName -replace "^[C][N]=($computername),?"
    $Links = Get-Gpinheritance $OU -Domain $DomainName | select -ExpandProperty GPoLinks
    foreach($GPO in $Links)
    {
        $GpoId = $GPO | select -ExpandProperty GpoId
        Get-GPOReport -Guid $GpoId -ReportType $Reportype -Path $Path\$ComputerName.html -Domain $DomainName 
    }
    
    
    <#$PasswordPolicy = Get-ADObject $RootDSE.defaultNamingContext -Property minPwdAge, maxPwdAge, minPwdLength, pwdHistoryLength, pwdProperties 

Next, produce a customized output that represents the policy:

     $PasswordPolicy | Select @{n="PolicyType";e={"Password"}},`

                              DistinguishedName,`

                              @{n="minPwdAge";e={"$($_.minPwdAge / -864000000000) days"}},`

                              @{n="maxPwdAge";e={"$($_.maxPwdAge / -864000000000) days"}},`

                              minPwdLength,`

                              pwdHistoryLength,`

                              @{n="pwdProperties";e={Switch ($_.pwdProperties) {

                                  0 {"Passwords can be simple and the administrator account cannot be locked out"}

                                  1 {"Passwords must be complex and the administrator account cannot be locked out"}

                                  8 {"Passwords can be simple, and the administrator account can be locked out"}

                                  9 {"Passwords must be complex, and the administrator account can be locked out"}

                                  Default {$_.pwdProperties}}}}
                                  }


   

    Using this as a source to filter out the data. I would like it to make a report though. http://blogs.technet.com/b/heyscriptingguy/archive/2014/01/09/use-powershell-to-get-account-lockout-and-password-policy.aspx

    #>

    )


}