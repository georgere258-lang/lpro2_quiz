$ErrorActionPreference = "SilentlyContinue"

$targets = @(
  "admin_panel_screen.dart",
  "know_your_client_screen.dart",
  "home_screen_legacy.dart",
  "pro_insight_intro_service.dart"
)

$out = New-Object System.Collections.Generic.List[string]

Get-ChildItem .\lib -Recurse -File -Filter *.dart | ForEach-Object {
  $p = $_.FullName
  $c = Get-Content $p -Raw
  foreach ($t in $targets) {
    if ($c -and $c.Contains($t)) {
      $out.Add("FOUND REF -> $t IN $p")
    }
  }
}

$out | Set-Content -Encoding UTF8 .\ref_scan.txt
Write-Host "Done. Results saved to ref_scan.txt"