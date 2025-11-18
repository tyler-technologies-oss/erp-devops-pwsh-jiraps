function Move-JiraVersion {
    # .ExternalHelp ..\Tyler.DevOps.JiraPS-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ByAfter' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("Tyler.DevOps.JiraPS.Version" -notin $_.PSObject.TypeNames) -and (($_ -isnot [Int]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraVersion'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Version. Expected [Tyler.DevOps.JiraPS.Version] or [Int], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $Version,

        [Parameter( Mandatory, ParameterSetName = 'ByPosition' )]
        [ValidateSet('First', 'Last', 'Earlier', 'Later')]
        [String]$Position,

        [Parameter( Mandatory, ParameterSetName = 'ByAfter' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (("Tyler.DevOps.JiraPS.Version" -notin $_.PSObject.TypeNames) -and (($_ -isnot [Int]))) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter") #fix code highlighting]
                    $errorId = 'ParameterType.NotJiraVersion'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Wrong object type provided for Version. Expected [Tyler.DevOps.JiraPS.Version] or [Int], but was $($_.GetType().Name)"
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    <#
                      #ToDo:CustomClass
                      Once we have custom classes, this check can be done with Type declaration
                    #>
                }
                else {
                    return $true
                }
            }
        )]
        [Object]
        $After,

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

        $server = Get-JiraConfigServer -ErrorAction Stop

        $versionResourceUri = "$server/rest/api/2/version/{0}/move"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $requestBody = @{ }
        switch ($PsCmdlet.ParameterSetName) {
            'ByPosition' {
                $requestBody["position"] = $Position
            }
            'ByAfter' {
                $afterSelfUri = ''
                if ($After -is [Int]) {
                    $versionObj = Get-JiraVersion -Id $After -Credential $Credential -ErrorAction Stop
                    $afterSelfUri = $versionObj.RestUrl
                }
                else {
                    $afterSelfUri = $After.RestUrl
                }

                $requestBody["after"] = $afterSelfUri
            }
        }

        if ($Version.Id) {
            $versionId = $Version.Id
        }
        else {
            $versionId = $Version
        }

        $parameter = @{
            URI        = $versionResourceUri -f $versionId
            Method     = "POST"
            Body       = ConvertTo-Json $requestBody
            Credential = $Credential
            AuthToken  = $AuthToken
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        Invoke-JiraMethod @parameter
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
