# AwSpinch - pronounced "Awwww, Spinach"
## Overview
AwSpinch is designed to pinch nameserver records that have expired from AWS.

This is an NS-type subdomain takeover (SDTO), where a subdomain has been delegated out to AWS' Route 53,
but has since been deleted from Route 53 without also deleting the NS pointer.

It's hard to tell if you can claim these NS records typically, because there's no way to request
a particular Delegation Set from AWS.

As a result, the most commonly cited tool for claiming these NS records is "Brute53", which (in typical
fashion) I only discovered after writing AwSpinch. Then I realised how AwSpinch was already better than
Brute53 and how I can improve even further on it.

## Requirement: AWS Tools for PowerShell

Install with the following command:

```Install-Module -Name AWS.Tools.Route53```

Make sure to set a credential to use with:

`Set-AWSCredential` (as in https://docs.aws.amazon.com/powershell/latest/userguide/specifying-your-aws-credentials.html)

## Use

```./awspinch.ps1 domain.example.com``` -- try and take over domain.example.com

This will try to take over the domain specified, by creating and deleting Delegation Sets until
a Delegation Set is created that has ONE name server in common with the targeted domain.

An exception ("Failed servers aren't at AWS") will be thrown if the targeted domain doesn't have
NS records pointing to Route 53.

## History

The original version is rather simplistic, in that it will create Delegation Sets and then delete them,
over and over, until a DS has one of the endpoints' name servers in hand, at which point it will register
the targeted subdomain name and return a success.

Even this version was very successful when faced with a domain that needed taking over.

Subsequent improvements have been/will be:

1. Done: Using the AWS Tools for PowerShell instead of the AWS CLI
1. Keeping the Delegation Sets in hand for use in later scans
1. Checking the Delegation Sets in hand for matches
1. Making it a CmdLet so you can provide your own parameters
1. Scanning for multiple endpoint domains
