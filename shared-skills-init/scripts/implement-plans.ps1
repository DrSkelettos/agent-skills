[CmdletBinding()]
param(
    [string] $PlansDirectory = (Join-Path $PSScriptRoot '..\docs\plans\09-ecg-print-extension'),
    [string] $Model = 'opencode-go/muse-spark-1.3-contributor',
    [string] $Thinking = 'xhigh'
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$resolvedPlansDirectory = (Resolve-Path $PlansDirectory).Path
$plans = @(Get-ChildItem -Path $resolvedPlansDirectory -Filter '*.md' -File | Sort-Object -Property Name)

if ($plans.Count -eq 0) {
    throw "No Markdown plans were found in '$resolvedPlansDirectory'."
}

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    throw 'The opencode command was not found on PATH.'
}

Push-Location $repositoryRoot
try {
    $planNumber = 0
    foreach ($plan in $plans) {
        $planNumber++
        $effectiveModel = if ([string]::IsNullOrWhiteSpace($Thinking)) { $Model } else { "$Model#$Thinking" }
        Write-Host "[$planNumber/$($plans.Count)] Implementing $($plan.Name) with $effectiveModel..."

        $prompt = "implement the attached plan '$($plan.Name)' in this repository. Complete its verification and commit steps as specified. Do not start another plan."
        & opencode run --model $effectiveModel --auto --file $plan.FullName $prompt

        if ($LASTEXITCODE -ne 0) {
            throw "OpenCode failed while implementing '$($plan.Name)' (exit code $LASTEXITCODE). Stopping before the next plan."
        }

        Write-Host "Finished $($plan.Name)."
    }
} finally {
    Pop-Location
}

Write-Host "Finished all $($plans.Count) plan(s) in '$resolvedPlansDirectory'."
