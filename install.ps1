# ─── Skills Reloaded Installer ────────────────────────────────────────────────
# Installs skills-reloaded skills for Claude Code, Codex, Gemini CLI, OpenCode, GitHub Copilot, Generic / Other
# Usage: irm https://raw.githubusercontent.com/techreloaded-ar/skills-reloaded/main/install.ps1 | iex
# ──────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$RepoBase = "https://raw.githubusercontent.com/techreloaded-ar/skills-reloaded/main"
$SkillNames = @("explore-context", "create-skills", "create-agents")

# ─── Tool definitions ────────────────────────────────────────────────────────
$Tools = @(
    @{ Name = "Claude Code"; Path = Join-Path "." ".claude\skills" }
    @{ Name = "Codex";       Path = Join-Path "." ".agents\skills" }
    @{ Name = "Gemini CLI";  Path = Join-Path "." ".gemini\skills" }
    @{ Name = "OpenCode";    Path = Join-Path "." ".opencode\skills" }
    @{ Name = "GitHub Copilot"; Path = Join-Path "." ".github\skills" }
    @{ Name = "Generic / Other"; Path = Join-Path "." ".skills-reloaded\skills" }
)

# ─── Legacy paths for cleanup ────────────────────────────────────────────────
$OldTools = @(
    @{ Path = Join-Path "." ".claude\commands";            Ext = "md" }
    @{ Path = Join-Path "." ".codex\prompts";              Ext = "md" }
    @{ Path = Join-Path "." ".gemini\commands";            Ext = "toml" }
    @{ Path = Join-Path "." ".config\opencode\commands";   Ext = "md" }
    @{ Path = ""; Ext = "" }
)
$OldNames = @("explore-context", "create-skills", "create-agents", "update-skills")

# ─── Install for a specific tool ─────────────────────────────────────────────
function Install-ForTool {
    param([int]$ToolIndex, [string]$TempDir)

    $tool = $Tools[$ToolIndex]
    $toolPath = $tool.Path

    foreach ($skillName in $SkillNames) {
        $destDir = Join-Path $toolPath $skillName
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $src = Join-Path (Join-Path $TempDir $skillName) "SKILL.md"
        $dest = Join-Path $destDir "SKILL.md"
        Copy-Item -Path $src -Destination $dest -Force
    }

    Write-Host ""
    Write-Host "  $([char]0x2713) " -ForegroundColor Green -NoNewline
    Write-Host "$($tool.Name)" -ForegroundColor White -NoNewline
    Write-Host " -> $toolPath" -ForegroundColor DarkGray
    foreach ($skillName in $SkillNames) {
        Write-Host "    $skillName/SKILL.md" -ForegroundColor DarkGray
    }
}

# ─── Remove legacy files ─────────────────────────────────────────────────────
function Remove-Legacy {
    param([int]$ToolIndex)

    $old = $OldTools[$ToolIndex]
    $oldPath = $old.Path
    
    # Skip se il path è vuoto (per nuove opzioni senza legacy)
    if ([string]::IsNullOrWhiteSpace($oldPath)) {
        return
    }
    
    $ext = $old.Ext
    $removed = 0

    foreach ($oldName in $OldNames) {
        $oldFile = Join-Path $oldPath "$oldName.$ext"
        if (Test-Path $oldFile) {
            Remove-Item -Path $oldFile -Force
            $removed++
        }
    }

    # Remove directory if empty
    if ((Test-Path $oldPath) -and (@(Get-ChildItem -Path $oldPath -Force).Count -eq 0)) {
        Remove-Item -Path $oldPath -Force
    }

    if ($removed -gt 0) {
        Write-Host "  Cleaned up $removed legacy file(s) from $oldPath" -ForegroundColor DarkGray
    }
}

