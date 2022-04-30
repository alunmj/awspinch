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

## History

The original version is rather simplistic, in that it will create Delegation Sets and then delete them,
over and over, until a DS has one of the endpoints' name servers in hand, at which point it will register
the targeted subdomain name and return a success.

Even this version was very successful when faced with a domain that needed taking over.

Subsequent improvements are/will be:

1. Making it a CmdLet so you can provide your own parameters
1. Using the AWS Tools for PowerShell instead of the AWS CLI
1. Keeping the Delegation Sets in hand for use in later scans
1. Scanning for multiple endpoint domains
1. Scanning for Delegation Sets, if you're planning on hitting a particular endpoint