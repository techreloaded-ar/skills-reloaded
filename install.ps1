# ─── Skills Reloaded Installer ────────────────────────────────────────────────
# Installs skills-reloaded commands for Claude Code, Codex, Gemini CLI, OpenCode
# Usage: irm https://raw.githubusercontent.com/Smarello/skills-reloaded/main/install.ps1 | iex
# ──────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$RepoBase = "https://raw.githubusercontent.com/Smarello/skills-reloaded/main/skills-reloaded"
$Files = @("explore-context.md", "create-skills.md", "create-agents.md", "update-skills.md")

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

# ─── Tool definitions ────────────────────────────────────────────────────────
$Tools = @(
    @{ Name = "Claude Code"; Path = Join-Path $env:USERPROFILE ".claude\commands" }
    @{ Name = "Codex";       Path = Join-Path $env:USERPROFILE ".codex\prompts" }
    @{ Name = "Gemini CLI";  Path = Join-Path $env:USERPROFILE ".gemini\commands" }
    @{ Name = "OpenCode";    Path = Join-Path $env:USERPROFILE ".config\opencode\commands" }
)

# ─── Frontmatter parser ──────────────────────────────────────────────────────
function Parse-Frontmatter {
    param([string]$FilePath)

    $content = [System.IO.File]::ReadAllText($FilePath, $Utf8NoBom)
    $result = @{ Name = ""; Description = ""; Body = "" }

    # Match YAML frontmatter: starts with --- on first line, ends with --- on its own line
    if ($content -match "(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$") {
        $header = $Matches[1]
        $result.Body = $Matches[2]

        foreach ($line in $header -split "\r?\n") {
            $line = $line.Trim()
            if ($line -match "^name:\s*(.+)$") {
                $result.Name = $Matches[1].Trim()
            }
            elseif ($line -match "^description:\s*(.+)$") {
                $result.Description = $Matches[1].Trim()
            }
        }
    }
    else {
        # No frontmatter — derive name from filename, description from first heading
        $result.Name = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)

        foreach ($line in $content -split "\r?\n") {
            if ($line -match "^#\s+(.+)$") {
                $result.Description = $Matches[1].Trim()
                break
            }
        }

        $result.Body = $content
    }

    return $result
}

# ─── TOML converter ──────────────────────────────────────────────────────────
function Convert-ToToml {
    param([string]$Description, [string]$Body)

    $escapedDesc = $Description.Replace('\', '\\').Replace('"', '\"')
    $escapedBody = $Body.Replace('\', '\\').Replace('"""', '""\\"')

    return "description = `"$escapedDesc`"`n`nprompt = `"`"`"`n$escapedBody`n`"`"`"`n"
}

# ─── Install for a specific tool ─────────────────────────────────────────────
function Install-ForTool {
    param([int]$ToolIndex, [string]$TempDir)

    $tool = $Tools[$ToolIndex]
    $toolPath = $tool.Path

    if (-not (Test-Path $toolPath)) {
        New-Item -ItemType Directory -Path $toolPath -Force | Out-Null
    }

    $installed = @()

    foreach ($file in $Files) {
        $src = Join-Path $TempDir $file
        $cmdName = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $parsed = Parse-Frontmatter -FilePath $src

        switch ($ToolIndex) {
            0 {
                # Claude Code — copy verbatim
                $dest = Join-Path $toolPath $file
                Copy-Item -Path $src -Destination $dest -Force
                $installed += $file
            }
            { $_ -eq 1 -or $_ -eq 3 } {
                # Codex / OpenCode — strip frontmatter
                $dest = Join-Path $toolPath $file
                [System.IO.File]::WriteAllText($dest, $parsed.Body, $Utf8NoBom)
                $installed += $file
            }
            2 {
                # Gemini CLI — convert to TOML
                $tomlFile = "$cmdName.toml"
                $dest = Join-Path $toolPath $tomlFile
                $tomlContent = Convert-ToToml -Description $parsed.Description -Body $parsed.Body
                [System.IO.File]::WriteAllText($dest, $tomlContent, $Utf8NoBom)
                $installed += $tomlFile
            }
        }
    }

    Write-Host ""
    Write-Host "  $([char]0x2713) " -ForegroundColor Green -NoNewline
    Write-Host "$($tool.Name)" -ForegroundColor White -NoNewline
    Write-Host " -> $toolPath" -ForegroundColor DarkGray
    foreach ($f in $installed) {
        Write-Host "    $f" -ForegroundColor DarkGray
    }
}

# ─── Interactive multi-select menu ────────────────────────────────────────────
function Show-Menu {
    $selected = @(1, 1, 1, 1) # all selected by default
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
        Write-Host "  Up/Down: navigate  Space: toggle  Enter: confirm" -ForegroundColor DarkGray

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
            [Console]::SetCursorPosition(0, [Console]::CursorTop - $toolCount - 1)

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
    $choices = Read-Host "Enter tool numbers separated by spaces (e.g. 1 2 3), or 'all'"

    $result = @()
    if ($choices -eq "all") {
        for ($i = 0; $i -lt $Tools.Count; $i++) { $result += $i }
    }
    else {
        foreach ($c in $choices -split '\s+') {
            $idx = [int]$c - 1
            if ($idx -ge 0 -and $idx -lt $Tools.Count) {
                $result += $idx
            }
        }
    }
    return $result
}

# ─── Main ─────────────────────────────────────────────────────────────────────
function Main {
    Write-Host ""
    Write-Host "  Skills Reloaded Installer" -ForegroundColor Cyan
    Write-Host "  Install AI coding commands for your tools" -ForegroundColor DarkGray
    Write-Host ""

    # Create temp directory
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "skills-reloaded-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # Download files
        Write-Host "  Downloading commands..." -ForegroundColor DarkGray
        $downloadFailed = $false

        foreach ($file in $Files) {
            $url = "$RepoBase/$file"
            $dest = Join-Path $tempDir $file

            try {
                Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-Host "  X Failed to download $file" -ForegroundColor Red
                $downloadFailed = $true
            }
        }

        if ($downloadFailed) {
            Write-Host ""
            Write-Host "  Some downloads failed. Please check your connection and try again." -ForegroundColor Red
            return
        }

        Write-Host "  $([char]0x2713) Downloaded $($Files.Count) commands" -ForegroundColor Green
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
        }

        # Summary
        Write-Host ""
        Write-Host "  Done! " -ForegroundColor Green -NoNewline
        Write-Host "Installed $($Files.Count) commands for $($selectedTools.Count) tool(s)."
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
