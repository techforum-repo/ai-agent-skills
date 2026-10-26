# Get absolute path of the local repository skills directory folder
$RepoSkillsDir = Resolve-Path "$PSScriptRoot\..\skills"

$ClaudeTarget = "$env:USERPROFILE\.claude\skills"
$CodexTarget = "$env:USERPROFILE\.codex\skills"

# Force establish target system environment paths if they don't exist
If (!(Test-Path $ClaudeTarget)) { New-Item -ItemType Directory -Path $ClaudeTarget -Force }
If (!(Test-Path $CodexTarget)) { New-Item -ItemType Directory -Path $CodexTarget -Force }

Write-Host "Syncing All Custom & External Skills to AI Platforms..." -ForegroundColor Cyan

# Dynamically loops through every folder inside your repository skills folder
Get-ChildItem $RepoSkillsDir | Where-Object { $_.PSIsContainer } | ForEach-Object {
    $SkillName = $_.Name
    $SourcePath = $_.FullName
    
    $ClaudeLink = Join-Path $ClaudeTarget $SkillName
    $CodexLink = Join-Path $CodexTarget $SkillName
    
    # Remove existing symlinks or legacy cached folders to prevent file collisions
    if (Test-Path $ClaudeLink) { Remove-Item $ClaudeLink -Recurse -Force }
    if (Test-Path $CodexLink) { Remove-Item $CodexLink -Recurse -Force }
    
    # Create the native Windows Symbolic Links for both execution environments
    New-Item -ItemType SymbolicLink -Path $ClaudeLink -Value $SourcePath | Out-Null
    New-Item -ItemType SymbolicLink -Path $CodexLink -Value $SourcePath | Out-Null
    
    Write-Host " ✓ Registered Windows Link: $SkillName" -ForegroundColor Green
}
Write-Host "Windows AI Platform Sync Complete!" -ForegroundColor Cyan