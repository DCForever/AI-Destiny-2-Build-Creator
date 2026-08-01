function Save-DriverShot([string]$src, [string]$dest) {
  $raw = Get-Content -LiteralPath $src -Raw
  if ($raw -match 'data:image/png;base64,(.+)$') { $b64 = $Matches[1].Trim() }
  else { $b64 = $raw.Trim() }
  $b64 = ($b64 -replace '\s','')
  $bytes = [Convert]::FromBase64String($b64)
  [IO.File]::WriteAllBytes($dest, $bytes)
  Write-Host "saved $dest ($($bytes.Length) bytes)"
}
