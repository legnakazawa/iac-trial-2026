Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-ProcessArgumentString {
    param(
        [string[]]$ArgumentList = @()
    )

    return ($ArgumentList | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '(\\*)"', '$1$1\\"' -replace '(\\+)$', '$1$1') + '"'
        }
        else {
            $_
        }
    }) -join ' '
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [string[]]$ArgumentList = @(),

        [string]$WorkingDirectory,

        [string]$FailureMessage = "Command failed: $FilePath"
    )

    $previousLocation = $null
    if ($WorkingDirectory) {
        $previousLocation = Get-Location
        Set-Location -LiteralPath $WorkingDirectory
    }

    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $FilePath
        $psi.Arguments = ConvertTo-ProcessArgumentString -ArgumentList $ArgumentList
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true

        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $psi
        [void]$process.Start()

        $standardOutput = $process.StandardOutput.ReadToEnd()
        $standardError = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        $combinedOutput = @($standardOutput, $standardError) -join ''
        if ($process.ExitCode -ne 0) {
            $details = $combinedOutput.Trim()
            if ($details) {
                throw "$FailureMessage`n$details"
            }

            throw $FailureMessage
        }

        if ($standardOutput) {
            [Console]::Out.Write($standardOutput)
        }

        if ($standardError) {
            [Console]::Error.Write($standardError)
        }

        return $combinedOutput.TrimEnd()
    }
    finally {
        if ($previousLocation) {
            Set-Location -LiteralPath $previousLocation
        }
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraRoot = Split-Path -Parent $scriptDir
$terraformDir = Join-Path $infraRoot 'terraform'
$workshopSrc = Join-Path $infraRoot 'workshop'

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tempRoot | Out-Null

try {
    $gitPat = Invoke-Tool -FilePath 'terraform' -ArgumentList @('output', '-raw', 'azuredevops_git_pat') -WorkingDirectory $terraformDir -FailureMessage 'terraform output -raw azuredevops_git_pat failed.'
    $reposJson = Invoke-Tool -FilePath 'terraform' -ArgumentList @('output', '-json', 'participant_repositories') -WorkingDirectory $terraformDir -FailureMessage 'terraform output -json participant_repositories failed.'
    $repos = $reposJson | ConvertFrom-Json
    $authBytes = [System.Text.Encoding]::ASCII.GetBytes(":$gitPat")
    $authHeader = 'AUTHORIZATION: Basic ' + [Convert]::ToBase64String($authBytes)

    foreach ($repoProperty in ($repos.PSObject.Properties | Sort-Object Name)) {
        $owner = $repoProperty.Name
        $repoUrl = $repoProperty.Value.remote_url

        Write-Host "Bootstrapping ${owner}: $repoUrl"

        $workdir = Join-Path $tempRoot $owner
        New-Item -ItemType Directory -Path $workdir -Force | Out-Null

        Get-ChildItem -LiteralPath $workshopSrc -Force | Copy-Item -Destination $workdir -Recurse -Force

        Invoke-Tool -FilePath 'git' -ArgumentList @('-C', $workdir, 'init') -FailureMessage "git init failed for $owner."
        Invoke-Tool -FilePath 'git' -ArgumentList @('-C', $workdir, 'config', 'user.name', 'iac-workshop-organizer') -FailureMessage "git config user.name failed for $owner."
        Invoke-Tool -FilePath 'git' -ArgumentList @('-C', $workdir, 'config', 'user.email', 'iac-workshop-organizer@example.local') -FailureMessage "git config user.email failed for $owner."
        Invoke-Tool -FilePath 'git' -ArgumentList @('-C', $workdir, 'add', '.') -FailureMessage "git add failed for $owner."
        Invoke-Tool -FilePath 'git' -ArgumentList @('-C', $workdir, 'commit', '-m', 'Initial workshop template') -FailureMessage "git commit failed for $owner."
        Invoke-Tool -FilePath 'git' -ArgumentList @('-C', $workdir, 'branch', '-M', 'main') -FailureMessage "git branch failed for $owner."
        Invoke-Tool -FilePath 'git' -ArgumentList @('-C', $workdir, 'remote', 'add', 'origin', $repoUrl) -FailureMessage "git remote add failed for $owner."
        Invoke-Tool -FilePath 'git' -ArgumentList @('-C', $workdir, '-c', "http.extraHeader=$authHeader", 'push', '-f', 'origin', 'main') -FailureMessage "git push failed for $owner."
    }

    Write-Host 'Repository bootstrap complete.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}