Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =============================================================
#  設定パラメータ（このファイル内で直接定義してください）
# -------------------------------------------------------------
#  以前は terraform output 等のコンソール出力から取得していた値を、
#  以下の変数として手動定義する方式に変更しています。
# =============================================================

# デプロイ先 VM の接続情報
# 旧: terraform output -raw vm_public_ip など
$vmIp = ''
$vmUser = 'azureuser'
$sshKey = '~/.ssh/id_rsa_iac_workshop'

# =============================================================

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

function ConvertTo-BashSingleQuotedString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $singleQuote = [string][char]39
    $escapedSingleQuote = $singleQuote + '\' + $singleQuote + $singleQuote
    return $singleQuote + ($Value -replace [regex]::Escape($singleQuote), $escapedSingleQuote) + $singleQuote
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

        if ($standardOutput) {
            [Console]::Out.Write($standardOutput)
        }

        if ($standardError) {
            [Console]::Error.Write($standardError)
        }

        if ($process.ExitCode -ne 0) {
            throw $FailureMessage
        }
    }
    finally {
        if ($previousLocation) {
            Set-Location -LiteralPath $previousLocation
        }
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$infraRoot = Split-Path -Parent $scriptDir
$generatedDir = Join-Path $infraRoot 'docker/generated'
$dockerDir = Join-Path $infraRoot 'docker'

if (-not $vmIp) {
    throw 'VM の IP アドレスが未設定です。スクリプト冒頭の $vmIp を設定してください。'
}

Write-Host "Using SSH key: $sshKey"

$composePath = Join-Path $generatedDir 'docker-compose.yml'
if (-not (Test-Path -LiteralPath $composePath)) {
    throw "Error: $composePath not found. Run scripts/gen-compose.py first."
}

Write-Host "Deploying to $vmUser@$vmIp ..."

$remoteHost = "$vmUser@$vmIp"
$remoteScript = 'cd /opt/workshop/docker && sudo docker compose build && sudo docker compose up -d && sudo docker compose ps'
$remoteCommand = "bash -lc " + (ConvertTo-BashSingleQuotedString -Value $remoteScript)
$workspaceDir = Join-Path $dockerDir 'workspaces'
$workspaceItems = @()
if (Test-Path -LiteralPath $workspaceDir) {
    $workspaceItems = @(Get-ChildItem -LiteralPath $workspaceDir)
}

Invoke-Tool -FilePath 'ssh' -ArgumentList @('-i', $sshKey, '-o', 'StrictHostKeyChecking=accept-new', $remoteHost, "mkdir -p /opt/workshop/docker /opt/workshop/workspaces && sudo chown -R $vmUser`:$vmUser /opt/workshop") -FailureMessage 'Failed to prepare directories on VM.'
Invoke-Tool -FilePath 'scp' -ArgumentList @('-i', $sshKey, (Join-Path $dockerDir 'Dockerfile'), (Join-Path $dockerDir 'entrypoint.sh'), (Join-Path $dockerDir 'setup-git-credentials.sh'), $composePath, (Join-Path $generatedDir '.env'), "${remoteHost}:/opt/workshop/docker/") -FailureMessage 'Failed to copy workshop files to VM.'
if ($workspaceItems.Count -gt 0) {
    $workspaceCopyArgs = @('-i', $sshKey, '-r') + ($workspaceItems | ForEach-Object { $_.FullName }) + @("${remoteHost}:/opt/workshop/workspaces/")
    Invoke-Tool -FilePath 'scp' -ArgumentList $workspaceCopyArgs -FailureMessage 'Failed to copy workspace directories to VM.'
}
Invoke-Tool -FilePath 'ssh' -ArgumentList @('-i', $sshKey, $remoteHost, "sudo chown -R $vmUser`:$vmUser /opt/workshop/workspaces") -FailureMessage 'Failed to fix workspace ownership on VM.'
Invoke-Tool -FilePath 'ssh' -ArgumentList @('-i', $sshKey, $remoteHost, $remoteCommand) -FailureMessage 'Failed to build or start docker compose on VM.'

Write-Host 'Deployment complete.'
