[CmdletBinding()]
param(
    [string] $Base = 'dev',
    [string] $Title,
    [string] $Body,
    [switch] $Draft,
    [switch] $KeepLocalBranch
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'The git command was not found on PATH.'
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'The gh command was not found on PATH. Install it with "winget install GitHub.cli" then run "gh auth login".'
}

$branch = (git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
    throw 'Could not determine the current branch.'
}

if ($branch -eq $Base) {
    throw "Already on '$Base', nothing to merge."
}

Write-Host "Current branch: $branch"

git push -u origin HEAD
if ($LASTEXITCODE -ne 0) {
    throw "Failed to push '$branch'."
}

$existingNumber = ''
try {
    $existingNumber = (gh pr list --head $branch --json number --jq '.[0].number // empty' 2>$null).Trim()
} catch {
    $existingNumber = ''
}
if (-not [string]::IsNullOrWhiteSpace($existingNumber)) {
    Write-Host "PR #$existingNumber already exists for '$branch'."
} else {
    $createArgs = @('pr', 'create', '--base', $Base)
    if (-not [string]::IsNullOrWhiteSpace($Title)) {
        $createArgs += @('--title', $Title)
    } else {
        $createArgs += '--fill'
    }
    if (-not [string]::IsNullOrWhiteSpace($Body)) {
        $createArgs += @('--body', $Body)
    }
    if ($Draft) {
        $createArgs += '--draft'
    }
    & gh @createArgs
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to create pull request.'
    }
}

if ($Draft) {
    Write-Host 'Draft PR created. Mark it ready before merging.'
    exit 0
}

& gh pr merge $branch --squash --delete-branch
if ($LASTEXITCODE -ne 0) {
    throw 'Squash-merge failed. Check branch protection, required checks, or merge conflicts.'
}

git checkout $Base
if ($LASTEXITCODE -ne 0) {
    throw "Failed to switch to '$Base'."
}

git pull --ff-only
if ($LASTEXITCODE -ne 0) {
    throw "Failed to pull latest '$Base'."
}

if (-not $KeepLocalBranch) {
    git branch -d $branch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Remote merged, but local branch '$branch' could not be deleted. Remove it manually with 'git branch -D $branch'."
    }
}

Write-Host "Merged '$branch' into '$Base' and updated local '$Base'."
