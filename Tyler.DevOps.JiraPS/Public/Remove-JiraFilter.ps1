function Remove-JiraFilter {
    # .ExternalHelp ..\Tyler.DevOps.JiraPS-help.xml
    [CmdletBinding( ConfirmImpact = "Medium", SupportsShouldProcess, DefaultParameterSetName = 'ByInputObject' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('Tyler.DevOps.JiraPS.Filter')]
        $InputObject,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [UInt32[]]
        $Id,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [String]
        $AuthToken = $null
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $InputObject = foreach ($_id in $Id) {
                Get-JiraFilter -Id $_id
            }
        }

        foreach ($filter in $InputObject) {
            $parameter = @{
                URI        = $filter.RestURL
                Method     = "DELETE"
                Credential = $Credential
                AuthToken  = $AuthToken
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($filter.Name, "Deleting Filter")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