# ─── Interactive multi-select menu ────────────────────────────────────────────
function Show-Menu {
    $selected = @(0, 0, 0, 0, 0) # none selected by default
    $cursor = 0
    $toolCount = $Tools.Count

    # Check if we have an interactive host
    $isInteractive = $true
    try {
        [Console]::CursorVisible = $false
    }
    catch {
        $isInteractive = $false
    }

    if (-not $isInteractive) {
        return Show-FallbackMenu
    }

    try {
        # Initial draw
        for ($i = 0; $i -lt $toolCount; $i++) {
            $checkbox = if ($selected[$i] -eq 1) { "[x]" } else { "[ ]" }
            $prefix = if ($i -eq $cursor) { ">" } else { " " }

            if ($i -eq $cursor) {
                Write-Host "  $prefix $checkbox $($Tools[$i].Name)" -ForegroundColor Cyan -NoNewline
            }
            else {
                Write-Host "  $prefix $checkbox $($Tools[$i].Name)" -NoNewline
            }
            Write-Host " ($($Tools[$i].Path))" -ForegroundColor DarkGray
        }
        Write-Host "  Up/Down: navigate  Space: toggle  Enter: confirm" -ForegroundColor DarkGray -NoNewline

        while ($true) {
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                "UpArrow" {
                    if ($cursor -gt 0) { $cursor-- }
                }
                "DownArrow" {
                    if ($cursor -lt ($toolCount - 1)) { $cursor++ }
                }
                "Spacebar" {
                    $selected[$cursor] = if ($selected[$cursor] -eq 1) { 0 } else { 1 }
                }
                "Enter" {
                    Write-Host ""
                    [Console]::CursorVisible = $true

                    $result = @()
                    for ($i = 0; $i -lt $toolCount; $i++) {
                        if ($selected[$i] -eq 1) { $result += $i }
                    }
                    return $result
                }
            }

            # Redraw — move cursor up
            [Console]::SetCursorPosition(0, [Console]::CursorTop - $toolCount)

            for ($i = 0; $i -lt $toolCount; $i++) {
                $checkbox = if ($selected[$i] -eq 1) { "[x]" } else { "[ ]" }
                $prefix = if ($i -eq $cursor) { ">" } else { " " }

                # Clear line
                Write-Host ("`r" + (" " * [Console]::WindowWidth)) -NoNewline
                Write-Host "`r" -NoNewline

                if ($i -eq $cursor) {
                    Write-Host "  $prefix $checkbox $($Tools[$i].Name)" -ForegroundColor Cyan -NoNewline
                }
                else {
                    Write-Host "  $prefix $checkbox $($Tools[$i].Name)" -NoNewline
                }
                Write-Host " ($($Tools[$i].Path))" -ForegroundColor DarkGray
            }
            Write-Host ("`r" + (" " * [Console]::WindowWidth)) -NoNewline
            Write-Host "`r  Up/Down: navigate  Space: toggle  Enter: confirm" -ForegroundColor DarkGray -NoNewline
        }
    }
    finally {
        try { [Console]::CursorVisible = $true } catch {}
    }
}

# ─── Fallback menu for non-interactive terminals ──────────────────────────────
function Show-FallbackMenu {
    Write-Host ""
    for ($i = 0; $i -lt $Tools.Count; $i++) {
        Write-Host "  $($i + 1)) $($Tools[$i].Name) ($($Tools[$i].Path))"
    }
    Write-Host ""
    $choices = Read-Host "Enter tool numbers separated by spaces (e.g. 1 2 3), or 'all' (default: none)"

    $result = @()
    if ($choices -eq "all") {
        for ($i = 0; $i -lt $Tools.Count; $i++) { $result += $i }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($choices)) {
        foreach ($c in $choices -split '\s+') {
            try {
                $idx = [int]$c - 1
                if ($idx -ge 0 -and $idx -lt $Tools.Count) {
                    $result += $idx
                }
            }
            catch {
                # Ignore invalid input
            }
        }
    }
    return $result
}

# ─── Main ─────────────────────────────────────────────────────────────────────
function Main {
    Write-Host ""
    Write-Host "  Skills Reloaded Installer" -ForegroundColor Cyan
    Write-Host "  Install AI coding skills for your tools" -ForegroundColor DarkGray
    Write-Host ""

    # Create temp directory
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "skills-reloaded-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # Download skills
        Write-Host "  Downloading skills..." -ForegroundColor DarkGray
        $downloadFailed = $false

        foreach ($skillName in $SkillNames) {
            $url = "$RepoBase/skills/$skillName/SKILL.md"
            $destDir = Join-Path $tempDir $skillName
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            $dest = Join-Path $destDir "SKILL.md"

            try {
                Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-Host "  X Failed to download $skillName" -ForegroundColor Red
                $downloadFailed = $true
            }
        }

        if ($downloadFailed) {
            Write-Host ""
            Write-Host "  Some downloads failed. Please check your connection and try again." -ForegroundColor Red
            return
        }

        Write-Host "  $([char]0x2713) Downloaded $($SkillNames.Count) skills" -ForegroundColor Green
        Write-Host ""

        # Tool selection
        Write-Host "  Select tools to install for:" -ForegroundColor White
        Write-Host ""
        $selectedTools = Show-Menu

        if ($null -eq $selectedTools -or $selectedTools.Count -eq 0) {
            Write-Host "  No tools selected. Exiting." -ForegroundColor Yellow
            return
        }

        # Install
        Write-Host "  Installing..." -ForegroundColor White

        foreach ($toolIndex in $selectedTools) {
            Install-ForTool -ToolIndex $toolIndex -TempDir $tempDir
            Remove-Legacy -ToolIndex $toolIndex
        }

        # Summary
        Write-Host ""
        Write-Host "  Done! " -ForegroundColor Green -NoNewline
        Write-Host "Installed $($SkillNames.Count) skills for $($selectedTools.Count) tool(s)."
        Write-Host ""
    }
    finally {
        # Cleanup
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Main
