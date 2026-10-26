# Get absolute path of the local cloned skills folder
$RepoSkillsDir = Resolve-Path "$PSScriptRoot\..\skills"

$ClaudeTarget = "$env:USERPROFILE\.claude\skills"
$CodexTarget = "$env:USERPROFILE\.codex\skills"

# Force establish target paths if they don't exist
If (!(Test-Path $ClaudeTarget)) { New-Item -ItemType Directory -Path $ClaudeTarget -Force }
If (!(Test-Path $CodexTarget)) { New-Item -ItemType Directory -Path $CodexTarget -Force }

Write-Host "Creating Windows Fs Symbolic Links..." -ForegroundColor Cyan

Get-ChildItem $RepoSkillsDir | Where-Object { $_.PSIsContainer } | ForEach-Object {
    $SkillName = $_.Name
    $SourcePath = $_.FullName
    
    $ClaudeLink = Join-Path $ClaudeTarget $SkillName
    $CodexLink = Join-Path $CodexTarget $SkillName
    
    # Remove existing symlinks or legacy files if refreshing profiles
    if (Test-Path $ClaudeLink) { Remove-Item $ClaudeLink -Recurse -Force }
    if (Test-Path $CodexLink) { Remove-Item $CodexLink -Recurse -Force }
    
    # Create the native Windows Symlink junctions
    New-Item -ItemType SymbolicLink -Path $ClaudeLink -Value $SourcePath | Out-Null
    New-Item -ItemType SymbolicLink -Path $CodexLink -Value $SourcePath | Out-Null
    
    Write-Host " ✓ Linked Windows Engine Target: $SkillName" -ForegroundColor Green
}
Write-Host "Windows Link Sync Complete!" -ForegroundColor Cyan