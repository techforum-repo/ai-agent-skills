# Establish repository root absolute reference paths
$RepoRoot = Resolve-Path "$PSScriptRoot\.."
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
        
        $TargetDir = Join-Path $RepoSkillsDir $Name
        
        Write-Host " 📥 Fetching external skill: $Name ($Repo#$Ref)..." -ForegroundColor Yellow
        
        # Force fresh clean downloads to catch manifest updates cleanly
        if (Test-Path $TargetDir) { Remove-Item $TargetDir -Recurse -Force }
        
        # Execute npx degit through PowerShell environment variables
        npx --yes degit "$Repo#$Ref" $TargetDir --force | Out-Null
    }
}

# Step 2: Systemic link routing mappings
If (!(Test-Path $ClaudeTarget)) { New-Item -ItemType Directory -Path $ClaudeTarget -Force }
If (!(Test-Path $CodexTarget)) { New-Item -ItemType Directory -Path $CodexTarget -Force }

Write-Host "Mapping active capabilities to Windows AI platforms..." -ForegroundColor Cyan

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