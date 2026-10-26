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
        
        # Only replace folders created by this installer; preserve local work.
        $Marker = Join-Path $TargetDir ".ai-agent-skills-managed"
        if ((Test-Path $TargetDir) -and !(Test-Path $Marker)) {
            Write-Warning "Skipping $Name: $TargetDir exists and is not managed by this repository."
            continue
        }
        if (Test-Path $TargetDir) { Remove-Item $TargetDir -Recurse -Force }
        
        # Execute npx degit through PowerShell environment variables
        npx --yes degit "$Repo#$Ref" $TargetDir --force | Out-Null
        New-Item -ItemType File -Path $Marker -Force | Out-Null
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
    
    # Never replace a directory or a link owned by another tool/user.
    if ((Test-Path $ClaudeLink) -and !((Get-Item $ClaudeLink -Force).LinkType)) {
        Write-Warning "Skipping $SkillName: $ClaudeLink is not a managed symbolic link."
        return
    }
    if ((Test-Path $CodexLink) -and !((Get-Item $CodexLink -Force).LinkType)) {
        Write-Warning "Skipping $SkillName: $CodexLink is not a managed symbolic link."
        return
    }
    if (Test-Path $ClaudeLink) { Remove-Item $ClaudeLink -Force }
    if (Test-Path $CodexLink) { Remove-Item $CodexLink -Force }
    
    # Create the native Windows Symbolic Links for both execution environments
    New-Item -ItemType SymbolicLink -Path $ClaudeLink -Value $SourcePath | Out-Null
    New-Item -ItemType SymbolicLink -Path $CodexLink -Value $SourcePath | Out-Null
    
    Write-Host " ✓ Registered Windows Link: $SkillName" -ForegroundColor Green
}
Write-Host "Windows AI Platform Sync Complete!" -ForegroundColor Cyan
