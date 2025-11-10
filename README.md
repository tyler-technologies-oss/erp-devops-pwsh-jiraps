TYLER.DEVOPS.JIRAPS

## Instructions

### Installation

Install Tyler.DevOps.JiraPS from the [PowerShell Gallery]! `Install-Module` requires PowerShellGet (included in PS v5, or download for v3/v4 via the gallery link)

```powershell
# One time only install:
Install-Module Tyler.DevOps.JiraPS -Scope CurrentUser

# Check for updates occasionally:
Update-Module Tyler.DevOps.JiraPS
```

### Usage

```powershell
# To use each session:
Import-Module Tyler.DevOps.JiraPS
Set-JiraConfigServer 'https://YourCloud.atlassian.net'
New-JiraSession -Credential $cred
```

```powershell
# Review the help at any time!
Get-Help about_Tyler.DevOps.JiraPS
Get-Command -Module Tyler.DevOps.JiraPS
Get-Help Get-JiraIssue -Full # or any other command
```
