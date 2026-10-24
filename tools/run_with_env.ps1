# Reads .env (KEY=VALUE) and runs flutter with matching --dart-define flags.
# Usage: .\tools\run_with_env.ps1 [-Device <id>] [-- <extra flutter args>]
param(
  [string]$Device = "",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
  Write-Error "Missing .env — copy .env.example to .env and fill SUPABASE_URL / SUPABASE_ANON_KEY."
}

$defines = @()
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if ($line -eq "" -or $line.StartsWith("#")) { return }
  $parts = $line.Split("=", 2)
  if ($parts.Length -ne 2) { return }
  $key = $parts[0].Trim()
  $val = $parts[1].Trim().Trim("'").Trim('"')
  if ($key -ne "") {
    $defines += "--dart-define=$key=$val"
  }
}

$flutterArgs = @("run") + $defines
if ($Device -ne "") {
  $flutterArgs += @("-d", $Device)
}
if ($FlutterArgs) {
  $flutterArgs += $FlutterArgs
}

Write-Host "flutter $($flutterArgs -join ' ')"
& flutter @flutterArgs
