# Run on your Windows PC from this folder (PowerShell):
#   winget install GitHub.cli ; gh auth login
#   .\scripts\open-pr.ps1 -Repo navidrome-nas            # private by default
#   .\scripts\open-pr.ps1 -Repo navidrome-nas -Public
param(
  [string]$Repo = "navidrome-nas",
  [switch]$Public
)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "GitHub CLI not found. Run: winget install GitHub.cli" }
gh auth status | Out-Null

# Safety: never push secrets
$tracked = git ls-files -- .env
if ($tracked) { throw ".env is tracked by git - remove it before pushing!" }

$visibility = if ($Public) { "--public" } else { "--private" }
$owner = gh api user --jq .login

if (-not ((git remote) -contains "origin")) {
  gh repo create "$owner/$Repo" $visibility --description "Navidrome + octo-fiesta Docker stack for UGREEN NAS" --source . --remote origin
}

git push -u origin main
git push -u origin feat/navidrome-octo-fiesta-ugreen

gh pr create `
  --repo "$owner/$Repo" `
  --base main `
  --head feat/navidrome-octo-fiesta-ugreen `
  --title "feat: Navidrome + octo-fiesta Docker stack for UGREEN NAS" `
  --body-file PULL_REQUEST.md

gh pr view --web --repo "$owner/$Repo" feat/navidrome-octo-fiesta-ugreen
