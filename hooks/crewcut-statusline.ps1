# CLAUDE_CONFIG_DIR overrides ~/.claude, matching where the hooks write the flag (issue #34)
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$Flag = Join-Path $ClaudeDir ".crewcut-active"
$Item = Get-Item -LiteralPath $Flag -Force -ErrorAction SilentlyContinue
# A symlinked flag could point the statusline at any file; ignore it.
if (-not $Item -or $Item.PSIsContainer -or $Item.LinkType) {
    exit 0
}

$Mode = ""
try {
    $Line = [string](Get-Content -LiteralPath $Flag -TotalCount 1 -ErrorAction Stop)
} catch {
    exit 0
}
# Keep only a-z0-9- from the first 64 chars: the flag is printed to the
# terminal, so stray bytes there must never become escape sequences.
$Line = $Line.Substring(0, [Math]::Min(64, $Line.Length)).ToLowerInvariant()
$Mode = $Line -replace '[^a-z0-9-]', ''

$Esc = [char]27
# ultra is the high-intensity mode; flag it amber so it stands out from the
# default green. The level is still in the text, so color is a redundant cue.
$Color = if ($Mode -eq "ultra") { "173" } else { "108" }
if ([string]::IsNullOrEmpty($Mode) -or $Mode -eq "full") {
    [Console]::Write("${Esc}[38;5;${Color}m[CREWCUT]${Esc}[0m")
} else {
    $Suffix = $Mode.ToUpperInvariant()
    [Console]::Write("${Esc}[38;5;${Color}m[CREWCUT:$Suffix]${Esc}[0m")
}
