# Usage: .\scripts\sync-skills.ps1 [-DryRun]
# Creating symbolic links on Windows requires an Administrator shell or Developer Mode.
param([switch]$DryRun)

$ErrorActionPreference = "Stop"
if ($DryRun) { Write-Host "Dry run: no files will be changed." -ForegroundColor Yellow }

# Establish repository root absolute reference paths
$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path
$RepoSkillsDir = Join-Path $RepoRoot "skills"
$ManifestFile = Join-Path $RepoRoot "config\external-skills.json"

$ClaudeTarget = "$env:USERPROFILE\.claude\skills"
$CodexTarget = "$env:USERPROFILE\.codex\skills"

# Step 1: Process and clone/update declarative external skills from the manifest JSON
if (Test-Path $ManifestFile) {
    Write-Host "Processing external skills manifest..." -ForegroundColor Cyan

    # Read and parse the raw JSON file natively via PowerShell
    $Manifest = Get-Content $ManifestFile -Raw | ConvertFrom-Json

    foreach ($skill in $Manifest.external_skills) {
        $Name = $skill.name
        $Repo = $skill.repo
        $Ref  = $skill.ref
        if (!$Name -or !$Repo -or !$Ref) { throw "Manifest entry needs name, repo and ref: $($skill | ConvertTo-Json -Compress)" }

        $TargetDir = Join-Path $RepoSkillsDir $Name

        Write-Host " Fetching external skill: ${Name} (${Repo}#${Ref})..." -ForegroundColor Yellow

        # Only replace folders created by this installer; preserve local work.
        $Marker = Join-Path $TargetDir ".ai-agent-skills-managed"
        if ((Test-Path $TargetDir) -and !(Test-Path $Marker)) {
            Write-Warning "Skipping ${Name}: $TargetDir exists and is not managed by this repository."
            continue
        }
        if ($DryRun) { Write-Host "   would replace $TargetDir"; continue }
        if (Test-Path $TargetDir) { Remove-Item $TargetDir -Recurse -Force }

        # Execute npx degit through PowerShell environment variables
        npx --yes degit "${Repo}#${Ref}" $TargetDir --force | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "degit failed for ${Name}" }
        New-Item -ItemType File -Path $Marker -Force | Out-Null
    }
}

# Step 2: Systemic link routing mappings
foreach ($Target in @($ClaudeTarget, $CodexTarget)) {
    if (!(Test-Path $Target) -and !$DryRun) { New-Item -ItemType Directory -Path $Target -Force | Out-Null }
}

# Remove links this installer created for skills that no longer exist in the repository.
Write-Host "Pruning stale links..." -ForegroundColor Cyan
foreach ($Target in @($ClaudeTarget, $CodexTarget)) {
    if (!(Test-Path $Target)) { continue }
    Get-ChildItem $Target -Force | Where-Object { $_.LinkType -eq "SymbolicLink" } | ForEach-Object {
        $LinkTarget = [string]($_.Target)
        if ($LinkTarget.StartsWith($RepoSkillsDir, [System.StringComparison]::OrdinalIgnoreCase) -and !(Test-Path $LinkTarget)) {
            if (!$DryRun) { Remove-Item $_.FullName -Force }
            Write-Host " - Removed stale link: $($_.FullName)"
        }
    }
}

Write-Host "Mapping active capabilities to Windows AI platforms..." -ForegroundColor Cyan

Get-ChildItem $RepoSkillsDir -Directory | ForEach-Object {
    $SkillName = $_.Name
    $SourcePath = $_.FullName

    $ClaudeLink = Join-Path $ClaudeTarget $SkillName
    $CodexLink = Join-Path $CodexTarget $SkillName

    # Never replace a directory or a link owned by another tool/user.
    foreach ($Link in @($ClaudeLink, $CodexLink)) {
        if ((Test-Path $Link) -and !((Get-Item $Link -Force).LinkType)) {
            Write-Warning "Skipping ${SkillName}: $Link is not a managed symbolic link."
            return
        }
    }
    if ($DryRun) { Write-Host "   would link $SkillName"; return }
    foreach ($Link in @($ClaudeLink, $CodexLink)) {
        if (Test-Path $Link) { Remove-Item $Link -Force }
        # Create the native Windows Symbolic Links for both execution environments
        New-Item -ItemType SymbolicLink -Path $Link -Value $SourcePath | Out-Null
    }

    Write-Host " Registered Windows Link: $SkillName" -ForegroundColor Green
}
Write-Host "Windows AI Platform Sync Complete!" -ForegroundColor Cyan
